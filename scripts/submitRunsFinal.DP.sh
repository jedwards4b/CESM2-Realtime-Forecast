#!/bin/bash

useyear=2022
usemonth=11

compset='BSMYLE'
usecompset='BSMYLE'
resoln='f09_g17'
caseroot='/glade/campaign/cesm/development/espwg/SMYLE-CASES/CESM2-SMYLE/cases/'

main_case_root='b.e21.'$usecompset'.'$resoln'.'${useyear}'-'${usemonth}'.001'

for mbr in $(seq -f "%03g" 1 20)
do

echo "Final submission for member:${mbr}"

runname=b.e21.$usecompset.$resoln.$useyear-$usemonth.$mbr
casedir=$caseroot/$runname

cd $casedir

# Uncomment for changing RESUBMIT
# ./xmlchange RESUBMIT=4

# Uncomment for changing STOP_N, REST_N for the final submission
#./xmlchange STOP_N=2,REST_N=2

./case.submit

done
