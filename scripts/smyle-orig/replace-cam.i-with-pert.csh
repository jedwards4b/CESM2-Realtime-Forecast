#!/bin/csh -fx
### set env variables
setenv CESM2_TOOLS_ROOT /glade/work/nanr/cesm_tags/CASE_tools/cesm2-smyle/
setenv CESMROOT /glade/work/nanr/cesm_tags/cesm2.1.4-SMYLE

setenv POSTPROCESS_PATH /glade/u/home/mickelso/CESM_postprocessing_3/
setenv POSTPROCESS_PATH_GEYSER /glade/u/home/mickelso/CESM_postprocessing_3/

set COMPSET = BSMYLE
set MACHINE = cheyenne
set RESOLN = f09_g17
set RESUBMIT = 0
set STOP_N=24
set STOP_OPTION=nmonths
set PROJECT=NCGD0047

setenv BASEROOT /glade/work/nanr/CESM2-SMYLE/cases/

set syr = 1958
set eyr = 1958
#set syr = 2007
#set eyr = 2007

@ ib = $syr
@ ie = $eyr

foreach year ( `seq $ib $ie` )
#foreach mon ( 02 05 08 11 )
foreach mon ( 11 )

set REFCASE  = b.e21.SMYLE_IC.f09_g17.${year}-${mon}.01
set REFROOT  = /glade/scratch/nanr/SMYLE/inputdata/cesm2_init/${REFCASE}/${year}-${mon}-01/
set PERTROOT  = /glade/scratch/nanr/SMYLE/inputdata/cesm2_init/${REFCASE}

#setenv CASEROOT /glade/p/cesm/espwg/CESM2-SMYLE/cases/$CASE
setenv INITDIR  /glade/scratch/nanr/SMYLE/
setenv DPDIR    /glade/scratch/nanr/SMYLE/
setenv SHORTCASE b.e21.BSMYLE.f09_g17.${year}-${mon}

#cd ~nanr/CESM-WF/
#./create_cylc_cesm2-smyle-ensemble --case $BASEROOT$SHORTCASE --res $RESOLN  --compset $COMPSET --project $PROJECT 



# case name counter
set smbr =  1
set embr =  10

@ mb = $smbr
@ me = $embr

foreach mbr ( `seq $mb $me` )

# Use restarts created from case 001 for all ensemble members;  pertlim will differentiate runs.
if ($mbr < 10) then
        set CASE = b.e21.BSMYLE.f09_g17.${year}-${mon}.00${mbr}
else
        set CASE = b.e21.BSMYLE.f09_g17.${year}-${mon}.0${mbr}
endif

echo 'Year   = ' $year
echo 'Member = ' $mbr
echo 'Case   = ' $CASE

  setenv RUNDIR   /$DPDIR/$CASE/run

  cp    ${REFROOT}/rpointer* $RUNDIR/
  ln -s ${REFROOT}/b.e21*    $RUNDIR/
  cd $RUNDIR
  set ifile = ${REFCASE}.cam.i.${year}-${mon}-01-00000.nc 
  set ofile = ${REFCASE}.cam.i.${year}-${mon}-01-00000-notUsed.nc
  mv $ifile $ofile
  echo ${PERTROOT}/pert0${mbr}/b.e21.SMYLE_IC.pert.f09_g17.cam.i* $RUNDIR/$ifile
  if ($mbr < 10) then
  	cp ${PERTROOT}/../pert0${mbr}/b.e21.SMYLE_IC.pert.f09_g17.cam.i* $RUNDIR/$ifile
  else
   	cp ${REFROOT}/../pert${mbr}/b.e21.SMYLE_IC.pert.f09_g17.cam.i* $RUNDIR/$ifile
  end if

end             # member loop

exit

