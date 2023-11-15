#!/usr/bin/env python3
import os, sys
cesmroot = os.environ.get('CESM_ROOT')
s2sfcstroot = os.path.join(os.path.dirname(os.path.join(os.path.abspath(__file__))), os.path.pardir)

if cesmroot is None:
    raise SystemExit("ERROR: CESM_ROOT must be defined in environment")

_LIBDIR = os.path.join(cesmroot,"cime","scripts","Tools")
sys.path.append(_LIBDIR)
_LIBDIR = os.path.join(cesmroot,"cime","scripts","lib")
sys.path.append(_LIBDIR)

print(f"sys path is {sys.path}")
import glob, shutil
from datetime import timedelta, datetime
import CIME.build as build
from standard_script_setup import *
from CIME.case             import Case
from CIME.utils            import safe_copy
from argparse              import RawTextHelpFormatter
from CIME.locked_files          import lock_file, unlock_file

def parse_command_line(args, description):
    parser = argparse.ArgumentParser(description=description,
                                     formatter_class=RawTextHelpFormatter)
    CIME.utils.setup_standard_logging_options(parser)
    parser.add_argument("--date",
                        help="Specify a start Date")
    parser.add_argument("--ensemble-start",default=0,
                        help="Specify the first ensemble member")
    parser.add_argument("--ensemble-end",default=10,
                        help="Specify the last ensemble member")

    args = CIME.utils.parse_args_and_handle_standard_logging_options(args, parser)
    cdate = os.getenv("CYLC_TASK_CYCLE_POINT")

    if args.date:
        try:
            date = datetime.strptime(args.date, '%Y-%m-%d')
        except ValueError as verr:
            raise ValueError("Incorrect data format, should be YYYY-MM-DD or YYYY-MM") from verr
    elif cdate:
        date = datetime.strptime(cdate, '%Y-%m-%d')
    else:
        date = datetime.today() - timedelta(days=1)

    return date.strftime("%Y-%m-%d"),int(args.ensemble_start),int(args.ensemble_end)

def stage_refcase(rundir, refdir, date):
    if not os.path.isdir(rundir):
        os.makedirs(rundir)
    nfname = "b.e21.f09_g17"

    for reffile in glob.iglob(refdir+"/*"):
        if os.path.basename(reffile).startswith("rpointer"):
            safe_copy(reffile, rundir)
        else:
            newfile = os.path.basename(reffile)
            if 'cice.r' in newfile:
                newfile = "{}.cice.r.{}-00000.nc".format(nfname,date)
            elif 'I2000' in newfile:
                newfile = newfile.replace("I2000Clm50BgcCrop.002runRealtime",nfname)
                newfile = newfile.replace("I2000Clm50BgcCrop.002runContd", nfname)
                newfile = newfile.replace("I2000Clm50BgcCrop.002run",nfname)
            newfile = os.path.join(rundir,newfile)
            if not "cam.i" in newfile:
                if os.path.lexists(newfile):
                    os.unlink(newfile)
                os.symlink(reffile, newfile)

def per_run_case_updates(case, date, sdrestdir, user_mods_dir, rundir):
    caseroot = case.get_value("CASEROOT")
    basecasename = os.path.basename(caseroot)[:-14]
    member = os.path.basename(caseroot)[-2:]
    mem = int(member)+1

    unlock_file("env_case.xml",caseroot=caseroot)
    casename = basecasename+"_"+date+"."+member
    case.set_value("CASE",casename)
    case.flush()
    lock_file("env_case.xml",caseroot=caseroot)

    seed = (mem+int(date[0:4]+date[5:7]+date[8:10]))*100

    case.set_value("CONTINUE_RUN",False)
    case.set_value("RUN_REFDATE",date)
    case.set_value("RUN_STARTDATE",date)
    case.set_value("RUN_REFDIR",sdrestdir)
    case.set_value("REST_OPTION",'none')
    case.set_value("PROJECT","P93300007")
#    dout_s_root = case.get_value("DOUT_S_ROOT")
#    dout_s_root = os.path.join(os.path.dirname(dout_s_root),casename)
#    if dout_s_root.startswith("/glade/scratch"):
#        dout_s_root = dout_s_root.replace("/glade/scratch/","/glade/p/nsc/ncgd0042/")
#    case.set_value("DOUT_S_ROOT",dout_s_root)
    # restage user_nl files for each run
    for usermod in glob.iglob(user_mods_dir+"/user*"):
        safe_copy(usermod, caseroot)
#   add seed changes here

        #print("date abby = {}".format(seed))
        with open("user_nl_cam") as fin, open("user_nl_cam.new","w") as fout:
           input_lines = fin.readlines()
           for line in input_lines:
              if "cam_stoch_sppt_seed" in line:
                 fout.write(" cam_stoch_sppt_seed = {}\n".format(seed))
              else:
                 fout.write(line)

        os.rename("user_nl_cam.new", "user_nl_cam")

#   end seed changes
    case.case_setup()

    stage_refcase(rundir, sdrestdir, date)
    case.set_value("BATCH_SYSTEM", "none")
    safe_copy(os.path.join(caseroot,"env_batch.xml"),os.path.join(caseroot,"LockedFiles","env_batch.xml"))
    # this doesnt appear to work correctly
