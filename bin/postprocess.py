#!/usr/bin/env python
import os, glob, sys

_LIBDIR = os.path.join("/glade/work/nanr/cesm_tags/cesm2.1.4-SMYLE/cime", "scripts", "Tools")
sys.path.append(_LIBDIR)
from standard_script_setup          import *
from CIME.utils import run_cmd, safe_copy, expect
from CIME.case import Case
logger = logging.getLogger(__name__)

caseroot = os.getcwd()
pp_path = os.getenv("POSTPROCESS_PATH")
if not os.path.isdir("./postprocess"):
    cp = os.path.join(pp_path,"cesm-env2","bin","create_postprocess")
    print("Create postprocess dir in {}".format(caseroot))
    run_cmd("{} -caseroot {}".format(cp,caseroot),verbose=True)
    run_cmd("./pp_config --set TIMESERIES_OUTPUT_ROOTDIR=/glade/p/cesm/espwg/CESM2-SMYLE/timeseries/{}".format(caseroot),from_dir="postprocess",verbose=True)
    #run_cmd("{} -caseroot {}".format(cp,caseroot),from_dir=caseroot,verbose=True)
    expect(os.path.isdir("./postprocess"),"postprocess dir NOT created! Die!! {} {}".format(cp,caseroot))
with Case(caseroot, read_only=False) as case:
    case.submit(job="timeseries")
