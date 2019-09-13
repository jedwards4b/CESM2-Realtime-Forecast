#!/bin/bash
source /glade/u/apps/ch/opt/lmod/7.5.3/lmod/lmod/init/sh
module load ncl
outdir=$SCRATCH/70Lwaccm6/
ncl $HOME/CESM2-Realtime-Forecast/bin/pp_priority1.ncl
# dispose of data
rsync -avzh $outdir jedwards@burnt.cgd.ucar.edu:/ftp/pub/jedwards/70Lwaccm6/
