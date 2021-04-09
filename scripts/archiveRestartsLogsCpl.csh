#!/bin/csh -fx
### set env variables
module load ncl nco

setenv CESM2_TOOLS_ROOT /glade/work/$USER/cesm_tags/CASE_tools/cesm2-smyle/
setenv ARCHDIR1  /glade/scratch/$USER/SMYLE/archive/
setenv ARCHDIR2  /glade/scratch/sglanvil/SMYLE/archive/
setenv TSERIES  /glade/campaign/cesm/development/espwg/SMYLE/archive
setenv LOGSDIR  /glade/campaign/cesm/development/espwg/SMYLE/logs
setenv RESTDIR  /glade/campaign/cesm/development/espwg/SMYLE/restarts
setenv POPDDIR  /glade/campaign/cesm/development/espwg/SMYLE/popd

set syr = 1971
set eyr = 1989

@ ib = $syr
@ ie = $eyr

foreach year ( `seq $ib $ie` )
#foreach mon ( 02 05 08 11 )
foreach mon ( 11 )


# case name counter
set smbr =  1
set embr =  20

@ mb = $smbr
@ me = $embr

foreach mbr ( `seq $mb $me` )
if ($mbr < 10) then
        set CASE = b.e21.BSMYLE.f09_g17.${year}-${mon}.00${mbr}
else
        set CASE = b.e21.BSMYLE.f09_g17.${year}-${mon}.0${mbr}
endif

if ($year >= 1980 && $year <= 1989) then
 set USEARCHDIR = $ARCHDIR2
endif
if ($year >= 1970 && $year <= 1979) then
 set USEARCHDIR = $ARCHDIR1
endif

if (! -d $TSERIES/$CASE/cpl/hist) then
	mkdir -p $TSERIES/$CASE/cpl/hist
        cp $USEARCHDIR/$CASE/cpl/hist/* $TSERIES/$CASE/cpl/hist/
endif

if (! -e $LOGSDIR/$CASE.logs.tar) then
   tar -cvf $LOGSDIR/$CASE.logs.tar $USEARCHDIR/$CASE/logs
endif
if (! -e $RESTDIR/$CASE.rest.tar) then
   tar -cvf $RESTDIR/$CASE.rest.tar $USEARCHDIR/$CASE/rest/
endif
if (! -e $POPDDIR/$CASE.popd.tar) then
   tar -cvf $POPDDIR/$CASE.popd.tar $USEARCHDIR/$CASE/ocn/hist/*.pop.d*
endif

end             # member loop
end             # year loop

exit

