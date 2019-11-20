#!/usr/bin/env bash
source ~/.bash_profile
cd CESM2-Realtime-Forecast
./bin/getCDASdata.py
./bin/create_landforcing_from_NCEPCFC.ncl 
./bin/update_land_streams.py --case/glade/scratch/ssfcst/I2000Clm50BgcCrop.002runContd/
cd /glade/scratch/ssfcst/I2000Clm50BgcCrop.002runContd/
./xmlchange STOP_N=1
./xmlchange STOP_OPTION=ndays
./case.submit

ssh data-access rsync -zavh --size-only /glade/scratch/ssfcst/archive/I2000Clm50BgcCrop.002runContd/rest/ /glade/campaign/cesm/development/cross-wg/S2S/land/rest/
