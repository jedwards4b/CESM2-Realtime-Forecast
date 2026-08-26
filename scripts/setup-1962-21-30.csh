#!/bin/csh -fx
### set env variables
module load ncl nco

setenv CESM2_TOOLS_ROOT /glade/work/nanr/cesm_tags/CASE_tools/cesm2-smyle/
setenv CESMROOT /glade/work/nanr/cesm_tags/cesm2.1.4-SMYLE

set COMPSET = BSMYLE
set MACHINE = cheyenne
set RESOLN = f09_g17
set RESUBMIT = 0
set STOP_N=24
set STOP_OPTION=nmonths
set PROJECT=P93300313

#setenv BASEROOT /glade/work/nanr/CESM2-SMYLE/cases/
#setenv BASEROOT /glade/p/cesm/espwg/CESM2-SMYLE/cases/
setenv BASEROOT /glade/campaign/cesm/development/espwg/SMYLE-CASES/CESM2-SMYLE/cases/

set syr = 1962
set eyr = 1962

@ ib = $syr
@ ie = $eyr

foreach year ( `seq $ib $ie` )
#foreach mon ( 02 05 08 11 )
foreach mon ( 11 )


set REFCASE  = b.e21.SMYLE_IC.f09_g17.${year}-${mon}.01
set REFPERT  = b.e21.SMYLE_IC.pert.f09_g17
set REFROOT  = /glade/campaign/cesm/development/espwg/SMYLE/inputdata/cesm2_init/${REFCASE}/${year}-${mon}-01/
set PERTROOT = /glade/campaign/cesm/development/espwg/SMYLE/inputdata/cesm2_init/${REFCASE}/
set EXEROOT  = /glade/scratch/nanr/SMYLE/exerootdir/bld/

#setenv CASEROOT /glade/p/cesm/espwg/CESM2-SMYLE/cases/$CASE
setenv INITDIR  /glade/scratch/nanr/SMYLE/
setenv DPDIR    /glade/scratch/nanr/SMYLE/
setenv BASECASE b.e21.BSMYLE.f09_g17.${year}-${mon}.001

# case name counter
set smbr =  21
set embr =  30
set embr =  22

@ mb = $smbr
@ me = $embr

foreach mbr ( `seq $mb $me` )


# Use restarts created from case 001 for all ensemble members;  pertlim will differentiate runs.
if ($mbr < 10) then
        set CASE = b.e21.BSMYLE.f09_g17.${year}-${mon}.00${mbr}
else
        set CASE = b.e21.BSMYLE.f09_g17.${year}-${mon}.0${mbr}
        set CLONEROOT = /glade/p/cesm/espwg/CESM2-SMYLE/cases/
        set CLONECASE = b.e21.BSMYLE.f09_g17.1999-11.021
endif

 cd $CESMROOT/cime/scripts
# ./create_clone --case $BASEROOT$CASE --clone $BASEROOT$CLONECASE --res $RESOLN  --compset $COMPSET 
 ./create_clone --case $BASEROOT$CASE --clone $CLONEROOT$CLONECASE 
# ./create_clone --case /glade/scratch/nanr/${CASE}-test4 --clone $CLONEROOT$CLONECASE 

echo 'Year   = ' $year
echo 'Member = ' $mbr
echo 'Case   = ' $CASE


  setenv RUNDIR   /$DPDIR/$BASECASE/run.0${mbr}
  setenv CASEROOT  $BASEROOT$CASE
  #setenv CASEROOT  /glade/scratch/nanr/${CASE}-test4
  cd $CASEROOT
  ./xmlchange CIME_OUTPUT_ROOT=/glade/scratch/$USER/SMYLE
  #./xmlchange OCN_TRACER_MODULES="iage cfc ecosys"

  # turn off cylc
  ./xmlchange EXTERNAL_WORKFLOW=FALSE

  ./xmlchange RUNDIR=$RUNDIR
  ./xmlchange RUN_REFCASE=$REFCASE
  ./xmlchange RUN_REFDIR=/glade/p/cesm/espwg/CESM2-SMYLE/inputdata/cesm2_init/b.e21.SMYLE_IC.f09_g17.${year}-${mon}.01/1962-11-01
  ./xmlchange RUN_REFDATE=${year}-${mon}-01
  ./xmlchange RUN_STARTDATE=${year}-${mon}-01
  ./xmlchange GET_REFCASE=FALSE
  ./xmlchange PROJECT=$PROJECT
  #./xmlchange JOB_QUEUE=economy --subgroup case.run
  #./xmlchange --append CAM_CONFIG_OPTS=-cosp

  #./xmlchange NTASKS_ICE=36
  #./xmlchange NTASKS_LND=504
  #./xmlchange ROOTPE_ICE=504
  ./xmlchange DOUT_S_ROOT=/glade/scratch/nanr/SMYLE/archive/$CASE

  ./case.setup --reset
  ./xmlchange BUILD_COMPLETE=TRUE


  #mv user_nl_cam user_nl_cam.`date +%m%d-%H%M`
  #mv user_nl_clm user_nl_clm.`date +%m%d-%H%M`
  #mv user_nl_cpl user_nl_cpl.`date +%m%d-%H%M`
  #mv user_nl_cice user_nl_cice.`date +%m%d-%H%M`
  #mv SourceMods/ SourceMods/.`date +%m%d-%H%M`
  #cp $CESM2_TOOLS_ROOT/user_mods/cesm2smyle.base/SourceMods/src.pop/* $CASEROOT/SourceMods/src.pop/
  #cp $CESM2_TOOLS_ROOT/user_mods/cesm2smyle.base/SourceMods/src.cam/* $CASEROOT/SourceMods/src.cam/
  #cp $CESM2_TOOLS_ROOT/user_mods/cesm2smyle.base/SourceMods/src.clm/* $CASEROOT/SourceMods/src.clm/

  #cp $CESM2_TOOLS_ROOT/user_mods/cesm2smyle.base/user_nl_* $CASEROOT/

  #./xmlchange STOP_N=$STOP_N
  #./xmlchange STOP_OPTION=$STOP_OPTION
  #./xmlchange RESUBMIT=$RESUBMIT


#echo " Copy Restarts -------------"
#if (! -d $RUNDIR) then
        #echo 'mkdir ' $RUNDIR
        #mkdir -p $RUNDIR
#endif

   #cp    ${REFROOT}/rpointer* $RUNDIR/
   #ln -s ${REFROOT}/b.e21*    $RUNDIR/

#echo " End restarts copy -----------"

#echo " Add cam.i.perturbation Restarts -------------"
   #set doThis = 1
   #if ($doThis == 1) then
   #if ($mbr > 1) then
   	#set ifile = ${REFCASE}.cam.i.${year}-${mon}-01-00000.nc 
   	#set ofile = ${REFCASE}.cam.i.${year}-${mon}-01-00000-original.nc
   	#mv $RUNDIR/$ifile $RUNDIR/$ofile
   	#if ($mbr < 10) then
        	#ln -s ${PERTROOT}/pert.0${mbr}/${REFPERT}.cam.i* $RUNDIR/$ifile
   	        #echo ${PERTROOT}/pert.0${mbr}/${REFPERT}.cam.i* $RUNDIR/$ifile
   	#else
        	#ln -s ${PERTROOT}/pert.${mbr}/${REFPERT}.cam.i* $RUNDIR/$ifile
   	        #echo ${PERTROOT}/pert.${mbr}/${REFPERT}.cam.i* $RUNDIR/$ifile
   	#endif
   #endif
   #endif
#
##echo $DPDIR/$CASE/run/
#echo $RUNDIR

   #./case.submit

end             # member loop

exit

