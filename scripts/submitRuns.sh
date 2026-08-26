#!/bin/bash

useyear=2022
usemonth=11

curdir='/glade/work/nanr/cesm_tags/CASE_tools/cesm2-smyle/'
srcdir='/glade/work/nanr/cesm_tags/CASE_tools/cesm2-smyle/'
compset='BSMYLE'
usecompset='BSMYLE'
resoln='f09_g17'
tagdir='/glade/work/nanr/cesm_tags/cesm2.1.4-SMYLE/'
caseroot='/glade/campaign/cesm/development/espwg/SMYLE-CASES/CESM2-SMYLE/cases/'

main_case_root='b.e21.'$usecompset'.'$resoln'.'${useyear}'-'${usemonth}'.001'

for mbr in $(seq -f "%03g" 1 20)
do

echo "setting up member ${mbr}"

runname=b.e21.$usecompset.$resoln.$useyear-$usemonth.$mbr
casedir=$caseroot/$runname

cd $casedir

./case.submit

done
