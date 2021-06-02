#!/usr/bin/env python3
import os, sys
cesmroot = os.environ.get('CESM_ROOT')
_LIBDIR = os.path.join(cesmroot,"cime","scripts","Tools")
sys.path.append(_LIBDIR)
from datetime import timedelta, datetime
from standard_script_setup import *
from CIME.utils            import run_cmd, expect
from argparse              import RawTextHelpFormatter
from calendar              import monthrange

def parse_command_line(args, description):
    parser = argparse.ArgumentParser(description=description,
                                     formatter_class=RawTextHelpFormatter)
    CIME.utils.setup_standard_logging_options(parser)
    parser.add_argument("--date",
                        help="Specify a date for data retreval")
    args = CIME.utils.parse_args_and_handle_standard_logging_options(args, parser)
    fullmonth = False
    if args.date:
        try:
            date = datetime.strptime(args.date, '%Y-%m-%d')
        except ValueError:
            try:
                date = datetime.strptime(args.date, '%Y-%m')
                fullmonth = True
            except ValueError:
                raise ValueError("Incorrect data format, should be YYYY-MM-DD or YYYY-MM")
    else:
        date = datetime.today() - timedelta(days=1)

    return date, fullmonth


def get_julian_day_of_year(date):
    day1 = date.replace(month=1, day=1)
    return 1 + int ((date-day1).total_seconds()/(24*3600))

def _main_func(description):
    date, fullmonth = parse_command_line(sys.argv, description)
    if fullmonth:
        fday = 1
        _, lday = monthrange(date.year, date.month)
    else:
        fday = date.day
        lday = date.day

    print( "Getting data for range {} to {}".format(fday, lday))
    for day in range(fday, lday+1):
        tdate = date.replace(day=day)
        jday = get_julian_day_of_year(tdate)
        print("Getting data for year {} julian date {}".format(date.year, jday))
        dataroot = "https://goldsfs1.gesdisc.eosdis.nasa.gov/data/GEOS5/DFPITI3NVASM.5.12.4/{}/{:03d}/.hidden/".format(date.year,jday)
        cmd = "wget -nc -np -r -nH --directory-prefix=/glade/scratch/jedwards/NASAdata/ -A'GEOS.*.V01.nc4' "+dataroot
        err, output, _ = run_cmd(cmd, combine_output=True, verbose=True)
        expect(err == 0,"Could not connect to repo via '{}'\nThis is most likely either a proxy, or network issue.\nOutput:\n{}".format(cmd, output.encode('utf-8')))


        dataroot = "https://goldsfs1.gesdisc.eosdis.nasa.gov/data/GEOS5/DFPITI3NXASM.5.12.4/{}/{:03d}/.hidden/".format(date.year,jday)
        cmd = "wget -nc -np -r -nH --directory-prefix=/glade/scratch/jedwards/NASAdata/ -A'GEOS.*.V01.nc4' "+dataroot
        err, output, _ = run_cmd(cmd, combine_output=True, verbose=True)
        expect(err == 0,"Could not connect to repo via '{}'\nThis is most likely either a proxy, or network issue.\nOutput:\n{}".format(cmd, output.encode('utf-8')))


if __name__ == "__main__":
    _main_func(__doc__)
