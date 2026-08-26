#!/bin/bash

useyear=2023
usemonth=11

curdir='/glade/work/nanr/cesm_tags/CASE_tools/cesm2-smyle/'
srcdir='/glade/work/nanr/cesm_tags/CASE_tools/cesm2-smyle/'
compset='BSMYLE'
usecompset='BSMYLE-TEST'
resoln='f09_g17'
tagdir='/glade/work/nanr/cesm_tags/cesm2.1.4-SMYLE/'
caseroot='/glade/campaign/cesm/development/espwg/SMYLE-CASES/CESM2-SMYLE/cases/'

main_case_root='b.e21.'$usecompset'.'$resoln'.'${useyear}'-'${usemonth}'.001'

for mbr in $(seq -f "%03g" 1 1)
do

echo "setting up member ${mbr}"

runname=b.e21.$usecompset.$resoln.$useyear-$usemonth.$mbr
casedir=$caseroot/$runname
rundir=/glade/derecho/scratch/nanr/SMYLE/${main_case_root}/run.${mbr}/

echo $rundir

cd $tagdir/cime/scripts

./create_newcase --case $casedir --res $resoln --compset $compset --run-unsupported
#./create_newcase --case $casedir --res $resoln --compset $compset 

cd $casedir

# ./xmlchange --append --file env_build.xml --id CAM_CONFIG_OPTS --val="-co2_cycle"
./xmlchange --append --file env_build.xml --id CAM_CONFIG_OPTS --val="-cosp "

./xmlchange OCN_CHL_TYPE=diagnostic
./xmlchange CLM_NAMELIST_OPTS=use_init_interp=.true.
./xmlchange CCSM_BGC=CO2A
./xmlchange DIN_LOC_ROOT_CLMFORC=/glade/p/cgd/tss/CTSM_datm_forcing_data

./xmlchange JOB_WALLCLOCK_TIME=12:00:00 --subgroup case.run
./xmlchange RUN_TYPE=hybrid
./xmlchange GET_REFCASE=FALSE
./xmlchange RUN_REFCASE=b.e21.SMYLE_IC.f09_g17.${useyear}-${usemonth}.01
./xmlchange RUN_REFDATE=${useyear}-${usemonth}-01
./xmlchange RUN_STARTDATE=${useyear}-${usemonth}-01
./xmlchange DOUT_S_ROOT=/glade/derecho/scratch/nanr/SMYLE/archive/$runname/
./xmlchange CIME_OUTPUT_ROOT=/glade/derecho/scratch/nanr/SMYLE/
./xmlchange RUNDIR=$rundir
./xmlchange OCN_TRACER_MODULES="iage cfc ecosys"
 
./xmlchange PROJECT=P93300313
./xmlchange STOP_N=24
./xmlchange REST_N=24
./xmlchange STOP_OPTION=nmonths
./xmlchange RESUBMIT=0
./xmlchange NTASKS_WAV=1

./case.setup --reset
./preview_namelists

./xmlchange EXEROOT='/glade/derecho/scratch/nanr/SMYLE/exerootdir/bld'
./xmlchange BUILD_COMPLETE=TRUE

# 
cp $srcdir/SourceMods/src.cam/* ./SourceMods/src.cam/
cp $srcdir/SourceMods/src.clm/* ./SourceMods/src.clm/
cp $srcdir/user_mods/cesm2smyle.base/user_nl_* .

mkdir -p $rundir

echo "made it this far"
  
  # Lastly - copy Initial conditions
    echo "Here is the RUNDIR ${rundir}"
    camic="b.e21.SMYLE_IC.f09_g17.${useyear}-${usemonth}.01.cam.i.${useyear}-${usemonth}-01-00000.nc"
    pertcamic="b.e21.SMYLE_IC.pert.f09_g17.cam.i.${useyear}-${usemonth}-01-00000.nc"
    #ics="/glade/campaign/cesm/development/espwg/SMYLE/inputdata/cesm2_init/fromHiroyuki-2023/b.e21.SMYLE_IC.f09_g17.2023-11.01-JRA55-fromHiroyuki/b.e21.SMYLE_IC.f09_g17.${useyear}-${usemonth}.01/"
    ics="/glade/campaign/cesm/development/espwg/SMYLE/inputdata/cesm2_init/fromHiroyuki-2023/b.e21.SMYLE_IC.f09_g17.2023-11.01-JRA55-fromHiroyuki/"

    ls ${rundir}

    # pre-stage ICs
    cp ${ics}/${useyear}-${usemonth}-01/rpointer.* ${rundir}/
    ln -s ${ics}/${useyear}-${usemonth}-01/b.e21.* ${rundir}/

    # perturb the atmosphere IC
    if [[ ${mbr} -ne "001" ]]
    then
       shortmbr=${mbr:1:3}
       echo $shortmbr
       rm ${rundir}/${camic}
       echo ${ics}/pert.${shortmbr}/${pertcamic} ${rundir}/${camic}
       ln -s ${ics}/pert.${shortmbr}/${pertcamic} ${rundir}/${camic}
    fi

    cd $casedir
    if [[ ${mbr} -eq "021" ]]
    then
       cd $casedir
       qcmd -- ./case.build
    fi
    #./case.submit

done
