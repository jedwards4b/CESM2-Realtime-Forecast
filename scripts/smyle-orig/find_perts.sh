#!/bin/bash

# example file: /glade/scratch/nanr/SMYLE/inputdata/cesm2_init//b.e21.SMYLE_IC.f09_g17.1959-11.01/pert.05/b.e21.SMYLE_IC.pert.f09_g17.cam.i.1959-11-01-00000.nc

inDir=/glade/scratch/nanr/SMYLE/inputdata/cesm2_init/
#outDir=/glade/work/sglanvil/CCR/SMYLE/
outDir=/glade/work/nanr/cesm_tags/CASE_tools/cesm2-smyle/cami-files/

for yearDir in $inDir/b.e21.SMYLE_IC.f09_g17.*; do
	year=$(sed -e 's/.*b\.e21\.SMYLE_IC\.f09_g17\.//' <<< $yearDir | sed -e 's/-.*//')
	echo $year

	for memberDir in $yearDir/pert.*; do
		member=$(sed -e 's/.*pert\.//' <<< $memberDir)
                fil=$memberDir/b.e21.SMYLE_IC.pert.f09_g17.cam.i.$year-11-01-00000.nc
		
		if test -f $fil; then
			dump=$(ncdump -h $fil)
			diffValue=$(sed -e 's/.*\.diff\.//' <<< $dump | sed -e 's/\.nc.*//')
			weightValue=$(sed -e 's/.*ncflint -O -C -v lat,lon,slat,slon,lev,ilev,hyai,hybi,hyam,hybm,US,VS,T,Q,PS -w //' <<< $dump | sed -e 's/,1.0 \/glade\/campaign.*//')
			if (( $(echo "$weightValue < 0" |bc -l) )); then
				echo "$member $diffValue -"
			fi
			if  (( $(echo "$weightValue > 0" |bc -l) )); then
				echo "$member $diffValue +"
			fi
		else
			echo "file does not exist"
		fi

	done
        echo "-----------------------------------------------"
done

# ncdump -h $fil | grep ncflint
# ncdump -h $fil | grep ncdiff  

