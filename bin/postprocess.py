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

import glob, shutil
from datetime import datetime, timedelta
from subprocess import Popen, PIPE
from standard_script_setup import *
from CIME.case             import Case
from CIME.utils            import run_cmd
from argparse              import RawTextHelpFormatter
#from globus_utils          import *

def str2bool(v):
    if isinstance(v, bool):
        return v
    if v.lower() in ('yes', 'true', 't', 'y', '1'):
        return True
    elif v.lower() in ('no', 'false', 'f', 'n', '0'):
        return False
    else:
        raise argparse.ArgumentTypeError('Boolean value expected.')

def parse_command_line(args, description):
    parser = argparse.ArgumentParser(description=description,
                                     formatter_class=RawTextHelpFormatter)
    CIME.utils.setup_standard_logging_options(parser)
    parser.add_argument("--date",
                        help="Specify a start Date")
    parser.add_argument("--member",
                        help="Specify an ensemble member")

    parser.add_argument("--sendtoftp",help="Send output to ftp server", default=False,
                        const=True, nargs='?', type=str2bool)

    parser.add_argument("--sendtoglobus",help="Send output to globus datashare directory", default=True,
                        const=True, nargs='?', type=str2bool)

    args = CIME.utils.parse_args_and_handle_standard_logging_options(args, parser)
    cdate = os.environ.get("CYLC_TASK_CYCLE_POINT")

    if args.member:
        member = int(args.member)
        os.environ["CYLC_TASK_PARAM_member"] = "{0:02d}".format(member)
    else:
        member = int(os.getenv("CYLC_TASK_PARAM_member"))

    if args.date:
        try:
            date = datetime.strptime(args.date, '%Y-%m-%d')
        except ValueError as verr:
            raise ValueError("Incorrect data format, should be YYYY-MM-DD or YYYY-MM") from verr
        os.environ["CYLC_TASK_CYCLE_POINT"] = args.date
    elif cdate:
        date = datetime.strptime(cdate, '%Y-%m-%d')
    else:
        date = datetime.today() - timedelta(days=1)

    return date.strftime("%Y-%m-%d"), member, args.sendtoftp, args.sendtoglobus

def run_ncl_scripts():
    scripts = ["pp_priority2.ncl","pp_priority1.ncl","pp_priority3.ncl","pp_h1vertical.ncl"]

    outfiles = []
    processes = []
    for script in scripts:
        processes.append(Popen("ncl "+script,cwd=os.path.join(os.getenv("FCST_HOME"),"bin"), stdout=PIPE, shell=True))
    errored = []

    while processes:
        p = processes.pop()
        result = p.communicate()[0].decode("utf-8")
        stat = p.wait()
        if stat != 0:
            print ("ERROR in ncl stat is {}".format(stat))
            errored.append(p)
        else:
            if '/p1/' in result or '/p2/' in result or '/p3/' in result:
                for line in result.splitlines():
                    if "Completed file:" in line:
                        print ("{}".format(line))
                        outfiles.append(line[line.find(os.sep):])

    return outfiles

def _main_func(description):
    date, member, sendtoftp, sendtoglobus = parse_command_line(sys.argv, description)

    basemonth = date[5:7]
    baseroot = os.getenv("FCST_WORK")
    basecasename = os.getenv("CESM_WORKFLOW")
    ftproot = " jedwards@thorodin.cgd.ucar.edu:/ftp/pub/jedwards/" + basecasename

    if member < 0:
        firstmember = 0
        lastmember = 20
    else:
        firstmember = member
        lastmember = member
    print("Running for members {} to {}".format(firstmember, lastmember))
    for curmem in range(firstmember, lastmember+1):
        print("Running postprocessing for member {} on date {}".format(curmem, date))
        os.environ["CYLC_TASK_PARAM_member"] = "{0:02d}".format(curmem)
        caseroot = os.path.join(baseroot,basecasename+"_"+date+".{0:02d}".format(curmem))

        with Case(caseroot, read_only=True) as case:
            dout_s_root = case.get_value("DOUT_S_ROOT")
            if not dout_s_root:
                print("Could not find DOUT_S_ROOT in case "+caseroot)
                sys.exit(-2)
            dout_s_root = dout_s_root[:-13] + date + ".{0:02d}".format(curmem)
            os.environ["DOUT_S_ROOT"] = dout_s_root
        #print("HERE rundir {} dout_s_root {}".format(rundir,dout_s_root))
        outfiles = run_ncl_scripts()
        # Copy data to ftp site
        if sendtoftp:
            for _file in outfiles:
                # path for realtime
                rsynccmd = "rsync -azvh --rsync-path=\"cd /project/webshare/projects/S2S/ && mkdir -p /project/webshare/projects/S2S/"+basecasename+"/realtime && rsync\" {} {}/realtime/{}".format(_file, ftproot,os.path.basename(_file))
                print("copying file {} to ftp server location {}".format(_file,ftproot+"/realtime/"))
                run_cmd(rsynccmd,verbose=True)
#        if sendtoglobus:
#            for _file in outfiles:
#                if "p1" in _file:
#                    newfile = _file.replace("scratch","p/datashare")
#                    if not os.path.isdir(os.path.dirname(newfile)):
#                        os.makedirs(os.path.dirname(newfile))
#                    shutil.copy2(_file, _file.replace("scratch","p/datashare"))



        # Clean up
