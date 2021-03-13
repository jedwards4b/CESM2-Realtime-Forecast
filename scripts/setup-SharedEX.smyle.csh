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
set RESUBMIT = 0
set STOP_N=24
set STOP_OPTION=nmonths
set PROJECT=NCGD0047

setenv BASEROOT /glade/work/nanr/CESM2-SMYLE/cases/

set syr = 1963
set eyr = 1963
set syr = 1964
set eyr = 1964
set syr = 1965
set eyr = 1965
set syr = 1966
set eyr = 1966
set syr = 1967
set eyr = 1967
# ...
set syr = 1994
set eyr = 1994

@ ib = $syr
@ ie = $eyr

foreach year ( `seq $ib $ie` )
#foreach mon ( 02 05 08 11 )
foreach mon ( 11 )


set REFCASE  = b.e21.SMYLE_IC.f09_g17.${year}-${mon}.01
set REFPERT  = b.e21.SMYLE_IC.pert.f09_g17
set REFROOT  = /glade/scratch/nanr/SMYLE/inputdata/cesm2_init/${REFCASE}/${year}-${mon}-01/
set PERTROOT = /glade/scratch/nanr/SMYLE/inputdata/cesm2_init/${REFCASE}/
set EXEROOT  = /glade/scratch/nanr/SMYLE/b.e21.BSMYLE.f09_g17.1978-11.001/bld/
set mastercase = b.e21.BSMYLE.f09_g17.1980-11.001

#setenv CASEROOT /glade/p/cesm/espwg/CESM2-SMYLE/cases/$CASE
setenv INITDIR  /glade/scratch/nanr/SMYLE/
setenv DPDIR    /glade/scratch/nanr/SMYLE/
setenv SHORTCASE b.e21.BSMYLE.f09_g17.${year}-${mon}

cd ~nanr/CESM-WF/
./create_cylc_cesm2-smyle-ensemble-cmip6 --case $BASEROOT$SHORTCASE --res $RESOLN  --compset $COMPSET --project $PROJECT 

# case name counter
set smbr =   1
set embr =  10

@ mb = $smbr
@ me = $embr

foreach mbr ( `seq $mb $me` )


# Use restarts created from case 001 for all ensemble members;  pertlim will differentiate runs.
if ($mbr < 10) then
        set CASE = b.e21.BSMYLE.f09_g17.${year}-${mon}.00${mbr}
else
        set CASE = b.e21.BSMYLE.f09_g17.${year}-${mon}.0${mbr}
endif

# cd $CESMROOT/cime/scripts
# ./create_newcase --case $BASEROOT$CASE --res $RESOLN  --compset $COMPSET 

echo 'Year   = ' $year
echo 'Member = ' $mbr
echo 'Case   = ' $CASE


  setenv RUNDIR   /$DPDIR/$CASE/run
  setenv CASEROOT  $BASEROOT$CASE
  cd $CASEROOT
  #if ($mbr == $smbr) then
    #set mastercase = $CASE
  #endif
  ./xmlchange CIME_OUTPUT_ROOT=/glade/scratch/$USER/SMYLE 
  ./xmlchange OCN_TRACER_MODULES="iage cfc ecosys"

  ./xmlchange RUN_REFCASE=$REFCASE
  ./xmlchange RUN_REFDATE=${year}-${mon}-01
  ./xmlchange RUN_STARTDATE=${year}-${mon}-01
  ./xmlchange GET_REFCASE=FALSE
  ./xmlchange PROJECT=NCGD0047
  ./xmlchange JOB_QUEUE=economy --subgroup case.run
  ./xmlchange --append CAM_CONFIG_OPTS=-cosp

  ./xmlchange NTASKS_ICE=36
  ./xmlchange NTASKS_LND=504
  ./xmlchange ROOTPE_ICE=504
# ./xmlchange DOUT_S_ROOT=$ENV{SCRATCH}/SMYLE/archive/$CASE

  ./case.setup


  mv user_nl_cam user_nl_cam.`date +%m%d-%H%M`
  mv user_nl_clm user_nl_clm.`date +%m%d-%H%M`
  mv user_nl_cpl user_nl_cpl.`date +%m%d-%H%M`
  mv user_nl_cice user_nl_cice.`date +%m%d-%H%M`
  #mv SourceMods/ SourceMods/.`date +%m%d-%H%M`
  cp $CESM2_TOOLS_ROOT/SourceMods/src.pop/* $CASEROOT/SourceMods/src.pop/
  cp $CESM2_TOOLS_ROOT/SourceMods/src.cam/* $CASEROOT/SourceMods/src.cam/
  cp $CESM2_TOOLS_ROOT/SourceMods/src.clm/* $CASEROOT/SourceMods/src.clm/

  cp $CESM2_TOOLS_ROOT/user_nl_files/user_nl_cam $CASEROOT/
  cp $CESM2_TOOLS_ROOT/user_nl_files/user_nl_clm $CASEROOT/
  cp $CESM2_TOOLS_ROOT/user_nl_files/user_nl_cpl $CASEROOT/
  cp $CESM2_TOOLS_ROOT/user_nl_files/user_nl_cice $CASEROOT/


  ./xmlchange STOP_N=$STOP_N
  ./xmlchange STOP_OPTION=$STOP_OPTION
  ./xmlchange RESUBMIT=$RESUBMIT


echo " Copy Restarts -------------"
if (! -d $RUNDIR) then
        echo 'mkdir ' $RUNDIR
        mkdir -p $RUNDIR
endif

   cp    ${REFROOT}/rpointer* $RUNDIR/
   ln -s ${REFROOT}/b.e21*    $RUNDIR/

echo " End restarts copy -----------"

echo " Add cam.i.perturbation Restarts -------------"
   set doThis = 1
   if ($doThis == 1) then
   if ($mbr > 1) then
   	set ifile = ${REFCASE}.cam.i.${year}-${mon}-01-00000.nc 
   	set ofile = ${REFCASE}.cam.i.${year}-${mon}-01-00000-original.nc
   	mv $RUNDIR/$ifile $RUNDIR/$ofile
   	if ($mbr < 10) then
        	ln -s ${PERTROOT}/pert.0${mbr}/${REFPERT}.cam.i* $RUNDIR/$ifile
   	        echo ${PERTROOT}/pert.0${mbr}/${REFPERT}.cam.i* $RUNDIR/$ifile
   	else
        	ln -s ${PERTROOT}/pert.${mbr}/${REFPERT}.cam.i* $RUNDIR/$ifile
   	        echo ${PERTROOT}/pert.${mbr}/${REFPERT}.cam.i* $RUNDIR/$ifile
   	endif
   endif
   endif

#echo $DPDIR/$CASE/run/
#echo $RUNDIR

# ./preview_namelists
  if ($mbr == $smbr) then
 	./case.setup --reset; ./case.setup
 	#./case.setup --reset; ./case.setup; qcmd -- ./case.build >& bld.`date +%m%d-%H%M`
	./xmlchange EXEROOT=$DPDIR/$mastercase/bld/
	./xmlchange BUILD_COMPLETE=TRUE
  else
 	./case.setup --reset; ./case.setup
	./xmlchange EXEROOT=$DPDIR/$mastercase/bld/
	./xmlchange BUILD_COMPLETE=TRUE
  endif

# ====== fix env_postprocess.xml
  cd postprocess
  ./pp_config --set DOUT_S_ROOT=$DPDIR/archive/$CASE

end             # member loop

exit

