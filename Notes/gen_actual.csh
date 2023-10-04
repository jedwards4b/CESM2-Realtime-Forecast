#!/bin/tcsh

setenv CASE b.e21.SMYLE.f09_g16.1958-11.060
setenv DOUT_S_ROOT /glade/scratch/nanr/SMYLE/archive/$CASE

set YYYY = 1958
set MM = 12

set fname = $DOUT_S_ROOT/ocn/hist/$CASE.pop.h.$YYYY-$MM.nc
ncdump -h $fname | grep "float .*time, z.*, nlat, nlon" | grep -v z_t_150m | cut -f1 -d'(' | awk '{print $NF}' | sort > monthly.3d_full.actual

set fname = $DOUT_S_ROOT/ocn/hist/$CASE.pop.h.$YYYY-$MM.nc
ncdump -h $fname | grep "float .*time, nlat, nlon" | cut -f1 -d'(' | awk '{print $NF}' | sort > monthly.2d.actual

set fname = $DOUT_S_ROOT/ocn/hist/$CASE.pop.h.$YYYY-$MM.nc
ncdump -h $fname | grep "float .*time, z_t_150m, nlat, nlon" | cut -f1 -d'(' | awk '{print $NF}' | sort > monthly.z_t_150m.actual

set fname = $DOUT_S_ROOT/ocn/hist/$CASE.pop.h.nday1.$YYYY-$MM-01.nc
ncdump -h $fname | grep "float .*time.*nlat, nlon" | cut -f1 -d'(' | awk '{print $NF}' | sort > nday1.actual

set fname = $DOUT_S_ROOT/ocn/hist/$CASE.pop.h.ecosys.nday1.$YYYY-$MM-01.nc
ncdump -h $fname | grep "float .*time.*nlat, nlon" | cut -f1 -d'(' | awk '{print $NF}' | sort > ecosys.nday1.actual

set fname = $DOUT_S_ROOT/ocn/hist/$CASE.pop.h.ecosys.nyear1.$YYYY.nc
ncdump -h $fname | grep "float .*time.*nlat, nlon" | cut -f1 -d'(' | awk '{print $NF}' | sort > ecosys.nyear1.actual
