#!/usr/bin/env python
import os, sys
cesmroot = os.getenv("CESM_ROOT")
_LIBDIR = os.path.join(cesmroot,"cime","scripts","Tools")
sys.path.append(_LIBDIR)

import datetime, glob
from standard_script_setup import *
import CIME.build   as build
from CIME.case             import Case
from CIME.utils            import run_cmd, expect
from argparse              import RawTextHelpFormatter
#from calendar              import monthrange

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
            date = datetime.datetime.strptime(args.date, '%Y-%m-%d')
        except ValueError:
            raise ValueError("Incorrect data format, should be YYYY-MM-DD or YYYY-MM")
    else:
        date = datetime.date.today()
        date = date.replace(day=date.day-1)

    return args.case, date


def get_julian_day_of_year(date):
    day1 = date.replace(month=1, day=1)
    return 1 + int ((date-day1).total_seconds()/(24*3600))

def _main_func(description):
    casename, _ = parse_command_line(sys.argv, description)
    compset = "I2000Clm50BgcCrop"
    grid = "f09_f09_mg17"
    caseroot = os.path.abspath(casename)
                  #"RUN_TYPE":"hybrid",
                  #"RUN_REFDIR":"/gpfs/fs1/scratch/sglanvil/archive/I2000Clm50BgcCrop.002/rest/0743-01-01-00000",
                  #"RUN_REFCASE":"I2000Clm50BgcCrop.002",
                  #"RUN_REFDATE":"0743-01-01",
                  #"GET_REFCASE":"TRUE",
                  #"RUN_STARTDATE":"1979-01-01",
    xmlchanges = {"CONTINUE_RUN":"TRUE",
                  "STOP_OPTION":"nmonths",
                  "STOP_N":11,
                  "REST_OPTION":"ndays",
                  "REST_N":1,
                  "DOUT_S_SAVE_INTERIM_RESTART_FILES":"TRUE",
                  "DATM_CLMNCEP_YR_ALIGN":1979,
                  "DATM_CLMNCEP_YR_START":1979,
                  "DATM_CLMNCEP_YR_END":2019,
                  "DATM_MODE":"CLMCRUNCEP"}
    clm_namelist_mods = """
    hist_fincl2 = "TLAI", "NPP", "GPP", "AR", "ER", "NBP", "QVEGT", "CPHASE", "TWS", "QRUNOFF", "H2OSOI"
    hist_nhtfrq = 0, -24
    hist_mfilt = 12,30
    """
    mosart_namelist_mods = """
rtmhist_fincl2 = "RIVER_DISCHARGE_OVER_LAND_LIQ", "TOTAL_DISCHARGE_TO_OCEAN_LIQ"
rtmhist_nhtfrq = 0, -24
rtmhist_mfilt = 12, 30
"""
    forcing_dir = "/glade/p/nsc/ncgd0042/ssfcst/forcing_files/"
    forcing_files = {"Precip": glob.glob(forcing_dir+"*Prec*.nc"),
                     "Solar": glob.glob(forcing_dir+"*Solar*.nc"),
                     "TPQW" : glob.glob(forcing_dir+"*TPQW*.nc")}

    with Case(caseroot, read_only=False) as case:
        case.create(casename, cesmroot, compset, grid, run_unsupported=True, answer="r")
        for key in xmlchanges:
            case.set_value(key, xmlchanges[key])
        case.case_setup()
        with open(os.path.join(caseroot,"user_nl_clm"),"a") as fd:
            fd.write(clm_namelist_mods)
        with open(os.path.join(caseroot,"user_nl_mosart"),"a") as fd:
            fd.write(mosart_namelist_mods)
        case.create_namelists()
        rundir = case.get_value("RUNDIR")
        for ftype in ["Solar", "Precip", "TPQW"]:
            forcing_files[ftype] = sorted(forcing_files[ftype], reverse=True)
            streamfile = os.path.join(rundir,"datm.streams.txt.CLMCRUNCEP."+ftype)
            newfile = os.path.join(caseroot, "user_"+os.path.basename(streamfile))

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
                    if "clmforc.cruncep" in line:
                        while forcing_files[ftype]:
                            newline = os.path.basename(forcing_files[ftype].pop())
                            fout.write(newline+"\n")
                        continue
                    fout.write(line)
                    if "<filePath>" in line:
                        skip_line=True
                        fout.write("/glade/p/nsc/ncgd0042/ssfcst/forcing_files/\n")
    with open("user_nl_datm","a") as fout:
        fout.write("taxmode = \'extend\',\'extend\',\'extend\',\'cycle\',\'cycle\'")
        run_cmd("ssh data-access cp /glade/campaign/cesm/development/cross-wg/S2S/land/rest/2018-12-31-00000/* {}".format(rundir))#        build.case_build(caseroot, case=case)

if __name__ == "__main__":
    _main_func(__doc__)
