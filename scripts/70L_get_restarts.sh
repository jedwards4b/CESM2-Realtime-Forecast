#!/usr/bin/env sh

date=1999-01-04

SDrestDir=/glade/scratch/sglanvil/S2S_70LIC_globus/SD/rest/$date/
mkdir -p $SDrestDir
landRestDir=/glade/scratch/sglanvil/S2S_70LIC_globus/LAND/rest/$date/
mkdir -p $landRestDir

module load python
ncar_pylib
# endpoint IDs (NOTE: make sure these don't expire!!)
campstore=6b5ab960-7bbf-11e8-9450-0a6d4e044368
glade=d33b3614-6d04-11e5-ba46-22000b92c6ec

task_id="$(globus transfer ${campstore}:/gpfs/csfs1/cesm/development/cross-wg/S2S/SD/rest/${date}-00000/ ${glade}:${SDrestDir} --jmespath 'task_id' --format=UNIX --recursive)"
echo "Waiting on 'globus transfer' task '$task_id'"
globus task wait "$task_id" --timeout 120
if [ $? -eq 0 ]; then
    echo "$task_id completed successfully";
else
    echo "$task_id failed!";
fi

task_id="$(globus transfer ${campstore}:/gpfs/csfs1/cesm/development/cross-wg/S2S/land/rest/${date}-00000/ ${glade}:${landRestDir} --jmespath 'task_id' --format=UNIX --recursive)"
echo "Waiting on 'globus transfer' task '$task_id'"
globus task wait "$task_id" --timeout 120
if [ $? -eq 0 ]; then
    echo "$task_id completed successfully";
else
    echo "$task_id failed!";
fi

deactivate

rename I2000Clm50BgcCrop.002run b.e21.BWHIST.SD.f09_g17.002 $landRestDir* # give land same case name as SD
cp $landRestDir*nc $SDrestDir # copy those land files (no rpointers) to SD dir
