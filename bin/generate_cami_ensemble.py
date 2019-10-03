#!/usr/bin/env python
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

import datetime, random, threading, time
from standard_script_setup import *
from CIME.utils            import run_cmd, safe_copy
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

def get_rvals(date, ensemble):
    rvals_file = os.path.join(os.getenv("WORK"),"cases","70Lwaccm6","camic_"+date+".txt")
    if os.path.isfile(rvals_file):
        rvals = []
        with open(rvals_file,"r") as fd:
            rawvals = fd.read().split(',')
        for rval in rawvals:
            if rval.startswith('['):
                rval = int(rval[1:])
            elif rval.endswith(']'):
                rval = int(rval[:-1])
            else:
                rval = int(rval)
            rvals.append(rval)
    else:
        rvals = random.sample(range(500),k=ensemble//2)
        #save these rvals to a file
        with open(rvals_file,"w") as fd:
            fd.write("{}".format(rvals))
    return rvals

def get_data_from_campaignstore(files, source_path, dest_path):
    
    client = initialize_client()
    globus_transfer_data = get_globus_transfer_data_struct(client)
    tc = get_transfer_client(client, globus_transfer_data)
    dest_endpoint = get_endpoint_id(tc,"NCAR Campaign Storage")
    src_endpoint = get_endpoint_id(tc,"NCAR GLADE")
    transfer_data = get_globus_transfer_object(tc, src_endpoint, dest_endpoint, 'S2S data transfer')
    dotrans = False
    for _file in files:
        if not os.path.isfile(os.path.join(dest_path,_file)):
            transfer_data = add_to_transfer_request(transfer_data, os.path.join(source_path, _file), os.path.join(dest_path,_file))
            dotrans = True
    if dotrans:
        activate_endpoint(tc, src_endpoint)
        activate_endpoint(tc, dest_endpoint)
        complete_transfer_request(tc, transfer_data)

def create_cam_ic_perturbed(original, ensemble, date, baserundir, outroot="b.e21.BWHIST.SD.f09_g17.002.nudgedOcn.cam.i.", factor=0.15):
    rvals = get_rvals(date, ensemble)

    outfile = os.path.join(baserundir,outroot+date+"-00000.nc")
    # first link the original ic file to the 0th ensemble member
    if os.path.exists(outfile):
        os.unlink(outfile)
    print("Linking {} to {}".format(original, outfile))
    os.symlink(original, outfile)

    # for each pair of ensemble members create an ic file with same perturbation opposite sign
    month = date[5:7]
    collections_path = '/gpfs/csfs1/cesm/collections/S2Sfcst/'
    local_path = os.path.join(os.getenv("SCRATCH"),"S2Sfcst")
    perturb_files = []
    for i in range(1,ensemble, 2):
        perturb_file = os.path.join("S2S_70LIC",
                                    "{}".format(month),
                                    "70Lwaccm6.cam.i.M{}.diff.{}.nc".format(month,rvals[i//2]))
        if not os.path.isdir(os.path.basename(os.path.join(local_path,perturb_file))):
            dirname = os.path.basename(os.path.join(local_path,perturb_file))
            print("Creating directory {}".format(dirname))
            os.makedirs(dirname)
        perturb_files.append(perturb_file)
    get_data_from_campaignstore(perturb_files, collections_path, local_path)


    for i in range(1,ensemble, 2):
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
    for perturb_file in perturb_files:
        os.unlink(os.path.join(local_path,perturb_file))
    

def create_perturbed_init_file(original, perturb_file, outfile, weight):
    ncflint = "ncflint"
    safe_copy(original, outfile)
    cmd = ncflint+" -A -v US,VS,T,Q,PS -w {},1.0 {} {} {}".format(weight, perturb_file, original, outfile)    
    run_cmd(cmd, verbose=True)
    os.rename(outfile, outfile.replace("-tmp.nc","-00000.nc"))


def _main_func(description):
    date = parse_command_line(sys.argv, description)

    # TODO make these input vars
    sdrestdir = os.path.join(os.getenv("SCRATCH"),"S2S_70LIC_globus","SDnudgedOcn","rest","{}".format(date))
    ensemble = 10
    baserundir = os.path.join(os.getenv("SCRATCH"),"70Lwaccm6."+date[5:7]+".00","run.00")
    # END TODO

    caminame = os.path.join(sdrestdir,"b.e21.BWHIST.SD.f09_g17.002.nudgedOcn.cam.i.{date}-00000.nc".format(date=date))
    create_cam_ic_perturbed(caminame,ensemble, date,baserundir)

if __name__ == "__main__":
    _main_func(__doc__)
