#!/bin/bash

timeseriesDirGLADE='/glade/scratch/sglanvil/SMYLE/timeseries'
archiveDirCS='/glade/campaign/cesm/development/espwg/SMYLE/archive'

for caseSourcePath in $timeseriesDirGLADE/b.e21.BSMYLE.f09_g17*; do
	caseName=$(echo $caseSourcePath | sed -e 's/.*\/timeseries\///')
	caseDestPath=$(echo $archiveDirCS/$caseName)
	echo $caseSourcePath
	echo $caseDestPath
	echo 
	mkdir -p $caseDestPath
	rsync --dry-run -avz --no-perms --no-owner --no-group --no-times --size-only $caseSourcePath/ $caseDestPath
done


