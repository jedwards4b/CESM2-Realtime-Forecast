#!/bin/bash
source /glade/u/apps/ch/opt/lmod/7.5.3/lmod/lmod/init/sh
module load ncl
outdir=$SCRATCH/70Lwaccm6/
# priority one vars
ncl $HOME/CESM2-Realtime-Forecast/bin/pp_priority1.ncl
# vertical remap h1 vars
ncl $HOME/CESM2-Realtime-Forecast/bin/pp_h1vertical.ncl
# vertical remap h4 vars
ncl $HOME/CESM2-Realtime-Forecast/bin/pp_h4vertical.ncl

# dispose of data
rsync -avzh $outdir jedwards@burnt.cgd.ucar.edu:/ftp/pub/jedwards/70Lwaccm6/
