#!/bin/csh 
### set env variables
module load ncl nco

setenv CESM2_TOOLS_ROOT /glade/work/nanr/cesm_tags/CASE_tools/cesm2-smyle-MCB/
setenv ARCHDIR  /glade/scratch/$USER/SMYLE-MCB/archive/
setenv TSERIES2  /glade/campaign/cesm/development/espwg/SMYLE-MCB/timeseries

# ...
# set syr = 1978
# set eyr = 2013
set syr = 2014
set eyr = 2014
set syr = 2015
set eyr = 2015

#if ($syr > 2019) then
#echo " go to cesm2-realtime scripts"
#exit
#endif

@ ib = $syr
@ ie = $eyr

foreach year ( `seq $ib $ie` )
#foreach mon ( 11 )
#foreach mon ( 02 05 08 11)
# foreach mon ( 11 )
foreach mon ( 02 05 08 )

# case name counter
set smbr =  1
set embr =  10

@ mb = $smbr
@ me = $embr

foreach mbr ( `seq $mb $me` )
if ($mbr < 10) then
        set CASE = b.e21.BSMYLE.f09_g17.MCB.${year}-${mon}.00${mbr}
else
        set CASE = b.e21.BSMYLE.f09_g17.MCB.${year}-${mon}.0${mbr}
endif


#echo "==================================    " 
#echo $CASE 
if (-d $TSERIES2/$CASE) then
    cd $TSERIES2/$CASE
    #set t1 = `ls  $TSERIES2/$CASE/atm/proc/tseries/month_1/*ZM_CLUBB* | wc -l`
    set t2 = `ls -lR $TSERIES2/$CASE | wc -l`
    set s2 = `du . -sh`
    if ($t2 < 1816 ) then
       echo  $CASE " ==============    " $t2  $s2
    else
       echo  $CASE " ===    " $t2  $s2
    endif
else
    echo " missing   ===    " $CASE
endif

end             # member loop
end             # member loop
end             # member loop

exit

