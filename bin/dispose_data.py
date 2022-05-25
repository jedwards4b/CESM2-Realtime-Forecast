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
            date = datetime.datetime.strptime(args.date, '%Y-%m')
        except ValueError:
            raise ValueError("Incorrect data format, should be YYYY-MM")
    elif cdate:
        date = datetime.datetime.strptime(cdate, '%Y-%m')
    else:
        date = datetime.date.today()
        date = date.replace(day=date.day-1)

    return date.strftime("%Y-%m")

def send_data_to_campaignstore(timeseriesdir, source_file_list):
    dest_path = '/glade/campaign/cesm/development/espwg/SMYLE-CW3E-L83/timeseries/'
    
    client = initialize_client()    
#    token = get_globus_token(client)
    token = None
    globus_transfer_data = get_globus_transfer_data_struct(client, token)
    tc = get_transfer_client(client, globus_transfer_data)
    dest_endpoint = get_endpoint_id(tc,"NCAR Campaign Storage")
    src_endpoint = get_endpoint_id(tc,"XSEDE Expanse")
    transfer_data = get_globus_transfer_object(tc, src_endpoint, dest_endpoint, 'Smyle data transfer')

    for _file in source_file_list:
        transfer_data = add_to_transfer_request(transfer_data, os.path.join(timeseriesdir,_file), os.path.join(dest_path,_file))

    activate_endpoint(tc, src_endpoint)
    activate_endpoint(tc, dest_endpoint)
    complete_transfer_request(tc, transfer_data)
    
def _main_func(description):
    # disable this until globus is fixed
    # return
    date = parse_command_line(sys.argv, description)
    scratch = os.getenv("SCRATCH")
    # TODO make these input vars
    basecasename = "b.e21.BSMYLE-CW3E-L83.f09_g17"
    basemonth = date[5:7]
    baseroot = os.path.join(os.getenv("WORK"),"cases",basecasename)
    timeseriesdir = os.path.join(scratch,"SMYLE-CW3E-L83","timeseries")

    filepatterns = [os.path.join("ocn","proc","tseries","month_1","*.TEMP.*.nc"),
                    os.path.join("atm","proc","tseries","day_1","*.PSL.*.nc"),
                    os.path.join("atm","proc","tseries","month_1","*.PSL.*.nc")]
    os.chdir(timeseriesdir)
    filelist = []
    for filepattern in filepatterns:
        dirpattern = basecasename+"."+date+".*"+os.sep+filepattern
        print("dirpattern is {}".format(dirpattern))
        for _file in glob.iglob(dirpattern):
            filelist.append(_file)

    print("filelist is {}".format(filelist))
# comment out if NCAR systems are down    
    send_data_to_campaignstore(timeseriesdir, filelist)
        
        
if __name__ == "__main__":
    _main_func(__doc__)
