#!/usr/bin/env sh
CESM_ROOT="$HOME/sandboxes/CESM2-Realtime-Forecast/cesm2_1/"
caseroot="$HOME/sandboxes/CESM2-Realtime-Forecast/cases"
casename="b.e21.BWHIST.SD.f09_g17.001"
res="f09_g17"
compset="BWHIST"

cd $CESM_ROOT/cime/scripts
./create_newcase --res $res --compset $compset --case $caseroot/$casename --handle-preexisting-dirs r
cd $caseroot/$casename

./xmlchange --append CAM_CONFIG_OPTS="-nlev 70 -offline_dyn"
./xmlchange OCN_TRACER_MODULES=''
./xmlchange RUN_REFCASE="b.e21.BWHIST.f09_g17.CMIP6-historical-WACCM.001"
./xmlchange RUN_REFDATE="2000-01-01"
./xmlchange RUN_STARTDATE="1998-01-01"
./xmlchange STOP_OPTION="nmonths"
./xmlchange STOP_N=2
./xmlchange REST_OPTION="ndays"
./xmlchange REST_N=1
./xmlchange DOUT_S_SAVE_INTERIM_RESTART_FILES="TRUE"
./xmlchange CCSM_BGC="CO2A"

./case.setup

cat <<EOF >> user_nl_pop
  chl_option='file'
EOF
cat <<EOF >> user_nl_cam
  met_data_file="1998/01/MERRA2_0.9x1.25_L70_19980101.nc"
  met_data_path="/gpfs/fs1/scratch/sglanvil/MET/MERRA2/L70/0.9x1.25/"
  met_filenames_list="/gpfs/fs1/scratch/sglanvil/MET/MERRA2/L70/0.9x1.25/filenames_1998-2015_noLeap.txt"
  met_qflx_factor=0.84
  met_rlx_time=1
  inithist='DAILY'
  bnd_topo="$CESMDATAROOT/inpudata/atm/cam/met/MERRA2/0.9x1.25/fv_0.9x1.25_nc3000_Nsw042_Nrs008_Co060_Fi001_ZR_sgh30_24km_GRNL_MERRA2_c171218.nc"
EOF

./case.build
