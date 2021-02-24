#!/usr/bin/env bash 
source ~/.bash_profile
module load ncl
cd CESM2-Realtime-Forecast

sg_year=2020
sg_month=11

sg_date=$sg_year-$sg_month
echo $sg_date
./bin/getCDASdata.py --date $sg_date
export CYLC_TASK_CYCLE_POINT=$sg_date
ncl ./bin/create_landforcing_from_NCEPCFC.ncl

#./bin/getCDASdata.py
#export CYLC_TASK_CYCLE_POINT=`date +%Y-%m-%d -d yesterday`
#export CYLC_TASK_CYCLE_POINT=2019-07-26
#ncl ./bin/create_landforcing_from_NCEPCFC.ncl

#./bin/update_land_streams.py --case /glade/scratch/ssfcst/I2000Clm50BgcCrop.002runRealtime/
#cd /glade/scratch/ssfcst/I2000Clm50BgcCrop.002runRealtime/
#./xmlchange STOP_N=1
#./xmlchange STOP_OPTION=ndays
#./case.submit

echo "DONE"

