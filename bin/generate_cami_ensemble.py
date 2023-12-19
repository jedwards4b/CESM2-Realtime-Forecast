#!/usr/bin/env python3
import os, sys
cesmroot = os.environ.get('CESM_ROOT')
s2sfcstroot = os.path.join(os.path.dirname(os.path.join(os.path.abspath(__file__))), os.path.pardir)

if cesmroot is None:
    raise SystemExit("ERROR: CESM_ROOT must be defined in environment")

# This is needed for globus_sdk
#_LIBDIR=os.path.join(os.environ.get("HOME"),".local","lib","python3.6","site-packages")
#sys.path.append(_LIBDIR)
_LIBDIR = os.path.join(cesmroot,"cime","scripts","Tools")
sys.path.append(_LIBDIR)
_LIBDIR = os.path.join(cesmroot,"cime","scripts","lib")
sys.path.append(_LIBDIR)

import random, threading, time, shutil
from datetime import timedelta, datetime
from standard_script_setup import *
from CIME.utils            import run_cmd, safe_copy, expect
from argparse              import RawTextHelpFormatter
#from globus_utils          import *

def parse_command_line(args, description):
    parser = argparse.ArgumentParser(description=description,
                                     formatter_class=RawTextHelpFormatter)
    CIME.utils.setup_standard_logging_options(parser)
    parser.add_argument("--date",
                        help="Specify a start Date")
    parser.add_argument("--ensemble-start",default=0,
                        help="Specify the first ensemble member")
    parser.add_argument("--ensemble-end",default=20,
                        help="Specify the last ensemble member")

    args = CIME.utils.parse_args_and_handle_standard_logging_options(args, parser)
    cdate = os.environ.get("CYLC_TASK_CYCLE_POINT")

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

#pylint: disable=unused-argument
def get_rvals(date, ensemble_start, ensemble_end):
    random.seed(int(date[0:4])+int(date[5:7])+int(date[8:10]))
    rvals = random.sample(range(1001),k=ensemble_end//2+1)
    print("Rvals are {}".format(rvals))
    rvals_file = os.path.join(os.getenv("WORK"),"cases",os.getenv("CESM_WORKFLOW"),"camic_"+date+".txt")
    with open(rvals_file,"w") as fd:
        fd.write("{}".format(rvals))
    return rvals


def create_cam_ic_perturbed(original, ensemble_start, ensemble_end, date, baserundir, outroot="b.e21.f09_g17.cam.i.", factor=0.15):
    rvals = get_rvals(date, ensemble_start, ensemble_end)

    outfile = os.path.join(baserundir,outroot+date+"-00000.nc")
    # first link the original ic file to the 0th ensemble member
    if os.path.exists(outfile):
        os.unlink(outfile)
    expect(os.path.isfile(original),"ERROR file {} not found".format(original))
    print("Linking {} to {}".format(original, outfile))
    rundir = os.path.dirname(outfile)
    if os.path.isdir(rundir):
        shutil.rmtree(rundir)
    os.makedirs(rundir)
    os.symlink(original, outfile)

    # for each pair of ensemble members create an ic file with same perturbation opposite sign
    month = date[5:7]

    local_path = "/glade/campaign/cesm/development/cross-wg/S2S/CESM2/CAMI/RP"
    perturb_files = []
    for i in range(ensemble_start+1,ensemble_end+1, 2):
        perturb_file = os.path.join("{}".format(month),
                                    "CESM2.cam.i.M{}.diff.{}.nc".format(month,rvals[i//2]))
        dirname = os.path.dirname(os.path.join(local_path,perturb_file))
        if not os.path.isdir(dirname):
            print("Creating directory {}".format(dirname))
            os.makedirs(dirname)
        perturb_files.append(perturb_file)

    for i in range(ensemble_start+1,ensemble_end+1, 2):
        perturb_file = os.path.join(local_path,perturb_files[i//2-1])
        outfile1 = os.path.join(baserundir[:-2]+"{:02d}".format(i), outroot+date+"-tmp.nc")
        outfile2 = os.path.join(baserundir[:-2]+"{:02d}".format(i+1), outroot+date+"-tmp.nc")
        print("Creating perturbed init file {}".format(outfile1))
        t = threading.Thread(target=create_perturbed_init_file,args=(original, perturb_file, outfile1, factor))
        t.start()
        t = threading.Thread(target=create_perturbed_init_file,args=(original, perturb_file, outfile2, -1*factor))
        t.start()
    while(threading.active_count() > 1):
        time.sleep(1)
#    for perturb_file in perturb_files:
#        os.unlink(os.path.join(local_path,perturb_file))


def create_perturbed_init_file(original, perturb_file, outfile, weight):
    ncflint = "ncflint"
    if not os.path.isdir(os.path.dirname(outfile)):
        os.makedirs(os.path.dirname(outfile))
    safe_copy(original, outfile)
    cmd = ncflint+" -O -C -v lat,lon,slat,slon,lev,ilev,hyai,hybi,hyam,hybm,US,VS,T,Q,PS -w {},1.0 {} {} {}".format(weight, perturb_file, original, outfile)
    run_cmd(cmd, verbose=True)
    os.rename(outfile, outfile.replace("-tmp.nc","-00000.nc"))


def _main_func(description):
    date, ensemble_start, ensemble_end = parse_command_line(sys.argv, description)
    workflow = os.getenv("CESM_WORKFLOW")

    sdrestdir = os.path.join(os.getenv("SCRATCH"),workflow,"StageIC","rest","{}".format(date))
    baserundir = os.path.join(os.getenv("SCRATCH"),workflow+"_"+date+".00","run.00")
    caminame = os.path.join(sdrestdir,"b.e21.f09_g17.cam.i.{date}-00000.nc".format(date=date))
    outroot = "b.e21.f09_g17.cam.i."
    print(f"baserundir is {baserundir}")
    create_cam_ic_perturbed(caminame,ensemble_start, ensemble_end, date,baserundir, outroot=outroot)

if __name__ == "__main__":
    _main_func(__doc__)
