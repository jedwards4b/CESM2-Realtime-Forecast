#!/usr/bin/env python3
import os, sys
cesmroot = os.environ.get('CESM_ROOT')
_LIBDIR = os.path.join(cesmroot,"cime","scripts","Tools")

sys.path.append(_LIBDIR)
from datetime import datetime as dt
from datetime import timedelta
import datetime, tarfile
from standard_script_setup import *
from CIME.utils import run_cmd, expect
from argparse import RawTextHelpFormatter
from calendar import monthrange

def parse_command_line(args, description):
    parser = argparse.ArgumentParser(description=description,
                                     formatter_class=RawTextHelpFormatter)
    CIME.utils.setup_standard_logging_options(parser)
    parser.add_argument("--date",
                        help="Specify a date for data retreval")
    args = CIME.utils.parse_args_and_handle_standard_logging_options(args, parser)
    fullmonth = True
    if args.date:
        try:
            date = datetime.datetime.strptime(args.date, '%Y-%m-%d')
        except ValueError:
            try:
                date = datetime.datetime.strptime(args.date, '%Y-%m')
                fullmonth = True
            except ValueError:
                raise ValueError("Incorrect data format, should be YYYY-MM-DD or YYYY-MM")
    else:
#       date = datetime.date.today() - datetime.timedelta(days=1)
	date = datetime.datetime.strptime(dt.today().strftime('%Y-%m'),'%Y-%m')
#	date = datetime.datetime.strptime(dt.today().strftime('%Y-%m'),'%Y-%m')-timedelta(1)
	print(date)

    return date, fullmonth

def get_julian_day_of_year(date):
    day1 = date.replace(month=1, day=1)
    return 1 + int ((date-day1).total_seconds()/(24*3600))

def fcst_files(members, fcst_time):
    for tarinfo in members:
        if fcst_time in os.path.basename(tarinfo.name):
            yield tarinfo

def _main_func(description):
    date, fullmonth = parse_command_line(sys.argv, description)
#    cdas_root = os.path.join(os.environ.get("ARCHIVEROOT"),"cdas_data")
    cdas_root = os.path.join(os.sep+"glade","scratch","espstoch","cdas_data")
    os.chdir(cdas_root)
    if fullmonth:
        fday = 1
        _, lday = monthrange(date.year, date.month)
    else:
        fday = date.day
        lday = date.day
    for day in range(fday, lday+1):
        infile = os.path.join(os.sep+"glade","collections","rda","data","ds094.0",str(date.year),"cdas1.{}{:02d}{:02d}.sfluxgrbf.tar".format(date.year,date.month,day))
        expect(os.path.isfile(infile),"Could not find input file {}".format(infile))
        tar = tarfile.open(infile)
        fhr = "f06"
        filestoextract = fcst_files(tar, fhr)
        tar.extractall(members=filestoextract)
        for tarinfo in fcst_files(tar, fhr):
            oldfile = os.path.basename(tarinfo.name)
            stime = oldfile[7:9]
            newfile = "cdas1.{}{:02d}{}.sfluxgrb{}.grib2".format(date.strftime("%Y%m"),day,stime,fhr)
            print("Rename {} to {}".format(oldfile, newfile))
            os.rename(oldfile, newfile)
        tar.close()


if __name__ == "__main__":
    _main_func(__doc__)
