#!/bin/csh -fx
### set env variables
module load ncl nco

setenv ARCHDIR  /glade/scratch/$USER/SMYLE-PACEMAKER/
setenv INPDATA  /glade/campaign/cesm/development/espwg/inputdata/cesm_init

set syr = 2019
set eyr = 2019

@ ib = $syr
@ ie = $eyr

foreach year ( `seq $ib $ie` )
foreach mon ( 02 )


# case name counter
set smbr =  2
set embr =  5

@ mb = $smbr
@ me = $embr

set CASE = b.e21.BSMYLE.f09_g17.TBI-ATL_10d50m-anom.${year}-${mon}.001

foreach mbr ( `seq $mb $me` )
if ($mbr < 10) then
        cd $ARCHDIR/$CASE/run.00${mbr}
        set PERTROOT = pert.0${mbr}
else
        cd $ARCHDIR/$CASE/run.0${mbr}
        set PERTROOT = pert.${mbr}
endif

echo 'Year   = ' $year
echo 'Member = ' $mbr
echo 'Case   = ' $CASE

rm b.e21.SMYLE_IC.f09_g17.${year}-02.01.cam.i.${year}-02-01-00000.nc
ln -s /glade/p/cesm/espwg/CESM2-SMYLE/inputdata/cesm2_init/b.e21.SMYLE_IC.f09_g17.${year}-02.01/${PERTROOT}/b.e21.SMYLE_IC.pert.f09_g17.cam.i.${year}-02-01-00000.nc ./b.e21.SMYLE_IC.f09_g17.${year}-02.01.cam.i.${year}-02-01-00000.nc

end             # member loop
end             # mon loop
end             # year loop

exit

