#!/usr/bin/env python
import os, sys
_LIBDIR = os.path.join(os.sep+"glade","scratch","jedwards","cheyenne","cime-nightly-build","cime","scripts","Tools")
sys.path.append(_LIBDIR)
import datetime
from standard_script_setup import *
from CIME.utils            import run_cmd, expect
from argparse              import RawTextHelpFormatter

def parse_command_line(args, description):
    parser = argparse.ArgumentParser(description=description,
                                     formatter_class=RawTextHelpFormatter)
    CIME.utils.setup_standard_logging_options(parser)
    parser.add_argument("--date",
                        help="Specify a date for data retreval")
    args = CIME.utils.parse_args_and_handle_standard_logging_options(args, parser)

    if args.date:
        try:
            date = datetime.datetime.strptime(args.date, '%Y-%m-%d')
        except ValueError:
            raise ValueError("Incorrect data format, should be YYYY-MM-DD")
    else:
        date = datetime.date.today()


    return date

def get_julian_day_of_year(date):
    day1 = date.replace(month=1, day=1)
    return 1 + int ((date-day1).total_seconds()/(24*3600))

def _main_func(description):
    date = parse_command_line(sys.argv, description)
    jday = get_julian_day_of_year(date)
    dataroot = "https://goldsfs1.gesdisc.eosdis.nasa.gov/data/GEOS5/DFPITI3NVASM.5.12.4/{}/{:03d}/.hidden/".format(date.year,jday)
    cmd = "wget -np -r -nH --directory-prefix=/glade/scratch/jedwards/NASAdata/ -A'GEOS.*' "+dataroot
    err, output, _ = run_cmd(cmd, combine_output=True, verbose=True)
    expect(err == 0,"Could not connect to repo via '{}'\nThis is most likely either a proxy, or network issue.\nOutput:\n{}".format(cmd, output.encode('utf-8')))


if __name__ == "__main__":
    _main_func(__doc__)
