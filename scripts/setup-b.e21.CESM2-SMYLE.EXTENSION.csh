#!/bin/csh -fx
### set env variables
module load ncl nco

setenv CESM2_TOOLS_ROOT /glade/work/nanr/cesm_tags/CASE_tools/cesm2-smyle/
setenv CESMROOT /glade/work/nanr/cesm_tags/cesm2.1.4-SMYLE

setenv POSTPROCESS_PATH /glade/u/home/mickelso/CESM_postprocessing_3/
setenv POSTPROCESS_PATH_GEYSER /glade/u/home/mickelso/CESM_postprocessing_3/

set COMPSET = BSMYLE
set MACHINE = cheyenne
set RESOLN = f09_g17
set RESUBMIT = 3
set STOP_N=24
set STOP_OPTION=nmonths
set PROJECT=NCGD0047

set syr = 2018
set eyr = 2018

@ ib = $syr
@ ie = $eyr

@ RESTYEAR = $syr + 2

echo $RESTYEAR

foreach year ( `seq $ib $ie` )
foreach mon ( 11 )


# case name counter
set smbr =  11
set embr =  20

@ mb = $smbr
@ me = $embr

foreach mbr ( `seq $mb $me` )


# Use restarts created from case 001 for all ensemble members;  pertlim will differentiate runs.
if ($mbr < 10) then
        set CASE     = b.e21.BSMYLE.f09_g17.${year}-${mon}.00${mbr}
else
        set CASE     = b.e21.BSMYLE.f09_g17.${year}-${mon}.0${mbr}
endif

set REFROOT  = /glade/scratch/nanr/SMYLE-X/archive/${CASE}/rest/${RESTYEAR}-${mon}-01-00000/

echo 'Year   = ' $year
echo 'Member = ' $mbr
echo 'Case   = ' $CASE


  setenv DPDIR    /glade/scratch/$USER/SMYLE-X/
  setenv RUNDIR   /$DPDIR/$CASE/run
  setenv CASEROOT /glade/p/cesm/espwg/CESM2-SMYLE-XTND/cases/$CASE
  # preserve the original case

  cd $CESMROOT/cime/scripts
  ./create_newcase --case $CASEROOT --res $RESOLN  --compset $COMPSET 

  cd $CASEROOT
  ./xmlchange CIME_OUTPUT_ROOT=/glade/scratch/$USER/SMYLE-X/
  ./xmlchange RUNDIR=/glade/scratch/$USER/SMYLE-X/$CASE/run/
  ./xmlchange RESUBMIT=$RESUBMIT
  ./xmlchange RUN_REFCASE=$CASE
  ./xmlchange RUN_REFDATE=${year}-${mon}-01
  ./xmlchange RUN_STARTDATE=${year}-${mon}-01
  ./xmlchange CONTINUE_RUN=TRUE
  ./xmlchange STOP_N=$STOP_N
  ./xmlchange STOP_OPTION=$STOP_OPTION
  ./xmlchange REST_N=$STOP_N
  ./xmlchange REST_OPTION=$STOP_OPTION
  ./xmlchange PROJECT=P06010014
  ./xmlchange --append CAM_CONFIG_OPTS=-cosp
  ./xmlchange OCN_TRACER_MODULES="iage cfc ecosys"
  ./xmlchange JOB_QUEUE=economy --subgroup case.run

# ./preview_namelists
  ./case.setup --reset 
  ./xmlchange EXEROOT=/glade/scratch/$USER/SMYLE-X/exerootdir/bld/
  ./xmlchange BUILD_COMPLETE=TRUE

echo " Copy Restarts -------------"
  if (! -d $RUNDIR) then
        echo 'mkdir ' $RUNDIR
        mkdir -p $RUNDIR
  endif

  cp  ${CESM2_TOOLS_ROOT}/user_mods/cesm2smyle.base/SourceMods/src.pop/* $CASEROOT/SourceMods/src.pop/
  cp  ${CESM2_TOOLS_ROOT}/user_mods/cesm2smyle.base/SourceMods/src.cam/* $CASEROOT/SourceMods/src.cam/
  cp  ${CESM2_TOOLS_ROOT}/user_mods/cesm2smyle.base/SourceMods/src.clm/* $CASEROOT/SourceMods/src.clm/
  cp  ${CESM2_TOOLS_ROOT}/user_mods/cesm2smyle.base/user_nl* $CASEROOT/

  cp    ${REFROOT}/rpointer* $RUNDIR/
  ln -s ${REFROOT}/b.e21*    $RUNDIR/

echo " End restarts copy -----------"

# ====== fix env_postprocess.xml
  #cd postprocess
  #./pp_config --set DOUT_S_ROOT=$DPDIR/archive/$CASE

end             # member loop

exit

