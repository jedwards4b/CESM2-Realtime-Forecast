#!/usr/bin/env python
import os, sys
cesmroot = os.environ.get('CESMROOT')
s2sfcstroot = os.path.join(os.path.dirname(os.path.join(os.path.abspath(__file__))), os.path.pardir)

if cesmroot is None:
    print "ERROR CESMROOT must be defined in environment"
    exit

_LIBDIR = os.path.join(cesmroot,"cime","scripts","Tools")
sys.path.append(_LIBDIR)
_LIBDIR = os.path.join(cesmroot,"cime","scripts","lib")
sys.path.append(_LIBDIR)

import datetime, tarfile
import CIME.build as build
from standard_script_setup import *
from CIME.case             import Case
from CIME.utils            import run_cmd, expect, safe_copy
from argparse              import RawTextHelpFormatter
from calendar              import monthrange

def parse_command_line(args, description):
    parser = argparse.ArgumentParser(description=description,
                                     formatter_class=RawTextHelpFormatter)
    CIME.utils.setup_standard_logging_options(parser)
    parser.add_argument("--date",
                        help="Specify a start Date")



    args = CIME.utils.parse_args_and_handle_standard_logging_options(args, parser)
    fullmonth = False
    if args.date:
        try:
            date = datetime.datetime.strptime(args.date, '%Y-%m-%d')
        except ValueError:
            try:
                date = datetime.datetime.strptime(args.date, '%Y-%m')
                fullmonth = True
            except ValueError:
                raise ValueError("Incorrect data format, should be YYYY-MM-DD or YYYY-MM")
    else:
        date = datetime.date.today()
        date = date.replace(day=date.day-1)

    return date.strftime("%Y-%m-%d"), fullmonth


def build_base_case(date, baseroot, basecasename, res, compset, overwrite,
                    sdrestdir, pertdir, user_mods_dir):

    caseroot = os.path.join(baseroot,basecasename+".00")

    with Case(caseroot, read_only=False) as case:
        if overwrite or not os.path.isdir(caseroot):
            case.create(os.path.basename(caseroot), cesmroot, compset, res,
                        run_unsupported=True, answer="r",
                        user_mods_dir=user_mods_dir)

        case.set_value("RUN_TYPE","hybrid")
        case.set_value("RUN_REFDIR",sdrestdir)
        case.set_value("RUN_REFCASE", "b.e21.{}.SD.{}.002".format(compset,res))
        case.set_value("RUN_REFDATE",str(date))
        case.set_value("RUN_STARTDATE",str(date))
        case.set_value("STOP_OPTION","ndays")
        case.set_value("STOP_N", 45)
        case.set_value("REST_OPTION","ndays")
        case.set_value("REST_N", 45)
        case.set_value("OCN_TRACER_MODULES","")
        case.set_value("CCSM_BGC","CO2A")
        case.set_value("EXTERNAL_WORKFLOW",True)
        case.set_value("NTHRDS", 1)
        case.set_value("CLM_NAMELIST_OPTS", "use_init_interp=.true.")
        case.case_setup()
        case.set_value("JOB_WALLCLOCK_TIME","02:00:00", subgroup="case.run")

        rundir = case.get_value("RUNDIR")
        success = build.case_build(caseroot, case=case)
        pertfile = os.path.join(pertdir,"70Lwaccm6.cam.i."+date+"-00000-000.nc")
        caminit = os.path.join(rundir,"b.e21.BWHIST.SD.f09_g17.002.cam.i."+date+"-00000.nc")
        print("Copying {} to {}".format(pertfile, caminit))
        os.unlink(caminit)
        safe_copy(pertfile, caminit)

        return caseroot

def clone_base_case(date, caseroot, ensemble, pertdir, user_mods_dir):

    startval = "01"
    nint = len(startval)
    cloneroot = caseroot
    for i in range(int(startval), int(startval)+ensemble):
        if ensemble > 1:
            caseroot = caseroot[:-nint] + '{{0:0{0:d}d}}'.format(nint).format(i)
        with Case(cloneroot, read_only=False) as clone:
            clone.create_clone(caseroot, keepexe=True,
                               user_mods_dir=user_mods_dir)
        with Case(caseroot, read_only=True) as case:
            rundir = case.get_value("RUNDIR")
        pertfile = os.path.join(pertdir,"70Lwaccm6.cam.i."+date+"-00000-{:03}.nc".format(i))
        caminit = os.path.join(rundir,"b.e21.BWHIST.SD.f09_g17.002.cam.i."+date+"-00000.nc")
        print("Copying {} to {}".format(pertfile, caminit))
        safe_copy(pertfile, caminit)




def _main_func(description):
    date, fullmonth = parse_command_line(sys.argv, description)

    # TODO make these input vars
    baseroot = "/glade/work/jedwards/cases_S2S"
    basecasename = "70Lwaccm6"
    res = "f09_g17"
    compset = "BWHIST"
    overwrite = False
    sdrestdir = "/glade/scratch/sglanvil/S2S_70LIC_globus/SD/rest/{}".format(date)
    pertdir = "/glade/scratch/sglanvil/S2S_70LIC/FINAL/{}-0.15_RFIC/".format(date)
    ensemble = 10
    user_mods_dir = os.path.join(s2sfcstroot,"user_mods",basecasename)
    # END TODO

    caseroot = build_base_case(date, baseroot, basecasename, res,
                               compset, overwrite, sdrestdir, pertdir, user_mods_dir+'.base')

    clone_base_case(date, caseroot, ensemble, pertdir, user_mods_dir)





if __name__ == "__main__":
    _main_func(__doc__)
