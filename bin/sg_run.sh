#!/bin/bash
set -e

#while read idate; do
for idate in $(cat sg_dates); do
	echo "$idate"
#	python sg_postprocess.py --date $idate --member -1 --model 70Lwaccm6
	python sg_postprocess.py --date $idate --member 5 --model cesm2cam6
#done < sg_dates
done

