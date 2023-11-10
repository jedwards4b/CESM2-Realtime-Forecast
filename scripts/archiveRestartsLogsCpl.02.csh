#!/bin/csh -fx
### set env variables
module load ncl nco

setenv CESM2_TOOLS_ROOT /glade/work/$USER/cesm_tags/CASE_tools/cesm2-smyle-PACEMAKER/
#setenv ARCHSTEVE  /glade/scratch/yeager/SMYLE-PACEMAKER/archive/
setenv TSERIES  /glade/campaign/cesm/development/espwg/SMYLE-PACEMAKER/archive
setenv LOGSDIR  /glade/campaign/cesm/development/espwg/SMYLE-PACEMAKER/logs
setenv RESTDIR  /glade/campaign/cesm/development/espwg/SMYLE-PACEMAKER/restarts
setenv POPDDIR  /glade/campaign/cesm/development/espwg/SMYLE-PACEMAKER/popd

set syr = 1978
set eyr = 2018

#setenv ARCHSTEVE  /glade/scratch/yeager/SMYLE-PACEMAKER/archive/
setenv ARCHNANR  /glade/scratch/$USER/SMYLE-PACEMAKER/archive/
#setenv ARCHNANR  /glade/scratch/sglanvil/SMYLE-PACEMAKER/archive/

@ ib = $syr
@ ie = $eyr

foreach year ( `seq $ib $ie` )
#foreach mon ( 02 05 08 11 )
#foreach mon ( 11 )
foreach mon ( 02 )


# case name counter
set smbr =  1
set embr =  10

@ mb = $smbr
@ me = $embr

foreach mbr ( `seq $mb $me` )
if ($mbr < 10) then
        #set CASE = b.e21.BSMYLE.f09_g17.TBI-ATL_10d50m-anom.${year}-${mon}.00${mbr}
        set CASE = b.e21.BSMYLE.f09_g17.TBI-ATL_15d50m-anom.${year}-${mon}.00${mbr}
        #set CASE = b.e21.BSMYLE.f09_g17.TBI-SOC_15d50m-anom.${year}-${mon}.00${mbr}
        #set CASE = b.e21.BSMYLE.f09_g17.TBI-IND_15d50m-anom.${year}-${mon}.00${mbr}
        #set CASE = b.e21.BSMYLE.f09_g17.TBI-PAC_15d50m-anom.${year}-${mon}.00${mbr}
else
        #set CASE = b.e21.BSMYLE.f09_g17.TBI-ATL_10d50m-anom.${year}-${mon}.0${mbr}
        set CASE = b.e21.BSMYLE.f09_g17.TBI-ATL_15d50m-anom.${year}-${mon}.0${mbr}
        #set CASE = b.e21.BSMYLE.f09_g17.TBI-SOC_15d50m-anom.${year}-${mon}.0${mbr}
        #set CASE = b.e21.BSMYLE.f09_g17.TBI-IND_15d50m-anom.${year}-${mon}.0${mbr}
        #set CASE = b.e21.BSMYLE.f09_g17.TBI-PAC_15d50m-anom.${year}-${mon}.0${mbr}
endif

set USE_ARCHDIR = $ARCHNANR

if (! -d $TSERIES/$CASE/cpl/hist) then
	mkdir -p $TSERIES/$CASE/cpl/hist
else
   cp $USE_ARCHDIR/$CASE/cpl/hist/* $TSERIES/$CASE/cpl/hist/
   echo "cpl done"
endif
if (! -e $LOGSDIR/$CASE.logs.tar) then
   cd $USE_ARCHDIR
   tar -cvf $LOGSDIR/$CASE.logs.tar $CASE/logs/*.gz
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

