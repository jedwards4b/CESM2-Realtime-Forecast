#!/bin/csh -fx
### set env variables
module load ncl nco

setenv CESM2_TOOLS_ROOT /glade/work/$USER/cesm_tags/CASE_tools/cesm2-smyle/
setenv ARCHDIR  /glade/scratch/$USER/SMYLE/archive/
setenv TSERIES  /glade/campaign/cesm/development/espwg/SMYLE/archive
setenv LOGSDIR  /glade/campaign/cesm/development/espwg/SMYLE/logs
setenv RESTDIR  /glade/campaign/cesm/development/espwg/SMYLE/restarts
setenv POPDDIR  /glade/campaign/cesm/development/espwg/SMYLE/popd

set syr = 2000
set eyr = 2005

@ ib = $syr
@ ie = $eyr

foreach year ( `seq $ib $ie` )
#foreach mon ( 02 05 08 11 )
foreach mon ( 11 )


# case name counter
set smbr =  11
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

if (! -d $TSERIES/$CASE/cpl/hist) then
	mkdir -p $TSERIES/$CASE/cpl/hist
endif
cp $ARCHDIR/$CASE/cpl/hist/* $TSERIES/$CASE/cpl/hist/

tar -cvf $LOGSDIR/$CASE.logs.tar $ARCHDIR/$CASE/logs
tar -cvf $RESTDIR/$CASE.rest.tar $ARCHDIR/$CASE/rest/
tar -cvf $POPDDIR/$CASE.popd.tar $ARCHDIR/$CASE/ocn/hist/*.pop.d*

end             # member loop
end             # year loop

exit

