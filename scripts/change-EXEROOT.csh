#!/bin/csh -fx
### set env variables
module load ncl nco

setenv ARCHDIR  /glade/scratch/$USER/SMYLE-PACEMAKER/

set syr = 1980
set eyr = 1987

@ ib = $syr
@ ie = $eyr

foreach year ( `seq $ib $ie` )
foreach mon ( 02 )


# case name counter
set smbr =  1
set embr =  5

@ mb = $smbr
@ me = $embr


foreach mbr ( `seq $mb $me` )

set PATH = /glade/p/cesm/espwg/CESM2-SMYLE-PACEMAKER/cases/
set CASE = b.e21.BSMYLE.f09_g17.TBI-ATL_15d50m-anom.${year}-${mon}.00${mbr}
set CASEROOT=$PATH/$CASE
cd $CASEROOT

echo 'Year   = ' $year
echo 'Member = ' $mbr
echo 'Case   = ' $CASE

./xmlchange EXEROOT=/glade/scratch/nanr/SMYLE-PACEMAKER/exerootdir/bld
./xmlchange BUILD_COMPLETE=TRUE

end             # member loop
end             # mon loop
end             # year loop

exit

