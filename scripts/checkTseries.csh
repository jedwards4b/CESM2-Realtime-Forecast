#!/bin/tcsh

setenv CASE b.e21.BSMYLE.f09_g17.1958-11.001
setenv DOUT_S_ROOT /glade/p/cesm/espwg/CESM2-SMYLE/timeseries/$CASE

set YYYY = 1958
set YYYY = 1959
set MM = 11

set fname = $DOUT_S_ROOT/$CASE.0??
