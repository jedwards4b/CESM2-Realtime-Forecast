#!/usr/bin/env python
import os, shutil, sys, argparse

from argparse              import RawTextHelpFormatter    
from datetime import timedelta, date, datetime
from ecflow import Defs, Suite, Task, Edit, Trigger, Family

cesmroot=os.path.join(os.getenv("HOME"),"cesm2_1")

_LIBDIR = os.path.join(cesmroot,"cime","scripts","Tools")                                                                                       
sys.path.append(_LIBDIR)                                                                                                                        
_LIBDIR = os.path.join(cesmroot,"cime","scripts","lib")                                                                                         
sys.path.append(_LIBDIR)                                                                                                                        
from standard_script_setup import *
from CIME.utils import expect

def parse_command_line(args, description):
    parser = argparse.ArgumentParser(description=description,
                                     formatter_class=RawTextHelpFormatter)
    CIME.utils.setup_standard_logging_options(parser)
    parser.add_argument("--date",
                        help="Specify a start Date")

    args = CIME.utils.parse_args_and_handle_standard_logging_options(args, parser)

    if args.date:
        try:
            date = datetime.strptime(args.date, '%Y-%m-%d')
        except ValueError as verr:
            raise ValueError("Incorrect data format, should be YYYY-MM-DD or YYYY-MM") from verr
    else:
        date = datetime.today() - timedelta(days=1)


    return date.strftime("%Y-%m-%d")

def workflow(description):
    print("Creating suite definition")
    home = os.path.join(os.getenv("WORK"), "sandboxes", "CESM2-Realtime-Forecast","ecflow")
    workflow = os.getenv("CESM_WORKFLOW")
    machine = os.getenv("NCAR_HOST")
    user = os.getenv("USER")
    expect(home and workflow and machine and user,f"Missing required env variable: home={home} CESM_WORKFLOW={workflow} machine={machine} user={user}")
    


    # user changes here
    ensemble_start = 0
    ensemble_end = 20
    project="P93300606"

    #fcstdate="2023-09-25"
    fcstdate = parse_command_line(sys.argv, __doc__)
    
    print(f"running for {fcstdate}")
    fcsthome=os.path.realpath(os.path.join(os.path.dirname(__file__), os.pardir))
    fcstwork=os.path.join("/glade/work/",user,machine,"cases","cesm2cam6")
    
    print(f"workflow={workflow} cesmroot={cesmroot} fcsthome={fcsthome} fcstwork={fcstwork}")
    
    run_member = os.path.join(home,workflow,"run_family","run_member.ecf")
    pp_member =  os.path.join(home,workflow,"postprocess_family","postprocess_member.ecf")
    
    for i in range(ensemble_start, ensemble_end+1):
        new_member = os.path.join(home,workflow,"run_family",f"run_member{i:02d}.ecf")
        shutil.copy(run_member, new_member)
        new_pp = os.path.join(home,workflow,"postprocess_family",f"postprocess_member{i:02d}.ecf")
        shutil.copy(pp_member, new_pp)
    
    defs = Defs(Suite(workflow,
                      Edit(PROJECT=project,
                           ECF_JOB_CMD="qsub %ECF_JOB% 1>%ECF_JOBOUT% 2>&1",
                           CESM_WORKFLOW=workflow,
                           CESM_ROOT=cesmroot,
                           FCSTDATE=fcstdate,
                           ENSEMBLE_START=ensemble_start,
                           ENSEMBLE_END=ensemble_end,
                           FCST_HOME=fcsthome,
                           FCST_WORK=fcstwork,
                           ECF_INCLUDE=os.path.join(home,"include"),
                           ECF_PORT=4238,
                           ECF_HOST="derecho6",
                           ECF_HOME=home,
                           LOGDIR=os.path.join(home,"log")),
                      Task("getdata"),
                      Task("buildcase").add(
                          Trigger("getdata == complete")),
                      Family("run_family").add(
                          [Task(f"run_member{i:02d}",
                                Trigger("/"+workflow+"/buildcase == complete"))
                for i in range(ensemble_start, ensemble_end+1)]),
                      Family("postprocess_family").add(
                          [Task(f"postprocess_member{i:02d}",
                                Trigger("/"+workflow+f"/run_family/run_member{i:02d} == complete"))
                           for i in range(ensemble_start, ensemble_end+1)]),
                      ))

    print(defs)

    print("Checking job creation: .ecf -> .job0")
    print(defs.check_job_creation())

    print("Saving definition to file 'cesm2cam6.def'")
    defs.save_as_defs("cesm2cam6.def")

# To restore the definition from file 'test.def' we can use:
# restored_defs = ecflow.Defs("test.def")

if __name__ == "__main__":
    workflow(__doc__)
