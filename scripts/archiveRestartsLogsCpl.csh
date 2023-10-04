#!/bin/csh -fx
### set env variables
module load ncl nco

setenv CESM2_TOOLS_ROOT /glade/work/$USER/cesm_tags/CASE_tools/cesm2-smyle/
setenv ARCHDIR1  /glade/scratch/$USER/SMYLE/archive/
setenv ARCHDIR2  /glade/scratch/sglanvil/SMYLE/archive/
setenv TSERIES  /glade/campaign/cesm/development/espwg/SMYLE/archive-pre1970
setenv LOGSDIR  /glade/campaign/cesm/development/espwg/SMYLE/logs
setenv RESTDIR  /glade/campaign/cesm/development/espwg/SMYLE/restarts
setenv POPDDIR  /glade/campaign/cesm/development/espwg/SMYLE/popd

set syr = 1958
set eyr = 1960

@ ib = $syr
@ ie = $eyr

foreach year ( `seq $ib $ie` )
#foreach mon ( 02 05 08 11 )
foreach mon ( 11 )
#foreach mon ( 02 )


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

if ($year >= 1958 && $year <= 1969) then
 set USE_ARCHDIR = $ARCHDIR1
endif
if ($year >= 1970 && $year <= 1979) then
 set USE_ARCHDIR = $ARCHDIR1
endif
if ($year >= 1990 && $year <= 1999) then
 set USE_ARCHDIR = $ARCHDIR1
endif
if ($year >= 2010 && $year <= 2018) then
 set USE_ARCHDIR = $ARCHDIR2
endif
if ($year >= 1980 && $year <= 1989) then
 set USE_ARCHDIR = $ARCHDIR2
endif
if ($year == 2019 ) then
 set USE_ARCHDIR = $ARCHDIR1
endif


if (! -d $TSERIES/$CASE/cpl/hist) then
	mkdir -p $TSERIES/$CASE/cpl/hist
        cp $USE_ARCHDIR/$CASE/cpl/hist/* $TSERIES/$CASE/cpl/hist/
else
   echo "cpl done"
endif
if (! -e $LOGSDIR/$CASE.logs.tar) then
   cd $USE_ARCHDIR
   tar -cvf $LOGSDIR/$CASE.logs.tar $CASE/logs/
else
   echo "logs done"
endif
if (! -e $RESTDIR/$CASE.rest.tar) then
   cd $USE_ARCHDIR
   tar -cvf $RESTDIR/$CASE.rest.tar $CASE/rest/
else
   echo "rest done"
endif
if (! -e $POPDDIR/$CASE.popd.tar) then
   cd $USE_ARCHDIR
   tar -cvf $POPDDIR/$CASE.popd.tar $CASE/ocn/hist/*.pop.d*
else
   echo "popd done"
endif

end             # mon loop
end             # member loop
end             # year loop

exit

