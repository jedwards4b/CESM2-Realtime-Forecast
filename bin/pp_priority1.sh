#!/bin/bash
source /glade/u/apps/ch/opt/lmod/7.5.3/lmod/lmod/init/sh
module load ncl
ncl /glade/work/jedwards/sandboxes/CESM2-Realtime-Forecast/bin/pp_priority1.ncl
# dispose of data
