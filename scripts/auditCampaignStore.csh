#!/bin/csh 
### set env variables
module load ncl nco

setenv CESM2_TOOLS_ROOT /glade/work/nanr/cesm_tags/CASE_tools/cesm2-smyle/
setenv ARCHDIR  /glade/scratch/$USER/SMYLE/archive/
setenv TSERIES1  /glade/scratch/sglanvil/SMYLE/timeseries
setenv TSERIES1  /glade/scratch/nanr/SMYLE/timeseries
setenv TSERIES1  /glade/p/cesm/espwg/CESM2-SMYLE/timeseries
setenv TSERIES2  /glade/campaign/cesm/development/espwg/SMYLE/archive

set syr = 1963
set eyr = 1963
# ...
set syr = 1970
set eyr = 2018

@ ib = $syr
@ ie = $eyr

foreach year ( `seq $ib $ie` )
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


echo "==================================    " 
#echo $CASE 
if (-d $TSERIES2/$CASE) then
    cd $TSERIES2/$CASE
    #set t1 = `ls  $TSERIES2/$CASE/atm/proc/tseries/month_1/*ZM_CLUBB* | wc -l`
    set t2 = `ls -lR $TSERIES2/$CASE | wc -l`
    set s2 = `du . -sh`
    echo  $CASE " ===    " $t2  $s2
else
    echo " missing   ===    " $CASE
endif

end             # member loop
end             # member loop
end             # member loop

exit

