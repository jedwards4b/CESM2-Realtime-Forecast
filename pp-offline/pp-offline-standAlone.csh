#!/bin/csh 
### set env variables
module load ncl nco

setenv CESM2_TOOLS_ROOT /glade/work/nanr/cesm_tags/CASE_tools/cesm2-smyle-PACEMAKER/
setenv DOUT_S_ROOT  /glade/scratch/yeager/SMYLE-PACEMAKER/archive/
setenv CASEROOT /glade/scratch/nanr/post-proc/

module use /glade/work/bdobbins/Software/Modules
module load cesm_postprocessing

#1981:  003-005	--
#1982:  001-004 -- 
#1984:  002-005 -- 
#1985:  001-005 --
#1986:  001-005
#1987:  001, 003-005
#1988:  001-005
#1989:  001-004


# ...
# case name counter
set smbr =  1
set embr =  4
set year =  1989

@ mb = $smbr
@ me = $embr

foreach mbr ( `seq $mb $me` )
if ($mbr < 10) then
        set CASE = b.e21.BSMYLE.f09_g17.TBI-ATL_10d50m-anom.${year}-02.00${mbr}
else
        set CASE = b.e21.BSMYLE.f09_g17.TBI-ATL_10d50m-anom.${year}-02.00${mbr}
endif

mkdir -p $CASEROOT/$CASE
cd $CASEROOT/$CASE

if ( ! -d "postprocess" ) then
   create_postprocess -caseroot=`pwd`
endif

cd postprocess

#cp $CESM2_TOOLS_ROOT/pp/env_timeseries.xml $CASEROOT/$CASE/postprocess

#pp_config --set TIMESERIES_OUTPUT_ROOTDIR=/glade/scratch/nanr/timeseries/$CASE/
pp_config --set TIMESERIES_OUTPUT_ROOTDIR=/glade/collections/cdg/timeseries-cmip6/$CASE
pp_config --set CASE=$CASE
pp_config --set DOUT_S_ROOT=$DOUT_S_ROOT/$CASE
pp_config --set ATM_GRID=0.9x1.25
pp_config --set LND_GRID=0.9x1.25
pp_config --set ICE_GRID=gx1v7
pp_config --set OCN_GRID=gx1v7
pp_config --set ICE_NX=320
pp_config --set ICE_NY=384


#pp_config --set TIMESERIES_OUTPUT_ROOTDIR=/glade/p/cesm/espwg/CESM2-SMYLE/timeseries/$CASE/
#qsub ./timeseries 

if ($mbr < 10) then
   set usembr = "00"${mbr}
else
   set usembr = "0"${mbr}
endif

echo $usembr

echo "Made it here"

# =========================
# change a few things
# =========================
#mv timeseries timeseries-OTB
cp $CESM2_TOOLS_ROOT/pp-offline/timeseries $CASEROOT/$CASE/postprocess

#qsub ./timeseries

end             # member loop

exit

