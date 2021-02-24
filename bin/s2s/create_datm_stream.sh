#!/bin/bash -l
# wrapper to get daily CDAS data and convert to datm stream
basedir=/glade/u/home/jedwards/sandboxes/CESM2-Realtime-Forecast/
module load ncl
module load python
cd $basedir
python ./bin/getCDASdata.py
ncl ./bin/create_landforcing_from_NCEPCFC.ncl
