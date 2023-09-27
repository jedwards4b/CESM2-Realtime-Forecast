#!/bin/csh 
### set env variables
module load ncl nco

setenv CESM2_TOOLS_ROOT /glade/work/nanr/cesm_tags/CASE_tools/cesm2-smyle-PACEMAKER/pp-offline/sashaScripts/
setenv DOUT_S_ROOT  /glade/scratch/sglanvil/SMYLE-PACEMAKER/archive/
setenv CASEROOT /glade/scratch/$USER/post-proc/

module use /glade/work/bdobbins/Software/Modules
module load cesm_postprocessing

# ...

set COMPSET=BSMYLE
set YEAR =  1990
set YEAR =  1990
set smbr =  2
set embr =  2

@ mb = $smbr
@ me = $embr

foreach mbr ( `seq $mb $me` )
if ($mbr < 10) then
        set CASE = b.e21.${COMPSET}.f09_g17.TBI-PAC_15d50m-anom.${YEAR}-02.00${mbr}
else
        set CASE = b.e21.${COMPSET}.f09_g17.TBI-PAC_15d50m-anom.${YEAR}-02.0${mbr}
endif

mkdir -p $CASEROOT/$CASE
cd $CASEROOT/$CASE

if ( ! -d "postprocess" ) then
   create_postprocess -caseroot=`pwd`
endif

cd postprocess

#pp_config --set TIMESERIES_OUTPUT_ROOTDIR=/glade/scratch/nanr/timeseries/$CASE/
pp_config --set TIMESERIES_OUTPUT_ROOTDIR=/glade/scratch/$USER/timeseries/$CASE
pp_config --set CASE=$CASE
pp_config --set DOUT_S_ROOT=$DOUT_S_ROOT/$CASE
pp_config --set ATM_GRID=0.9x1.25
pp_config --set LND_GRID=0.9x1.25
pp_config --set ICE_GRID=gx1v7
pp_config --set OCN_GRID=gx1v7
pp_config --set ICE_NX=320
pp_config --set ICE_NY=384


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
mv timeseries timeseries-OTB
cp $CESM2_TOOLS_ROOT/timeseries $CASEROOT/$CASE/postprocess

end             # member loop

exit

