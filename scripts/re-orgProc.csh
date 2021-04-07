#!/bin/csh -fx
### set env variables
module load ncl nco

setenv CESM2_TOOLS_ROOT /glade/work/nanr/cesm_tags/CASE_tools/cesm2-smyle/
setenv ARCHDIR  /glade/scratch/$USER/SMYLE/archive/
setenv TSERIES  /glade/scratch/$USER/SMYLE/timeseries

# ...
set syr = 1970
set eyr = 1970

@ ib = $syr
@ ie = $eyr

foreach year ( `seq $ib $ie` )
#foreach mon ( 02 05 08 11 )
foreach mon ( 11 )


# case name counter
set smbr =  20
set embr =  20

@ mb = $smbr
@ me = $embr

foreach mbr ( `seq $mb $me` )
if ($mbr < 10) then
        set CASE = b.e21.BSMYLE.f09_g17.${year}-${mon}.00${mbr}
else
        set CASE = b.e21.BSMYLE.f09_g17.${year}-${mon}.0${mbr}
endif

echo 'Year   = ' $year
echo 'Member = ' $mbr
echo 'Case   = ' $CASE

if (! -d $TSERIES/$CASE/) then
	mkdir -p $TSERIES/$CASE/atm
	mkdir -p $TSERIES/$CASE/glc
	mkdir -p $TSERIES/$CASE/ice
	mkdir -p $TSERIES/$CASE/lnd
	mkdir -p $TSERIES/$CASE/ocn
	mkdir -p $TSERIES/$CASE/rof
endif
mv $ARCHDIR/$CASE/atm/proc $TSERIES/$CASE/atm
mv $ARCHDIR/$CASE/glc/proc $TSERIES/$CASE/glc
mv $ARCHDIR/$CASE/ice/proc $TSERIES/$CASE/ice
mv $ARCHDIR/$CASE/lnd/proc $TSERIES/$CASE/lnd
mv $ARCHDIR/$CASE/ocn/proc $TSERIES/$CASE/ocn
mv $ARCHDIR/$CASE/rof/proc $TSERIES/$CASE/rof

end             # member loop

exit

