#!/usr/bin/env bash 
source ~/.bash_profile
cd CESM2-Realtime-Forecast
./bin/getCDASdata.py
export CYLC_TASK_CYCLE_POINT=`date +%Y-%m-%d -d yesterday`
ncl ./bin/create_landforcing_from_NCEPCFC.ncl

./bin/update_land_streams.py --case/glade/scratch/ssfcst/I2000Clm50BgcCrop.002runContd/
cd /glade/scratch/ssfcst/I2000Clm50BgcCrop.002runContd/
./xmlchange STOP_N=10
./xmlchange STOP_OPTION=ndays
./case.submit

