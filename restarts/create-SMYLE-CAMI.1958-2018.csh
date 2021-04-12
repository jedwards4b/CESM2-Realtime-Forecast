#! /bin/csh -fxv 

setenv CESM2_TOOLS_ROOT /glade/work/nanr/cesm_tags/CASE_tools/cesm2-smyle/
setenv CESMROOT /glade/work/nanr/cesm_tags/cesm2.1.4-SMYLE

if ($HOST != casper10) then
echo "ERROR:  Must be run on Casper"
#exit
endif


#foreach  year ( 1954 1964 1974 1984 1994 2004 )
set syr = 1959
set eyr = 1970
#set syr = 2007
#set eyr = 2007
#set syr = 1958
#set eyr = 1970
set syr = 1970
set eyr = 1970

@ ib = $syr
@ ie = $eyr

foreach year ( `seq $ib $ie` )
#foreach mon ( 02 05 08 11 )
#foreach mon ( 05 08 11 )
#foreach mon ( 11 )
foreach mon ( 02 )

set case = b.e21.SMYLE_IC.f09_g17.${year}-${mon}.01

#set icdir = /glade/p/cesm/cseg/inputdata/ccsm4_init/{$case} 
set Picdir = /glade/scratch/nanr/SMYLE/inputdata/cesm2_init/{$case}/
set icdir  = /glade/scratch/nanr/SMYLE/inputdata/cesm2_init/{$case}/${year}-${mon}-01
if (! -d ${Picdir}) then
 mkdir ${Picdir}
endif
if (! -d ${icdir}) then
 mkdir ${icdir}
endif

# ==================================
# generate perturbed cam.i.restarts
# ==================================
setenv CYLC_TASK_CYCLE_POINT ${year}-${mon}-01
cd ${CESM2_TOOLS_ROOT}/restarts/
./generate_cami_ensemble_offline.py
#./test_generate_cami.py

end
end

exit
 
 



