#!/usr/bin/env python
import os, sys, shutil
from argparse import RawTextHelpFormatter
from datetime import datetime

cesmroot = "/glade/work/jedwards/sandboxes/cesm2_1/"
os.environ["CESM_ROOT"] = cesmroot
_LIBDIR = os.path.join(cesmroot,"cime","scripts","Tools")
sys.path.append(_LIBDIR)
_LIBDIR = os.path.join(cesmroot,"cime","scripts","lib")
sys.path.append(_LIBDIR)
_LIBDIR = "/glade/u/apps/derecho/23.06/spack/opt/spack/lmod/8.7.20/gcc/7.5.0/pdxb/lmod/lmod/init/"
sys.path.append(_LIBDIR)

from standard_script_setup import *
from CIME.utils import run_cmd, expect
from env_modules_python import module

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
        fmtdate = date.strftime("%Y-%m-%d")
    else:
        ocndata = os.path.join("/glade","campaign","cesm","development","cross-wg","S2S","SDnudgedOcn","rest")
        all_subdirs = [os.path.join(ocndata,d) for d in os.listdir(ocndata) if os.path.isdir(os.path.join(ocndata,d))]
        latest = max(all_subdirs, key=os.path.getmtime)
        fmtdate = (latest[len(ocndata)+1:])[:10]

    return fmtdate


def _main_func(description):
    # get the requested date or by default the latest date for which ocn data is available
    os.environ["MODULEPATH"] = "/glade/u/apps/cseg/derecho/modules/23.06/Core" + \
        os.pathsep + "/glade/u/apps/derecho/modules/environment"
    module("load"," cesmdev/1.0 ncarenv/23.06 ")
    module("load", "ecflow/5.9.0")
    module("list")
    date = parse_command_line(sys.argv, description)
    print(f"Running for date {date}")
    os.environ["CESM_WORKFLOW"]="cesm2cam6"
    os.environ["ECF_PORT"]="4238"
    os.environ["ECF_HOST"]="derecho6"

    fcstroot = "/glade/work/jedwards/sandboxes/CESM2-Realtime-Forecast"
    ecflowroot = os.path.join(fcstroot,"ecflow")
#    print(f"Initialize modules")
#    run_cmd("/glade/u/apps/derecho/23.06/spack/opt/spack/lmod/8.7.20/gcc/7.5.0/pdxb/lmod/lmod/init/env_modules_python.py")
#    stat, pycode, err = run_cmd('/glade/u/apps/derecho/23.06/spack/opt/spack/lmod/8.7.20/gcc/7.5.0/pdxb/lmod/lmod/libexec/lmod python load cesmdev ncarenv/23.06 ecflow', verbose=True)
#    print(f"load modules")
#    exec(pycode)
    print(f"cd to {ecflowroot}")
    os.chdir(ecflowroot)
    print(f"Run workflow setup for {date}")
    run_cmd(os.path.join(ecflowroot,f"workflow.py --date {date}"),verbose=True)
    print("Start ensemble")
    run_cmd(os.path.join(ecflowroot,"cesm2cam6","client.py"), verbose=True)
    

if __name__ == "__main__":
    _main_func(__doc__)
