#!/bin/csh 
### set env variables
module load ncl nco

setenv CESM2_TOOLS_ROOT /glade/work/nanr/cesm_tags/CASE_tools/cesm2-smyle/
setenv ARCHDIR  /glade/scratch/$USER/SMYLE/archive/
setenv TSERIES2  /glade/campaign/cesm/development/espwg/SMYLE/archive

# ...
set syr = 2023
set eyr = 2023

@ ib = $syr
@ ie = $eyr

foreach year ( `seq $ib $ie` )
foreach mon ( 11 )
	#foreach mon ( 05 )


# case name counter
set smbr =  1
set embr =  20

@ mb = $smbr
@ me = $embr

foreach mbr ( `seq $mb $me` )
if ($mbr < 10) then
        set CASE = b.e21.BSMYLE-XT-beta.f09_g17.${year}-${mon}.00${mbr}
else
        set CASE = b.e21.BSMYLE-XT-beta.f09_g17.${year}-${mon}.0${mbr}
endif


echo "==================================    " 
if (-d $TSERIES2/$CASE) then
    set t2 = `ls -lR $TSERIES2/$CASE | wc -l`
    cd $TSERIES2/$CASE
    set s2 = `du . -sh`
    echo " campaign   ===    " ${year}-{$mon}.${mbr}   $t2  $s2
else
    echo " MISSING    ===    " ${year}-{$mon}.${mbr}
endif



end             # member loop
end             # member loop
end             # member loop

exit

