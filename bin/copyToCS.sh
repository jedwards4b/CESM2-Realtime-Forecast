#!/usr/bin/env bash 
source ~/.bash_profile

# ----------------- original archive directory ----------------- 
landSource=/glade/scratch/ssfcst/archive/I2000Clm50BgcCrop.002runRealtime/rest/
sdSource=/glade/scratch/ssfcst/archive/b.e21.BWHIST.SD.f09_g17.002.nudgedOcn/rest/

# ----------------- campaign storage ----------------- 
landDest=/glade/campaign/cesm/development/cross-wg/S2S/land/rest/
sdDest=/glade/campaign/cesm/development/cross-wg/S2S/SDnudgedOcn/rest/

echo "......................begin rsync..................."

latestFile=$(ls $sdSource | sort -V | tail -n 1)
rsync -av $sdSource/$latestFile casper.ucar.edu:$sdDest/

for daysBack in {7..1}; do
	latestFile=$(ls $landSource | sort -V | tail -n $daysBack | head -n 1)
	echo $latestFile
	rsync -av $landSource/$latestFile casper.ucar.edu:$landDest/
done

echo ".........................done......................."


