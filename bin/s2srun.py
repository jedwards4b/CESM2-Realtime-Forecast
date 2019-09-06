#!/usr/bin/env python
import os, sys
#cesmroot = os.environ.get('CESM_ROOT')
cesmroot = os.path.join(os.sep+"glade","u","home","jedwards","sandboxes","CESM2-Realtime-Forecast","cesm2_1")
s2sfcstroot = os.path.join(os.path.dirname(os.path.join(os.path.abspath(__file__))), os.path.pardir)

if cesmroot is None:
    print ("ERROR CESM_ROOT must be defined in environment")
    exit

_LIBDIR="/glade/u/home/jedwards/.local/lib/python3.6/site-packages/"
sys.path.append(_LIBDIR)
_LIBDIR = os.path.join(cesmroot,"cime","scripts","Tools")
sys.path.append(_LIBDIR)
_LIBDIR = os.path.join(cesmroot,"cime","scripts","lib")
sys.path.append(_LIBDIR)

import datetime, glob
import CIME.build as build
from standard_script_setup import *
from CIME.case             import Case
from CIME.utils            import run_cmd, expect, safe_copy
from argparse              import RawTextHelpFormatter
from calendar              import monthrange
from CIME.locked_files          import lock_file, unlock_file
from globus_utils          import *

def parse_command_line(args, description):
    parser = argparse.ArgumentParser(description=description,
                                     formatter_class=RawTextHelpFormatter)
    CIME.utils.setup_standard_logging_options(parser)
    parser.add_argument("--date",
                        help="Specify a start Date")



    args = CIME.utils.parse_args_and_handle_standard_logging_options(args, parser)
    fullmonth = False
    cdate = os.getenv("CYLC_TASK_CYCLE_POINT")

    if args.date:
        try:
            date = datetime.datetime.strptime(args.date, '%Y-%m-%d')
        except ValueError:
            try:
                date = datetime.datetime.strptime(args.date, '%Y-%m')
                fullmonth = True
            except ValueError:
                raise ValueError("Incorrect data format, should be YYYY-MM-DD or YYYY-MM")
    elif cdate:
        date = datetime.datetime.strptime(cdate, '%Y-%m-%d')
    else:
        date = datetime.date.today()
        date = date.replace(day=date.day-1)

    return date.strftime("%Y-%m-%d"), fullmonth

def per_run_case_updates(case, date, sdrestdir, user_mods_dir, rundir):
    caseroot = case.get_value("CASEROOT")
    basecasename = os.path.basename(caseroot)[:-3]
    member = os.path.basename(caseroot)[-3:]

    unlock_file("env_case.xml",caseroot=caseroot)
    case.set_value("CASE",basecasename+"."+date+member)
    case.flush()
    lock_file("env_case.xml",caseroot=caseroot)

    case.set_value("CONTINUE_RUN",False)
    case.set_value("RUN_REFDATE",date)
    case.set_value("RUN_STARTDATE",date)
    case.set_value("RUN_REFDIR",sdrestdir)
    case.set_value("PROJECT","NCGD0042")
    # restage user_mods for each run
    for usermod in glob.iglob(user_mods_dir+"/user*"):
        safe_copy(usermod, caseroot)

    case.case_setup()

    stage_refcase(rundir, sdrestdir)
    unlock_file("env_batch.xml",caseroot=caseroot)
    case.flush()
    lock_file("env_batch.xml",caseroot=caseroot)


def build_base_case(date, baseroot, basecasename, res, compset, overwrite,
                    sdrestdir, pertdir, user_mods_dir, pecount=None):

    caseroot = os.path.join(baseroot,basecasename+".00")

    with Case(caseroot, read_only=False) as case:
        if overwrite or not os.path.isdir(caseroot):
            case.create(os.path.basename(caseroot), cesmroot, compset, res,
                        run_unsupported=True, answer="r",walltime="04:00:00",
                        user_mods_dir=user_mods_dir, pecount=pecount)
            # make sure that changing the casename will not affect these variables
            case.set_value("EXEROOT",case.get_value("EXEROOT", resolved=True))
            case.set_value("RUNDIR",case.get_value("RUNDIR",resolved=True)+".00")

            case.set_value("RUN_TYPE","hybrid")
            case.set_value("GET_REFCASE",False)
            case.set_value("RUN_REFDIR",sdrestdir)
            case.set_value("RUN_REFCASE", "b.e21.{}.SD.{}.002".format(compset,res))
            case.set_value("STOP_OPTION","ndays")
            case.set_value("STOP_N", 45)
            case.set_value("REST_OPTION","ndays")
            case.set_value("REST_N", 45)
            case.set_value("OCN_TRACER_MODULES","")
            case.set_value("CCSM_BGC","CO2A")
            case.set_value("EXTERNAL_WORKFLOW",True)
            case.set_value("CLM_NAMELIST_OPTS", "use_init_interp=.true.")
