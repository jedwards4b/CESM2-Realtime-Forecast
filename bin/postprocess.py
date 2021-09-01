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

import datetime, shutil, glob
from subprocess import Popen, PIPE
from standard_script_setup import *
from CIME.case             import Case
from CIME.utils            import run_cmd
from argparse              import RawTextHelpFormatter
from globus_utils          import *

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

    parser.add_argument("--sendtoftp",help="Send output to ftp server", default=False, const=True, nargs='?', type=str2bool)

    parser.add_argument("--sendtoglobus",help="Send output to globus datashare", default=True, const=True, nargs='?', type=str2bool)

    args = CIME.utils.parse_args_and_handle_standard_logging_options(args, parser)
    cdate = os.environ.get("CYLC_TASK_CYCLE_POINT")

    if args.member:
        member = int(args.member)
        os.environ["CYLC_TASK_PARAM_member"] = "{0:02d}".format(member)
    else:
        member = int(os.getenv("CYLC_TASK_PARAM_member"))

    if args.date:
        try:
            date = datetime.datetime.strptime(args.date, '%Y-%m-%d')
        except ValueError:
            raise ValueError("Incorrect data format, should be YYYY-MM-DD or YYYY-MM")
        os.environ["CYLC_TASK_CYCLE_POINT"] = args.date
    elif cdate:
        date = datetime.datetime.strptime(cdate, '%Y-%m-%d')
    else:
        date = datetime.date.today()
        date = date.replace(day=date.day-1)

    return date.strftime("%Y-%m-%d"), member, args.sendtoftp, args.sendtoglobus

def run_ncl_scripts():
    scripts = ["pp_priority2.ncl","pp_priority1.ncl","pp_priority3.ncl","pp_h1vertical.ncl"]
    scripts.append("pp_h4vertical.ncl")

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
            #if '/p1/' in result or '/p2/' in result or '/p3/' in result:
            if True:
                for line in result.splitlines():
                    if "Completed file:" in line:
                        print ("{}".format(line))
                        outfiles.append(line[line.find(os.sep):])

    return outfiles


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
    date, member, sendtoftp, sendtoglobus = parse_command_line(sys.argv, description)
    basecasename = "70Lwaccm6"
    basemonth = date[5:7]
    baseroot = os.getenv("WORK")
    ftproot = " jedwards@thorodin.cgd.ucar.edu:/ftp/pub/jedwards/70Lwaccm6"
    

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
        caseroot = os.path.join(baseroot,basecasename+"."+basemonth+".{0:02d}".format(curmem))

        with Case(caseroot, read_only=True) as case:
            rundir = case.get_value("RUNDIR")
            dout_s_root = case.get_value("DOUT_S_ROOT")
            print("HERE caseroot {} dout_s_root {} date {} curmem {}".format(caseroot, dout_s_root,date,curmem))
            dout_s_root = dout_s_root[:-13] + date + ".{0:02d}".format(curmem)
            os.environ["DOUT_S_ROOT"] = dout_s_root
        outfiles = run_ncl_scripts()
        # Copy data to ftp site
        if sendtoftp:
            for _file in outfiles:
                fsplit = _file.find(basecasename + os.sep)+10
                fpath = os.path.dirname(_file[fsplit-1:])
                # path for hindcasts
                # rsynccmd = "rsync -azvh --rsync-path=\"mkdir -p /ftp/pub/jedwards/70Lwaccm6/"+fpath+" && rsync\" "+_file+" "+ftproot+fpath
                # path for realtime
                rsynccmd = "rsync -azvh --rsync-path=\"mkdir -p /ftp/pub/jedwards/70Lwaccm6/realtime && rsync\" {} {}/realtime/{}".format(_file, ftproot,os.path.basename(_file))
                print("copying file {} to ftp server location {}".format(_file,ftproot+"/realtime/"))
                run_cmd(rsynccmd,verbose=True)
        if sendtoglobus:
            for _file in outfiles:
                fname = os.path.basename(_file)
                if "p1" in _file or \
                   "OMEGA_7" in fname or \
                   "U_7" in fname or \
                   "V_7" in fname or \
                   "T_7" in fname or \
                   "Z3_7" in fname or \
                   "RELHUM_7" in fname:
                    newfile = _file.replace("scratch","p/datashare")
                    if not os.path.isdir(os.path.dirname(newfile)):
                        os.makedirs(os.path.dirname(newfile))
                    print("Copy {} to datashare".format(fname))
                    shutil.copy2(_file, newfile)


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

        fnameout = basecasename+"v2."+basemonth+"."+date+".{0:02d}".format(curmem)+".cice.hd.nc"
        if basecasename == "cesm2cam6":
            outdir = "/glade/scratch/ssfcst/cesm2cam6v2/ice"
        else:
            outdir = "/glade/scratch/ssfcst/{}/ice".format(basecasename)

        print("ICE PATH")
        print(outdir)
        print("Combining cice files into {} in {}".format(fnameout,icehistpath))
        if not os.path.isdir(icehistpath):
            os.makedirs(icehistpath)
        if glob.iglob(os.path.join(icehistpath,"*.cice.h.*.nc")):
            run_cmd("ncrcat -4 -L 1 *.cice.h.*.nc -O {}".format(os.path.join(outdir,fnameout)),from_dir=icehistpath,verbose=True)
            for _file in glob.iglob(os.path.join(icehistpath,"*ice.h.*.nc")):
                os.unlink(_file)
        fnameout = fnameout.replace("cice.hd.nc","pop.h.nday1.nc")

        print("Copying ocn daily files into {}".format(fnameout))
        if basecasename == "cesm2cam6":
            outdir = "/glade/scratch/ssfcst/cesm2cam6v2/ocn"
        else:
            outdir = "/glade/scratch/ssfcst/{}/ocn".format(basecasename)

        for _file in glob.iglob(os.path.join(ocnhistpath,"*pop.h.[no]*.nc")):
            newfname = os.path.basename(_file).replace("cesm2cam6.","cesm2cam6v2.")
            run_cmd("nccopy -4 -d 1 {}  {}".format(_file, os.path.join(outdir,newfname)), verbose=True, from_dir=ocnhistpath)

        #    send_data_to_campaignstore(dout_s_root+os.sep )
        if basecasename == "cesm2cam6":
            outdir = "/glade/scratch/ssfcst/cesm2cam6v2/6hourly"
        else:
            outdir = "/glade/scratch/ssfcst/{}/6hourly".format(basecasename)

        for _file in glob.iglob(os.path.join(atmhistpath,"*cam.h3*.nc")):
            print("Copying {} file into {}".format(_file,outdir))
            if basecasename == "cesm2cam6":
                newfname = os.path.basename(_file).replace("cesm2cam6.","cesm2cam6v2.")
            else:
                newfname = os.path.basename(_file)

            run_cmd("nccopy -4 -d 1 -VPS,PSL,UBOT,VBOT,Z200,Z500,U10,lat,lon,date,time_bnds,time,gw,ndcur,nscur,nsteph {}  {}".format(_file, os.path.join(outdir,newfname)), verbose=True, from_dir=atmhistpath)

