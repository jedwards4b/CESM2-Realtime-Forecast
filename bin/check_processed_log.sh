#!/usr/bin/env sh
#=========================================================================================
# Purpose:
# Test whether post-processed SS forecast files are complete or not
#
# Method::
# Check the netCDF time dimension of post-processed forecast files to see if
# they have the expected (hard-coded) dimension size
# which (strongly?) suggests that the post-processed files are correct & complete
#
# Usage:
#    unix> check_processed_data.sh <YEAR> [--savelog]
#
#    echo to stdout all test failures
#    optional log file documents PASS/FAIL for all files tested
#
# Notes: 
# o processes only one year (otherwise log file is too large & takes too long)
# o loop over each subdir to shorten list of file returned by find command
# 
# History:
# o 2020 July, B. Kauffman, first version
#=========================================================================================

ROOTDIR="/glade/scratch/espstoch/cesm2cam6v2"    # ? should this be an arg?
ROOTDIR="$(pwd)"

#-------------------------------------------------------------------------------
# command line arg parsing (very fragile)
#-------------------------------------------------------------------------------


SAVELOG="FALSE"
if [[ $2 == *"--savelog"* ]]
then
   SAVELOG="TRUE"
fi

echo "ROOTDIR = $ROOTDIR"

#-------------------------------------------------------------------------------
# create file name for log file
#-------------------------------------------------------------------------------

LID="$(date +%y%m%d-%H%M%S)"
LOGFILE="$(pwd)/check_processed_log.out.$LID"

if [[ $SAVELOG == "TRUE" ]]
then
   echo "Saving all results to $LOGFILE"
   echo "$(date)" > $LOGFILE
   echo "$ROOTDIR" >> $LOGFILE
fi

#-------------------------------------------------------------------------------
# for all log files, count number of lines, count number of FAILs
#-------------------------------------------------------------------------------
 
for FILE in $( ls *.log.*  ) ; do

#  FILESTR="$( ls  $FILE)"
   nPASS="$( grep -ch PASS $FILE)"
   nFAIL="$( grep -ch FAIL $FILE)"
   echo "#PASS = $nPASS  #FAIL = $nFAIL 	$FILE"
done

exit