#            case.set_value("ATM_NCPL",96)
#            case.set_value("ICE_NCPL",96)
#            case.set_value("LND_NCPL",96)
#            case.set_value("WAV_NCPL",96)


        rundir = case.get_value("RUNDIR")
        per_run_case_updates(case, date, sdrestdir, user_mods_dir, rundir)
        success = build.case_build(caseroot, case=case)
        pertfile = os.path.join(pertdir,"70Lwaccm6.cam.i."+date+"-00000-000.nc")
        caminit = os.path.join(rundir,"b.e21.BWHIST.SD.f09_g17.002.cam.i."+date+"-00000.nc")
        print("Linking {} to {}".format(pertfile, caminit))
        if os.path.isfile(caminit):
            os.unlink(caminit)
        os.symlink(pertfile, caminit)

        return caseroot

def stage_refcase(rundir, refdir):
    if not os.path.isdir(rundir):
        os.makedirs(rundir)
    for reffile in glob.iglob(refdir+"/*"):
        if os.path.basename(reffile).startswith("rpointer"):
            safe_copy(reffile, rundir)
        else:
            newfile = os.path.join(rundir,os.path.basename(reffile))
            if os.path.exists(newfile):
                os.unlink(newfile)
            os.symlink(reffile, newfile)

def clone_base_case(date, caseroot, ensemble, sdrestdir, pertdir, user_mods_dir, overwrite):

    startval = "01"
    nint = len(startval)
    cloneroot = caseroot
    for i in range(int(startval), int(startval)+ensemble):
        member_string = '{{0:0{0:d}d}}'.format(nint).format(i)
        if ensemble > 1:
            caseroot = caseroot[:-nint] + member_string
        if overwrite and os.path.isdir(caseroot):
            os.unlink(caseroot)
        if not os.path.isdir(caseroot):
            with Case(cloneroot, read_only=False) as clone:
                clone.create_clone(caseroot, keepexe=True,
                                   user_mods_dir=user_mods_dir)
        with Case(caseroot, read_only=True) as case:
            # rundir is initially 00 reset to current member
            rundir = case.get_value("RUNDIR")
            rundir = rundir[:-3]+member_string
            case.set_value("RUNDIR",rundir)
            per_run_case_updates(case, date, sdrestdir, user_mods_dir, rundir)

        pertfile = os.path.join(pertdir,"70Lwaccm6.cam.i."+date+"-00000-{:03}.nc".format(i))
        caminit = os.path.join(rundir,"b.e21.BWHIST.SD.f09_g17.002.cam.i."+date+"-00000.nc")
        if os.path.isfile(caminit):
            os.unlink(caminit)
        print("Linking {} to {}".format(pertfile, caminit))
        os.symlink(pertfile, caminit)

def get_data_from_campaignstore(date):
    source_path = '/gpfs/csfs1/cesm/development/cross-wg/S2S/SD/rest/{}-00000/'.format(date)
    dest_path = '/glade/scratch/jedwards/S2S_70LIC_globus/SD/rest/{}/'.format(date)
    lnd_source_path = '/gpfs/csfs1/cesm/development/cross-wg/S2S/land/rest/{}-00000/'.format(date)
    client = initialize_client()
    globus_auth_data = get_globus_auth_data_struct(client)
    globus_transfer_data = get_globus_transfer_data_struct(client)
    tc = get_transfer_client(client, globus_transfer_data)
    src_endpoint = get_endpoint_id(tc,"NCAR Campaign Storage")
    dest_endpoint = get_endpoint_id(tc,"NCAR GLADE")
    transfer_data = get_globus_transfer_object(tc, src_endpoint, dest_endpoint, 'S2S initial data transfer')
    transfer_data = add_to_transfer_request(transfer_data, source_path, dest_path)
    transfer_data = add_to_transfer_request(transfer_data, lnd_source_path, dest_path)
    activate_endpoint(tc, src_endpoint)
    activate_endpoint(tc, dest_endpoint)
    if complete_transfer_request(tc, transfer_data):
        for lndfile in glob.iglob(dest_path+"I2000*"):
            newfile = lndfile.replace("I2000Clm50BgcCrop.002run","b.e21.BWHIST.SD.f09_g17.002")
            print("Renaming {} to {}".format(lndfile,newfile))
            os.rename(os.path.join(dest_path,lndfile), os.path.join(dest_path,newfile))

def _main_func(description):
    date, fullmonth = parse_command_line(sys.argv, description)

    # TODO make these input vars
    baseroot = "/glade/work/jedwards/cases_S2S"
    basecasename = "70Lwaccm6"
    res = "f09_g17"
    compset = "BWHIST"
    overwrite = False
    sdrestdir = "/glade/scratch/jedwards/S2S_70LIC_globus/SD/rest/{}".format(date)
    pertdir = "/glade/scratch/sglanvil/S2S_70LIC/FINAL/{}-0.15_RFIC/".format(date)
    ensemble = 10
    user_mods_dir = os.path.join(s2sfcstroot,"user_mods",basecasename)
    # END TODO
    get_data_from_campaignstore(date)
    caseroot = build_base_case(date, baseroot, basecasename, res,
                               compset, overwrite, sdrestdir, pertdir, user_mods_dir+'.base', pecount="S")
    clone_base_case(date, caseroot, ensemble, sdrestdir, pertdir, user_mods_dir, overwrite)

if __name__ == "__main__":
    _main_func(__doc__)
