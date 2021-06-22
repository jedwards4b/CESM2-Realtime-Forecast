#!/bin/csh -fx
### set env variables
module load ncl nco

setenv CESM2_TOOLS_ROOT /glade/work/$USER/cesm_tags/CASE_tools/cesm2-comet-smyle/
setenv ARCHDIR1  /glade/scratch/$USER/SMYLE-ERA5/inputdata/cesm2_init/
setenv CAMPAIGN  /glade/campaign/cesm/development/espwg/SMYLE-ERA5/inputdata/cesm2_init/

set syr = 1970
set eyr = 2018

@ ib = $syr
@ ie = $eyr

foreach year ( `seq $ib $ie` )
#foreach mon ( 10 11 12 01 )
foreach mon ( 10 )


# case name counter

set CASE = b.e21.SMYLE_ERA5_IC.f09_g17.${year}-${mon}.01

if (! -e $CAMPAIGN/$CASE.tar) then
   cd $ARCHDIR1
   tar -cvf $CAMPAIGN/$CASE.tar ./$CASE/
else
   echo "IC archived done"
endif

end             # mon loop
end             # year loop

exit

