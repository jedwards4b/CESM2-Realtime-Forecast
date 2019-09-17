#!/usr/bin/env python
import os, sys
cesmroot = os.environ.get('CESM_ROOT')
s2sfcstroot = os.path.join(os.path.dirname(os.path.join(os.path.abspath(__file__))), os.path.pardir)

if cesmroot is None:
    raise SystemExit("ERROR: CESM_ROOT must be defined in environment")

# This is needed for globus_sdk
_LIBDIR=os.path.join(os.environ.get("HOME"),".local","lib","python3.6","site-packages")
sys.path.append(_LIBDIR)
_LIBDIR = os.path.join(cesmroot,"cime","scripts","Tools")
sys.path.append(_LIBDIR)
_LIBDIR = os.path.join(cesmroot,"cime","scripts","lib")
sys.path.append(_LIBDIR)

import datetime, threading, time, shutil
from standard_script_setup import *
from CIME.case             import Case
from CIME.utils            import run_cmd
from argparse              import RawTextHelpFormatter
from globus_utils          import *

def parse_command_line(args, description):
    parser = argparse.ArgumentParser(description=description,
                                     formatter_class=RawTextHelpFormatter)
    CIME.utils.setup_standard_logging_options(parser)
    parser.add_argument("--date",
                        help="Specify a start Date")

    args = CIME.utils.parse_args_and_handle_standard_logging_options(args, parser)
    cdate = os.environ.get("CYLC_TASK_CYCLE_POINT")

    if args.date:
        try:
            date = datetime.datetime.strptime(args.date, '%Y-%m-%d')
        except ValueError:
            raise ValueError("Incorrect data format, should be YYYY-MM-DD or YYYY-MM")
    elif cdate:
        date = datetime.datetime.strptime(cdate, '%Y-%m-%d')
    else:
        date = datetime.date.today()
        date = date.replace(day=date.day-1)

    return date.strftime("%Y-%m-%d")

def run_ncl_scripts():
    scripts = ("pp_priority1.ncl","pp_h1vertical.ncl", "pp_h4vertical.ncl")
    path = os.path.join(os.getenv("HOME"),"CESM2-Realtime-Forecast","bin")
    for script in scripts:
        t = threading.Thread(target="ncl "+os.path.join(path,script))
        t.start()
    while(threading.active_count() > 1):
        time.sleep(1)

    
def _main_func(description):
    date = parse_command_line(sys.argv, description)
    scratch = os.getenv("SCRATCH")
    # TODO make these input vars
    basecasename = "70Lwaccm6"
    basemonth = date[5:7]
    baseroot = os.path.join(os.getenv("WORK"),"cases",basecasename)
    member = os.getenv("CYLC_TASK_PARAM_member")
    caseroot = os.path.join(baseroot,"70Lwaccm6."+basemonth+"{0:02d}".format(member))
    with Case(caseroot, read_only=True) as case:
        rundir = case.get_value("RUNDIR")
        dout_s_root = case.get_value("DOUT_S_ROOT")
        
    # END TODO
    run_ncl_scripts()
    # Copy data to ftp site
    run_cmd("rsync -azvh "+os.path.join(scratch,"70Lwaccm6")+" jedwards@burnt.cgd.ucar.edu:/ftp/pub/jedwards/70Lwaccm6")

    # Clean up
    shutil.rmtree(rundir)
    for _dir in ("cpl","exp", "glc", "wav", "rest"):
        shutil.rmtree(os.path.join(dout_s_root,_dir))
    atmhistpath = os.path.join(dout_s_root,"atm","hist")
    for histfile in os.listdir(atmhistpath):
        if "h1" in histfile or "h4" in histfile:
            os.unlink(os.path.join(atmhistpath,histfile))
        
if __name__ == "__main__":
    _main_func(__doc__)