#    unlock_file("env_batch.xml",caseroot=caseroot)
#    case.flush()
#    lock_file("env_batch.xml",caseroot=caseroot)


def build_base_case(date, baseroot, basemonth,res, compset, overwrite,
                    sdrestdir, workflow, user_mods_dir, pecount=None):
    caseroot = os.path.join(baseroot,"{}_{}".format(workflow,date)+".00")
    if overwrite and os.path.isdir(caseroot):
        shutil.rmtree(caseroot)

    with Case(caseroot, read_only=False) as case:
        if not os.path.isdir(caseroot):
            case.create(os.path.basename(caseroot), cesmroot, compset, res,
                        run_unsupported=True, answer="r",walltime="04:00:00",
                        user_mods_dir=user_mods_dir, pecount=pecount, 
			output_root=os.getenv("SCRATCH"))
            # make sure that changing the casename will not affect these variables        
            case.set_value("EXEROOT",case.get_value("EXEROOT", resolved=True))
            case.set_value("RUNDIR",case.get_value("RUNDIR",resolved=True)+".00")

            case.set_value("RUN_TYPE","hybrid")
            case.set_value("GET_REFCASE",False)
            case.set_value("RUN_REFDIR",sdrestdir)
            case.set_value("RUN_REFCASE", "b.e21.f09_g17")
#            case.set_value("OCN_TRACER_MODULES","iage")
            case.set_value("OCN_TRACER_MODULES","")
            case.set_value("OCN_CHL_TYPE","diagnostic")
            case.set_value("NTASKS_WAV", 64)
            case.set_value("NTASKS_GLC",1)
            # pelayout for cesm2cam6 case
#            case.set_value("NTASKS_ATM",1152)
#            case.set_value("NTASKS_CPL",1152)
#            case.set_value("NTASKS_LND",1044)
#            case.set_value("NTASKS_ROF",1044)
#            case.set_value("NTASKS_ICE", 108)
#            case.set_value("NTASKS_OCN",  54)
#            case.set_value("NTASKS_WAV",  18)
#            case.set_value("ROOTPE_ICE",1044)
#            case.set_value("ROOTPE_OCN",1152)
#            case.set_value("ROOTPE_WAV",1206)


            case.set_value("STOP_OPTION","ndays")
            case.set_value("STOP_N", 45)
            case.set_value("REST_OPTION","none")

            case.set_value("CCSM_BGC","CO2A")
            case.set_value("EXTERNAL_WORKFLOW",True)
            case.set_value("CLM_NAMELIST_OPTS", "use_init_interp=.true.")

        rundir = case.get_value("RUNDIR")
        per_run_case_updates(case, date, sdrestdir, user_mods_dir, rundir)
        build.case_build(caseroot, case=case, save_build_provenance=False)

        return caseroot

def clone_base_case(date, caseroot, ensemble_start, ensemble_end, sdrestdir, user_mods_dir, overwrite):

    startval = "01"
    nint = len(startval)
    cloneroot = caseroot
    for i in range(ensemble_start+1, ensemble_end+1):
        member_string = '{{0:0{0:d}d}}'.format(nint).format(i)
        caseroot = caseroot[:-nint] + member_string
        if overwrite and os.path.isdir(caseroot):
            shutil.rmtree(caseroot)
        if not os.path.isdir(caseroot):
            with Case(cloneroot, read_only=False) as clone:
                print("Cloning case {} to {}".format(cloneroot,caseroot))
                clone.create_clone(caseroot, keepexe=True,
                                   user_mods_dir=user_mods_dir)
        with Case(caseroot, read_only=True) as case:
            # rundir is initially 00 reset to current member
            rundir = case.get_value("RUNDIR")
            rundir = rundir[:-nint]+member_string
            case.set_value("RUNDIR",rundir)
            per_run_case_updates(case, date, sdrestdir, user_mods_dir, rundir)

def _main_func(description):
    date, ensemble_start, ensemble_end = parse_command_line(sys.argv, description)

    # TODO make these input vars

    basemonth = int(date[5:7])
    baseyear = int(date[0:4])
    baseroot = os.getenv("FCST_WORK")
    res = "f09_g17"

    #if baseyear < 2014 or (baseyear == 2014 and basemonth < 11):
    if baseyear < 2014 or (baseyear == 2014 and basemonth < 12):
        compset = "BHIST"
    else:
        compset = "BSSP585"

#    print ("baseyear is {} basemonth is {}".format(baseyear,basemonth))

    overwrite = True

    sdrestdir = os.path.join(os.getenv("SCRATCH"),"cesm2cam6","StageIC","rest","{}".format(date))

    workflow = os.getenv("CESM_WORKFLOW")
    if not workflow:
        raise ValueError("env variable CESM_WORKFLOW must be defined")
    
    user_mods_dir = os.path.join(s2sfcstroot,"user_mods",workflow)

    # END TODO
    #print("basemonth = {}".format(basemonth))
    caseroot = build_base_case(date, baseroot, basemonth, res,
                               compset, overwrite, sdrestdir, workflow, user_mods_dir+'.base', pecount="S")
    clone_base_case(date, caseroot, ensemble_start, ensemble_end, sdrestdir, user_mods_dir, overwrite)

if __name__ == "__main__":
    _main_func(__doc__)
