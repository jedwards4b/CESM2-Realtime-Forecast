#!/bin/csh -fx
### set env variables
module load ncl nco

setenv CESM2_TOOLS_ROOT /glade/work/$USER/cesm_tags/CASE_tools/cesm2-smyle/
setenv ARCHDIR2  /glade/scratch/nanr/SMYLE/archive/
setenv TSERIES  /glade/campaign/cesm/development/espwg/SMYLE-AUFIRE/archive
setenv LOGSDIR  /glade/campaign/cesm/development/espwg/SMYLE-AUFIRE/logs
setenv RESTDIR  /glade/campaign/cesm/development/espwg/SMYLE-AUFIRE/restarts
setenv POPDDIR  /glade/campaign/cesm/development/espwg/SMYLE-AUFIRE/popd

set syr = 2019
set eyr = 2019

@ ib = $syr
@ ie = $eyr

foreach year ( `seq $ib $ie` )
#foreach mon ( 02 05 08 11 )
#foreach mon ( 11 )
foreach mon ( 08 )


# case name counter
set smbr =  1
set embr =  30

@ mb = $smbr
@ me = $embr

foreach mbr ( `seq $mb $me` )
if ($mbr < 10) then
        set CASE = b.e21.BSMYLE-AUFIRE.f09_g17.${year}-${mon}.50${mbr}
else
        set CASE = b.e21.BSMYLE-AUFIRE.f09_g17.${year}-${mon}.5${mbr}
endif

set USE_ARCHDIR = $ARCHDIR2

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

