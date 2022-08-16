#!/usr/bin/env python3
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

import glob
from datetime import datetime, timedelta
from standard_script_setup import *
from argparse              import RawTextHelpFormatter
from globus_utils          import *
from CIME.utils            import safe_copy

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
            date = datetime.strptime(args.date, '%Y-%m-%d')
        except ValueError as verr:
            raise ValueError("Incorrect data format, should be YYYY-MM-DD or YYYY-MM") from verr
    elif cdate:
        date = datetime.strptime(cdate, '%Y-%m-%d')
    else:
        date = datetime.today() - timedelta(days=1)


    return date.strftime("%Y-%m-%d")

def get_ocn_src_path(src_root, date, count=0):
    oyr = int(date[:4]) - 1749
    odate = "{:04d}".format(oyr)+date[4:]
    src_dir_path = os.path.join(src_root,"cesm","development","cross-wg","S2S","CESM2","OCEANIC")
    src_path = os.path.join(src_dir_path, "{}-00000".format(odate))
    if os.path.isdir(src_path):
        return(src_path)
    if count > 30:
        print("No suitable ocean restart file found")
        return None
    ndate = datetime.strptime(date, '%Y-%m-%d') - timedelta(days=1)
    return(get_ocn_src_path(src_root, ndate.strftime("%Y-%m-%d"), count=count+1))



def get_data_from_campaignstore(date):

    source_root_local = "/glade/campaign"
    source_path = 'cesm/development/cross-wg/S2S/CESM2/CLIMOCEANIC/{date}-00000/'.format(date=date)

    source_path = get_ocn_src_path(source_root_local, date)

    dest_path = os.path.join(os.getenv("SCRATCH"),"cesm2cam6climoOCNclimoLND","Ocean","rest","{}".format(date))


#    if os.path.exists(os.path.join(dest_path,"rpointer.ocn.restart")):
#        print("Data already exists in {}".format(dest_path))
#        return
#    if(not os.path.exists(dest_path)):
    os.makedirs(dest_path)
    lnd_source_path = 'cesm/development/cross-wg/S2S/CESM2/CLIMOLND/{}-00000/'.format(date)


    if os.path.isdir(os.path.join(source_root_local,source_path)) and os.path.isdir(os.path.join(source_root_local,lnd_source_path)):
        source_path = os.path.join(source_root_local,source_path)
        lnd_source_path = os.path.join(source_root_local,lnd_source_path)
        for _file in glob.iglob(source_path+"/*"):
            safe_copy(_file, dest_path)
        for _file in glob.iglob(lnd_source_path+"/*"):
            safe_copy(_file, dest_path)
    else:
        print( "path {} {}".format(os.path.join(source_root_local,source_path),os.path.join(source_root_local,\
lnd_source_path)))
        return

    refname = "b.e21.f09_g17"

    for lndfile in glob.iglob(dest_path+"I2000*"):
        newfile = lndfile.replace("I2000Clm50BgcCrop.002runRealtimeClimo_contd4",refname)
        # newfile = lndfile.replace("I2000Clm50BgcCrop.002runContd",refname)
        # newfile = lndfile.replace("I2000Clm50BgcCrop.002run",refname)
        print("Renaming {} to {}".format(lndfile,newfile))
        os.rename(os.path.join(dest_path,lndfile), os.path.join(dest_path,newfile))


    cam_source_path = "/glade/campaign/cesm/development/cross-wg/S2S/CESM2/CAMI/CFSv2/"
    cami = os.path.join(cam_source_path,"CESM2_NCEP_0.9x1.25_L32.cam2.i.{}-00000.nc".format(date))
    camo = os.path.join(dest_path, "b.e21.f09_g17.cam.i.{}-00000.nc".format(date))
    if os.path.isfile(camo):
        os.remove(camo)
    if os.path.isfile(cami):
        safe_copy(cami, camo)
    else:
        print("No cami file {} found".format(cami))

def _main_func(description):
    date = parse_command_line(sys.argv, description)

    get_data_from_campaignstore(date)

if __name__ == "__main__":
    _main_func(__doc__)
