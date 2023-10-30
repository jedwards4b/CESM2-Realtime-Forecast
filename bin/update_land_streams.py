#!/usr/bin/env python3
import os, sys
cesmroot = os.getenv("CESM_ROOT")
_LIBDIR = os.path.join(cesmroot,"cime","scripts","Tools")
sys.path.append(_LIBDIR)

import glob
from datetime import datetime, timedelta
from standard_script_setup import *
from CIME.case             import Case
#from CIME.utils            import run_cmd, expect
from argparse              import RawTextHelpFormatter

def parse_command_line(args, description):
    parser = argparse.ArgumentParser(description=description,
                                     formatter_class=RawTextHelpFormatter)
    CIME.utils.setup_standard_logging_options(parser)
    parser.add_argument("--date",
                        help="Specify a date for data retreval")
    parser.add_argument("--case", "-case", required=True, metavar="CASENAME",
                        help="(required) Specify the case name. "
                        "\nIf this is simply a name (not a path), the case directory is created in the current working directory."
                        "\nThis can also be a relative or absolute path specifying where the case should be created;"
                        "\nwith this usage, the name of the case will be the last component of the path.")

    args = CIME.utils.parse_args_and_handle_standard_logging_options(args, parser)
    if args.date:
        try:
            date = datetime.strptime(args.date, '%Y-%m-%d')
        except ValueError:
            raise ValueError("Incorrect data format, should be YYYY-MM-DD")
    else:
        date = datetime.today() - timedelta(days=1)

    return args.case, date

def _main_func(description):
    casename, _ = parse_command_line(sys.argv, description)
    caseroot = os.path.abspath(casename)

#    forcing_dir = "/glade/collections/nmme/ncgd0022/jcaron/CFSv2/forcing_files/"
    forcing_dir = "/glade/scratch/espstoch/forcing_files/"
    forcing_files = {"Precip": glob.glob(forcing_dir+"*Prec*.nc"),
                     "Solar": glob.glob(forcing_dir+"*Solar*.nc"),
                     "TPQW" : glob.glob(forcing_dir+"*TPQW*.nc")}

    with Case(caseroot, read_only=False) as case:
        rundir = case.get_value("RUNDIR")
        for ftype in ["Solar", "Precip", "TPQW"]:
            forcing_files[ftype] = sorted(forcing_files[ftype], reverse=True)
            streamfile = os.path.join(rundir,"datm.streams.txt.CLMCRUNCEP."+ftype)
            newfile = os.path.join(caseroot, "user_"+os.path.basename(streamfile))
            #print("New forcing_files from {} to {}".format(forcing_files["Solar"][0],forcing_files["Solar"][-1]))
            with open(streamfile) as fin, open(newfile,"w") as fout:
                input_lines = fin.readlines()
                skip_line = False
                for line in input_lines:
                    if "</filePath>" in line:
                        skip_line=False
                    if skip_line:
                        continue
                    if "domain.lnd" in line:
                        line = "domain.ncepCFSv2.c2019.0.2d.nc\n"
                    if "clmforc.cruncep" in line or "clmforc.NCEPCFSv2" in line:
                        while forcing_files[ftype]:
                            newline = os.path.basename(forcing_files[ftype].pop())
                            fout.write(newline+"\n")
                        continue
                    fout.write(line)
                    if "<filePath>" in line:
                        skip_line=True
                        fout.write("/glade/scratch/espstoch/forcing_files/\n")

if __name__ == "__main__":
    _main_func(__doc__)
