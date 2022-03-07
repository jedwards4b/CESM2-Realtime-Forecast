#!/bin/csh 
### set env variables
module load ncl nco

setenv CESM2_TOOLS_ROOT /glade/work/nanr/cesm_tags/CASE_tools/cesm2-smyle/
setenv DOUT_S_ROOT  /glade/scratch/$USER/SMYLE/archive/
setenv CASEROOT /glade/p/cesm/espwg/CESM2-SMYLE-EXTEND/cases

# ...
set syr = 1992
set eyr = 1992

@ ib = $syr
@ ie = $eyr

foreach year ( `seq $ib $ie` )
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

cd $CASEROOT/$CASE
./xmlchange STOP_N=26
./xmlchange REST_N=26

end             # mbr loop
end             # mon loop
end             # year loop

exit

