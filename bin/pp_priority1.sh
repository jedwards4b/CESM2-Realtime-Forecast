#!/bin/bash
source /glade/u/apps/ch/opt/lmod/7.5.3/lmod/lmod/init/sh
module load ncl
outdir=$SCRATCH/70Lwaccm6/$CYLC_TASK_CYCLE_POINT/
mkdir -p $outdir
ncl $HOME/CESM2-Realtime-Forecast/bin/pp_priority1.ncl
# dispose of data
scp -r $outdir jedwards@burnt.cgd.ucar.edu:/ftp/pub/jedwards/70Lwaccm6