#        outdir = "/glade/scratch/ssfcst/cesm2cam6v2/daily"

        if basecasename == "cesm2cam6":
            outdir = "/glade/scratch/ssfcst/cesm2cam6v2/daily"
        else:
            outdir = "/glade/scratch/ssfcst/{}/daily".format(basecasename)

        for _file in glob.iglob(os.path.join(atmhistpath,"*cam.h2*.nc")):
            print("Copying {} file into {}".format(_file, outdir))
            newfname = os.path.basename(_file).replace("cesm2cam6.","cesm2cam6v2.")
            run_cmd("nccopy -4 -d 1 -VFLNT,FSNT,FLDS,FSDS,PRECC,PRECL,QREFHT,RHREFHT,RH600,PSL,PS,SNOWHICE,SNOWHLND,CLDTOT,TMQ,SST,LANDFRAC,OCNFRAC,UVzm,VTHzm,UWzm,WTHzm,TROP_P,TROP_T,THzm,Uzm,Vzm,Wzm,PHIS,WSPDSRFMX,WSPDSRFAV,QFLX,U10,TGCLDIWP,TGCLDLWP,lev,ilev,lat,lon,date,time_bnds,time,gw,ndcur,nscur,nsteph {} {}".format(_file, os.path.join(outdir,newfname)), verbose=True, from_dir=atmhistpath)
#        for _file in glob.iglob(os.path.join(atmhistpath,"*cam.h1*.nc")):
#            print("Copying {} file into {}".format(_file, outdir))
#            run_cmd("nccopy -4 -d 1 -VU10,TGCLDIWP,TGCLDLWP,lev,ilev,lat,lon,date,time_bnds,time,gw,ndcur,nscur,nsteph {} {}".format(_file, os.path.join(outdir,os.path.basename(_file))), verbose=True, from_dir=atmhistpath)

        outdir="/glade/scratch/ssfcst/{}/lnd".format(basecasename)

        print("LND OUTDIR:")
        print(outdir)

        for _file in glob.iglob(os.path.join(lndhistpath,"*clm2.h0*.nc")):
           print("Copying {} file into {}".format(_file, outdir))
           newfname = os.path.basename(_file).replace("cesm2cam6.","cesm2cam6v2.")
           run_cmd("nccopy -4 -d 1 {} {}".format(_file, os.path.join(outdir,newfname)), verbose=True, from_dir=lndhistpath)


if __name__ == "__main__":
    _main_func(__doc__)
