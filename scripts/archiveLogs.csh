#!/bin/csh -fx
### set env variables
module load ncl nco

setenv CESM2_TOOLS_ROOT /glade/work/$USER/cesm_tags/CASE_tools/cesm2-smyle/
setenv ARCHDIR1  /glade/scratch/$USER/SMYLE-EXTEND/archive/
setenv ARCHDIR2  /glade/scratch/sglanvil/SMYLE-EXTEND/archive/
setenv TSERIES  /glade/campaign/cesm/development/espwg/SMYLE-EXTEND/timeseries
setenv LOGSDIR  /glade/campaign/cesm/development/espwg/SMYLE-EXTEND/logs
setenv POPDDIR  /glade/campaign/cesm/development/espwg/SMYLE-EXTEND/popd

set syr = 2011
set eyr = 2011

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

if ($year >= 1970 && $year <= 1979) then
 set USE_ARCHDIR = $ARCHDIR1
endif
if ($year >= 1990 && $year <= 1999) then
 set USE_ARCHDIR = $ARCHDIR1
endif
if ($year >= 2000 && $year <= 2014) then
 set USE_ARCHDIR = $ARCHDIR1
endif
if ($year >= 1980 && $year <= 1989) then
 set USE_ARCHDIR = $ARCHDIR2
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
#if (! -e $RESTDIR/$CASE.rest.tar) then
   #cd $USE_ARCHDIR
   #tar -cvf $RESTDIR/$CASE.rest.tar $CASE/rest/
#else
   #echo "rest done"
#endif
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

