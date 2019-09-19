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

import datetime, time, shutil, glob
from subprocess import Popen
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

def send_data_to_campaignstore(source_path):
    dest_path = '/gpfs/csfs1/cesm/development/cross-wg/S2S/'
    
    client = initialize_client()
    globus_transfer_data = get_globus_transfer_data_struct(client)
    tc = get_transfer_client(client, globus_transfer_data)
    dest_endpoint = get_endpoint_id(tc,"NCAR Campaign Storage")
    src_endpoint = get_endpoint_id(tc,"NCAR GLADE")
    transfer_data = get_globus_transfer_object(tc, src_endpoint, dest_endpoint, 'S2S data transfer')
    transfer_data = add_to_transfer_request(transfer_data, source_path, dest_path)
    activate_endpoint(tc, src_endpoint)
    activate_endpoint(tc, dest_endpoint)
    complete_transfer_request(tc, transfer_data)
    
def _main_func(description):
    date = parse_command_line(sys.argv, description)
    scratch = os.getenv("SCRATCH")
    # TODO make these input vars
    basecasename = "70Lwaccm6"
    basemonth = date[5:7]
    baseroot = os.path.join(os.getenv("WORK"),"cases",basecasename)
    sdrestdir = os.path.join(scratch,"S2S_70LIC_globus","SD","rest","{}".format(date))
    if os.path.isdir(sdrestdir):
        shutil.rmtree(sdrestdir)        
    for i in range(0,10):
        member = "{0:02d}".format(i)
        caseroot = os.path.join(baseroot,basecasename+"."+basemonth+"."+member)
        with Case(caseroot, read_only=True) as case:
            rundir = case.get_value("RUNDIR")
            dout_s_root = case.get_value("DOUT_S_ROOT")
        
        # Copy data to ftp site
        run_cmd("rsync -azvh "+os.path.join(scratch,"70Lwaccm6")+" jedwards@burnt.cgd.ucar.edu:/ftp/pub/jedwards/70Lwaccm6")

        # Clean up
        if os.path.isdir(rundir):
            for _file in glob.iglob(os.path.join(rundir,"*"+date+"*")):
                os.unlink(os.path.join(rundir,_file))

        for _dir in ("cpl","esp", "glc", "wav", "rest"):
            if os.path.isdir(os.path.join(dout_s_root,_dir)):
                shutil.rmtree(os.path.join(dout_s_root,_dir))
        atmhistpath = os.path.join(dout_s_root,"atm","hist")
        icehistpath = os.path.join(dout_s_root,"ice","hist")
        for histfile in os.listdir(atmhistpath):
            if "h1" in histfile or "h4" in histfile:
                os.unlink(os.path.join(atmhistpath,histfile))
        #Concatinate cice history into a single file

        fnameout = basecasename+"."+basemonth+"."+date+"."+member+".cice.h.nc"
        run_cmd("ncrcat * "+fnameout,from_dir=icehistpath)
        for _file in glob.iglob(os.path.join(icehistpath,"*ice.h.*.nc")):
            os.unlink(_file)
        send_data_to_campaignstore(dout_s_root+os.sep )
        
if __name__ == "__main__":
    _main_func(__doc__)