#        if os.path.isdir(rundir):
#            for _file in glob.iglob(os.path.join(rundir,"*"+date+"*")):
#                os.unlink(_file)

            #    for _dir in ("cpl","esp", "glc", "wav", "rest"):
            #        if os.path.isdir(os.path.join(dout_s_root,_dir)):
            #            shutil.rmtree(os.path.join(dout_s_root,_dir))
        atmhistpath = os.path.join(dout_s_root,"atm","hist")
        icehistpath = os.path.join(dout_s_root,"ice","hist")
        ocnhistpath = os.path.join(dout_s_root,"ocn","hist")
        lndhistpath = os.path.join(dout_s_root,"lnd","hist")
        #    for histfile in os.listdir(atmhistpath):
        #        if "h1" in histfile or "h4" in histfile:
        #            os.unlink(os.path.join(atmhistpath,histfile))
        #Concatinate cice history into a single file

        fnameout = basecasename + basemonth+"."+date+".{0:02d}".format(curmem)+".cice.hd.nc"
        outroot = os.path.join(os.getenv("SCRATCH"),basecasename)
        outdir = os.path.join(outroot,"ice")

        print("ICE PATH")
        print(outdir)
        print("Combining cice files into {} in {}".format(fnameout,icehistpath))

        if glob.iglob(os.path.join(icehistpath,"*.cice.h.*.nc")):
            run_cmd("ncrcat -4 -L 1 *.cice.h.*.nc -O {}".format(os.path.join(outdir,fnameout)),from_dir=icehistpath,verbose=True)
            for _file in glob.iglob(os.path.join(icehistpath,"*ice.h.*.nc")):
                os.unlink(_file)
        fnameout = fnameout.replace("cice.hd.nc","pop.h.nday1.nc")

        print("Copying ocn daily files into {}".format(fnameout))
        
        outdir = os.path.join(outroot,"ocn")

        for _file in glob.iglob(os.path.join(ocnhistpath,"*pop.h.*.nc")):
            newfname = os.path.basename(_file).replace("cesm2cam6.","cesm2cam6.")
            run_cmd("nccopy -4 -d 1 {}  {}".format(_file, os.path.join(outdir,newfname)), verbose=True, from_dir=ocnhistpath)


            
        outdir = os.path.join(outroot,"3hourly")

        for _file in glob.iglob(os.path.join(atmhistpath,"*cam.h4*.nc")):
            print("Copying {} file into {}".format(_file,outdir))
            newfname = os.path.basename(_file).replace("cesm2cam6.","cesm2cam6.")

            run_cmd("nccopy -4 -d 1 -VTS,PS,PSL,QBOT,TMQ,UBOT,VBOT,lat,lon,date,time_bnds,time,gw,ndcur,nscur,nsteph {}  {}".format(_file, os.path.join(outdir,newfname)), verbose=True, from_dir=atmhistpath)

        outdir = os.path.join(outroot,"6hourly")

        for _file in glob.iglob(os.path.join(atmhistpath,"*cam.h3*.nc")):
            print("Copying {} file into {}".format(_file,outdir))
            newfname = os.path.basename(_file).replace("cesm2cam6.","cesm2cam6.")

            run_cmd("nccopy -4 -d 1 -VU850,V850,TMQ,PRECT,uIVT,vIVT,IVT,PS,PSL,UBOT,VBOT,Z200,Z500,U10,lat,lon,date,time_bnds,time,gw,ndcur,nscur,nsteph {}  {}".format(_file, os.path.join(outdir,newfname)), verbose=True, from_dir=atmhistpath)

        outdir = os.path.join(outroot,"daily")

        for _file in glob.iglob(os.path.join(atmhistpath,"*cam.h2*.nc")):
            print("Copying {} file into {}".format(_file, outdir))
            newfname = os.path.basename(_file).replace("cesm2cam6.","cesm2cam6.")
            run_cmd("nccopy -4 -d 1 -VFLNT,FSNT,FLDS,FSDS,PRECC,PRECL,QREFHT,RHREFHT,RH600,PSL,PS,SNOWHICE,SNOWHLND,CLDTOT,TMQ,SST,LANDFRAC,OCNFRAC,UVzm,VTHzm,UWzm,WTHzm,TROP_P,TROP_T,THzm,Uzm,Vzm,Wzm,PHIS,WSPDSRFMX,WSPDSRFAV,QFLX,U10,TGCLDIWP,TGCLDLWP,lev,ilev,lat,lon,date,time_bnds,time,gw,ndcur,nscur,nsteph {} {}".format(_file, os.path.join(outdir,newfname)), verbose=True, from_dir=atmhistpath)
#        for _file in glob.iglob(os.path.join(atmhistpath,"*cam.h1*.nc")):
#            print("Copying {} file into {}".format(_file, outdir))
#            run_cmd("nccopy -4 -d 1 -VU10,TGCLDIWP,TGCLDLWP,lev,ilev,lat,lon,date,time_bnds,time,gw,ndcur,nscur,nsteph {} {}".format(_file, os.path.join(outdir,os.path.basename(_file))), verbose=True, from_dir=atmhistpath)

        outdir = os.path.join(outroot,"lnd")

        print("LND OUTDIR:")
        print(outdir)

        for _file in glob.iglob(os.path.join(lndhistpath,"*clm2.h0*.nc")):
            print("Copying {} file into {}".format(_file, outdir))
            newfname = os.path.basename(_file).replace("cesm2cam6.","cesm2cam6.")
            run_cmd("nccopy -4 -d 1 {} {}".format(_file, os.path.join(outdir,newfname)), verbose=True, from_dir=lndhistpath)


if __name__ == "__main__":
    _main_func(__doc__)
