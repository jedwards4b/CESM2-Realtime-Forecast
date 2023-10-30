#!/usr/bin/env bash 
source ~/.bash_profile
module load ncl
cd cesm2cam6/CESM2-Realtime-Forecast

# ------- original ---------
./bin/getCDASdata.py
export CYLC_TASK_CYCLE_POINT=`date +%Y-%m-%d -d yesterday`
ncl ./bin/create_landforcing_from_NCEPCFC.ncl
./bin/update_land_streams.py --case /glade/scratch/espstoch/I2000Clm50BgcCrop.002runRealtime/

# -------- attempt to get around the issue for now (Dec. 1, 2020, sasha glanville)
#sg_year=2021
#sg_month=03
#sg_date=$sg_year-$sg_month
#echo $sg_date
#./bin/getCDASdata.py --date $sg_date
#export CYLC_TASK_CYCLE_POINT=$sg_date
#ncl ./bin/create_landforcing_from_NCEPCFC.ncl
#./bin/update_land_streams.py --case /glade/scratch/ssfcst/I2000Clm50BgcCrop.002runRealtime/

echo "DONE"

