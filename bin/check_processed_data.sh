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

YEAR=$1

SAVELOG="FALSE"
if [[ $2 == *"--savelog"* ]]
then
   SAVELOG="TRUE"
fi

echo "ROOTDIR = $ROOTDIR"
echo "YEAR = $YEAR" 

#-------------------------------------------------------------------------------
# create file name for log file
#-------------------------------------------------------------------------------

LID="$(date +%y%m%d-%H%M%S)"
LOGFILE="$(pwd)/check_processed_data.$YEAR.log.$LID"

if [[ $SAVELOG == "TRUE" ]]
then
   echo "Saving all results to $LOGFILE"
   echo "$(date)" > $LOGFILE
   echo "$ROOTDIR" >> $LOGFILE
   echo "YEAR = $YEAR" >> $LOGFILE
fi

#-------------------------------------------------------------------------------
# hard-coded ncdump -h output required to PASS the test
#-------------------------------------------------------------------------------
TIMESTR_DEF="time = UNLIMITED ; // (46 currently)"  # default value
TIMESTR_ICE="time = UNLIMITED ; // (45 currently)"
TIMESTR_OCN="time = UNLIMITED ; // (45 currently)"
TIMESTR_6HR="time = UNLIMITED ; // (181 currently)"

#-------------------------------------------------------------------------------
# loop over files & check
#-------------------------------------------------------------------------------
cd $ROOTDIR

for SUBDIR  in ./* ; do

   PASSSTR=$TIMESTR_DEF # default
   if [[ $SUBDIR == "./6hourly" ]]
   then
      PASSSTR=$TIMESTR_6HR
   fi
   if [[ $SUBDIR == "./ice" ]]
   then
      PASSSTR=$TIMESTR_ICE
   fi
   if [[ $SUBDIR == "./ocn" ]]
   then
      PASSSTR=$TIMESTR_OCN
   fi
 
   for FILE in $(find $SUBDIR -name *$YEAR*.nc | sort) ; do

      FILESTR="$( ls -o    $FILE)"
      TIMESTR="$(ncdump -h $FILE | grep UNLIMITED) " 
   
      PASSFAIL="FAIL"
      if [[ $TIMESTR == *"$PASSSTR"* ]]
      then
         PASSFAIL="PASS"
      fi

      #--- echo only failures to stdout ---
      if [[ $PASSFAIL == "FAIL" ]]
      then
         echo "$FILESTR $TIMESTR $PASSFAIL"
      fi
      #--- but save all pass/fail info to log file, if requested ---
      if [[ $SAVELOG == "TRUE" ]]
      then
         echo "$FILESTR $TIMESTR $PASSFAIL" >> $LOGFILE
      fi
   done
done

echo "$(date)" 
if [[ $SAVELOG == "TRUE" ]]
then
   echo "$(date)" >> $LOGFILE
fi

exit
