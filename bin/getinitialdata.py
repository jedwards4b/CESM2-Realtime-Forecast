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

import datetime, glob
from standard_script_setup import *
from argparse              import RawTextHelpFormatter
from globus_utils          import *

def parse_command_line(args, description):
    parser = argparse.ArgumentParser(description=description,
                                     formatter_class=RawTextHelpFormatter)
    CIME.utils.setup_standard_logging_options(parser)
    parser.add_argument("--date",
                        help="Specify a start Date")

    args = CIME.utils.parse_args_and_handle_standard_logging_options(args, parser)
    cdate = os.getenv("CYLC_TASK_CYCLE_POINT")

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

def get_data_from_campaignstore(date):
    source_path = '/gpfs/csfs1/cesm/development/cross-wg/S2S/SDnudgedOcn/rest/{date}-00000/'.format(date=date)
#    source_path = '/gpfs/csfs1/cesm/development/cross-wg/S2S/SD/rest/{}-00000/'.format(date)
    dest_path = os.path.join(os.getenv("SCRATCH"),"S2S_70LIC_globus","SDnudgedOcn","rest","{}".format(date))
    if os.path.exists(dest_path):
        print("Data already exists in {}".format(dest_path))
        return

    lnd_source_path = '/gpfs/csfs1/cesm/development/cross-wg/S2S/land/rest/{}-00000/'.format(date)
    client = initialize_client()
    globus_transfer_data = get_globus_transfer_data_struct(client)
    tc = get_transfer_client(client, globus_transfer_data)
    src_endpoint = get_endpoint_id(tc,"NCAR Campaign Storage")
    dest_endpoint = get_endpoint_id(tc,"NCAR GLADE")

    transfer_data = get_globus_transfer_object(tc, src_endpoint, dest_endpoint, 'S2S initial data transfer')
    transfer_data = add_to_transfer_request(transfer_data, source_path, dest_path)
    transfer_data = add_to_transfer_request(transfer_data, lnd_source_path, dest_path)
#    transfer_data = add_to_transfer_request(transfer_data, cam_source_path, os.path.join(dest_path,os.path.basename(cam_source_path)))
    activate_endpoint(tc, src_endpoint)
    activate_endpoint(tc, dest_endpoint)
    if complete_transfer_request(tc, transfer_data):
        for lndfile in glob.iglob(dest_path+"I2000*"):
            newfile = lndfile.replace("I2000Clm50BgcCrop.002run","b.e21.BWHIST.SD.f09_g17.002")
            print("Renaming {} to {}".format(lndfile,newfile))
            os.rename(os.path.join(dest_path,lndfile), os.path.join(dest_path,newfile))

def _main_func(description):
    date = parse_command_line(sys.argv, description)

    get_data_from_campaignstore(date)

if __name__ == "__main__":
    _main_func(__doc__)
