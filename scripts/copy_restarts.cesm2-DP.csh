#!/bin/csh -fx
### set env variables
module load ncl nco

setenv CESM2_TOOLS_ROOT /glade/work/nanr/cesm_tags/CASE_tools/cesm2-smyle/
setenv CESMROOT /glade/work/nanr/cesm_tags/cesm2.1.4-SMYLE

set COMPSET = BSMYLE
set MACHINE = cheyenne
set RESOLN = f09_g17
set RESUBMIT = 3
set STOP_N=24
set STOP_OPTION=nmonths
set PROJECT=CESM0020

set syr = 1958
set eyr = 1958

@ ib = $syr
@ ie = $eyr

@ RESTYEAR = $syr + 2

echo $RESTYEAR

foreach year ( `seq $ib $ie` )
foreach mon ( 11 )


# case name counter
set smbr =  21
set embr =  30

@ mb = $smbr
@ me = $embr

foreach mbr ( `seq $mb $me` )


# Use restarts created from case 001 for all ensemble members;  pertlim will differentiate runs.
if ($mbr < 10) then
        set CASE     = b.e21.BSMYLE.f09_g17.${year}-${mon}.00${mbr}
else
        set CASE     = b.e21.BSMYLE.f09_g17.${year}-${mon}.0${mbr}
endif

set REFROOT  = /glade/scratch/nanr/SMYLE/archive/${CASE}/rest/${RESTYEAR}-${mon}-01-00000/

echo 'Year   = ' $year
echo 'Member = ' $mbr
echo 'Case   = ' $CASE


  setenv DPDIR    /glade/scratch/$USER/SMYLE-EXTEND/
  setenv RUNDIR   /$DPDIR/b.e21.BSMYLE.f09_g17.${year}-${mon}.001/run.0${mbr}/

  cp    ${REFROOT}/rpointer* $RUNDIR/
  ln -s ${REFROOT}/b.e21*    $RUNDIR/

echo " End restarts copy -----------"

end             # member loop

exit

