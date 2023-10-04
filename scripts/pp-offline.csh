#!/bin/csh 
### set env variables
module load ncl nco

setenv CESM2_TOOLS_ROOT /glade/work/nanr/cesm_tags/CASE_tools/cesm2-smyle/
setenv ARCHDIR  /glade/scratch/$USER/SMYLE/archive/
setenv TSERIES1  /glade/scratch/sglanvil/SMYLE/timeseries
setenv TSERIES1  /glade/scratch/nanr/SMYLE/timeseries
setenv TSERIES1  /glade/p/cesm/espwg/CESM2-SMYLE/timeseries
setenv TSERIES2  /glade/campaign/cesm/development/espwg/SMYLE/archive
setenv CASEROOT  /glade/p/cesm/espwg/CESM2-SMYLE/cases

module use /glade/work/bdobbins/Software/Modules
module load cesm_postprocessing

# ...
set syr = 2005
set eyr = 2005

@ ib = $syr
@ ie = $eyr

foreach year ( `seq $ib $ie` )
foreach mon ( 08 )

# case name counter
set smbr =  20
set embr =  20

@ mb = $smbr
@ me = $embr

foreach mbr ( `seq $mb $me` )
if ($mbr < 10) then
        set CASE = btestpp.e21.BSMYLE.f09_g17.${year}-${mon}.00${mbr}
else
        set CASE = btestpp.e21.BSMYLE.f09_g17.${year}-${mon}.0${mbr}
        set CASE = btestpp.e21.BSMYLE.f09_g17.2001-08.020
endif

cd $CASEROOT/$CASE

if ( ! -d "postprocess" ) then
   create_postprocess -caseroot=`pwd`
endif

cd postprocess
pp_config --set TIMESERIES_OUTPUT_ROOTDIR=/glade/scratch/nanr/timeseries/$CASE/
#pp_config --set TIMESERIES_OUTPUT_ROOTDIR=/glade/p/cesm/espwg/CESM2-SMYLE/timeseries/$CASE/
#qsub ./timeseries 

if ($mbr < 10) then
   set usembr = "00"${mbr}
else
   set usembr = "0"${mbr}
endif

echo $usembr

# =========================
# change a few things
# =========================
mv timeseries timeseries-OTB
cat >> timeseries << EOF
#!/bin/bash

#PBS -N ${year}-${mon}-${usembr}
#PBS -q regular
#PBS -l select=1:ncpus=36:mpiprocs=36
#PBS -l walltime=12:00:00
#PBS -A NCGD0047


##########
##
## See https://github.com/NCAR/CESM_postprocessing/wiki for details
## regarding settings for optimal performance for CESM postprocessing tools.
##
##########

module use /glade/work/bdobbins/Software/Modules
module load cesm_postprocessing

module load impi
module load singularity/3.7.2

mpirun singularity run -B /glade,/var /glade/work/bdobbins/Containers/CESM_Postprocessing/image /opt/ncar/cesm_postprocessing/cesm-env2/bin/cesm_tseries_generator.py  --caseroot /glade/p/cesm/espwg/CESM2-SMYLE/cases/b.e21.BSMYLE.f09_g17.${year}-${mon}.${usembr}/postprocess >> ./logs/timeseries.`date +%Y%m%d-%H%M%S`

EOF

# qsubcasper ./timeseries
qsubcasper -q casper -l walltime=02:00:00 -A NCGD0047 ./timeseries

end             # member loop
end             # member loop
end             # member loop

exit
