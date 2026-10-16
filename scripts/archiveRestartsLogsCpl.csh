#!/bin/csh -fx
### set env variables
module load ncl nco

setenv CESM2_TOOLS_ROOT /glade/work/$USER/cesm_tags/CASE_tools/cesm2-smyle-AMIP/
setenv TSERIES  /glade/campaign/cesm/development/espwg/CESM2-SMYLE-AMIP/timeseries
setenv LOGSDIR  /glade/campaign/cesm/development/espwg/CESM2-SMYLE-AMIP/logs
setenv RESTDIR  /glade/campaign/cesm/development/espwg/CESM2-SMYLE-AMIP/restarts
setenv POPDDIR  /glade/campaign/cesm/development/espwg/CESM2-SMYLE-AMIP/popd

#set syr = 1979
#set eyr = 1979
#set syr = 2023
#set eyr = 2023
set syr = 2023
set eyr = 2023

setenv ARCHNANR  /glade/derecho/scratch/$USER/SMYLE-AMIP/archive/

@ ib = $syr
@ ie = $eyr

#foreach mon ( 02 05 08 11 )
foreach mon ( 11 )
#foreach mon ( 05 )


# case name counter
set smbr =  1
set embr =  50

@ mb = $smbr
@ me = $embr

foreach mbr ( `seq $mb $me` )
set mbr_padZeros = `printf %02d $mbr`

   #set CASE = f.e21.FHIST_Obs_TropicalAMIP_SSTSIC_2023.f09_f09_mg17.2023-11.1${mbr_padZeros}
   set CASE = f.e21.FHIST_Obs_TPacAMIP_SSTSIC_2023.f09_f09_mg17.2023-11.1${mbr_padZeros}
   set CASE = f.e21.FHIST_Obs_TPacAMIP_SSTSIC_1979cf.f09_f09_mg17.1979-11.1${mbr_padZeros}
   set CASE = f.e21.FHIST_Obs_TIndAtlAMIP_SSTSIC_2023.f09_f09_mg17.2023-11.1${mbr_padZeros}
   set CASE = f.e21.FHIST_Obs_Tzonal_SSTSIC_2023.f09_f09_mg17.2023-11.1${mbr_padZeros}
   set CASE = f.e21.FHIST_Obs_Tzonal_SSTSIC_1979cf.f09_f09_mg17.1979-11.1${mbr_padZeros}
   set CASE = f.e21.FHIST_Obs_TIndAtlAMIP_SSTSIC_1979cf.f09_f09_mg17.1979-11.1${mbr_padZeros}
   set CASE = f.e21.FHIST_Obs_Trelative_SSTSIC_1979cf.f09_f09_mg17.1979-11.1${mbr_padZeros}
   set CASE = f.e21.FHIST_Obs_Trelative_SSTSIC_2023.f09_f09_mg17.2023-11.1${mbr_padZeros}

   set USE_ARCHDIR = $ARCHNANR

if (! -d $TSERIES/$CASE/cpl/hist) then
	mkdir -p $TSERIES/$CASE/cpl/hist
else
   cp $USE_ARCHDIR/$CASE/cpl/hist/* $TSERIES/$CASE/cpl/hist/
   echo "cpl done"
endif
if (! -e $LOGSDIR/$CASE.logs.tar) then
   cd $USE_ARCHDIR
   tar -cvf $LOGSDIR/$CASE.logs.tar $CASE/logs/*.gz
else
   echo "logs done"
endif
#if (! -e $RESTDIR/$CASE.rest.tar) then
   #cd $USE_ARCHDIR
   #tar -cvf $RESTDIR/$CASE.rest.tar $CASE/rest/
#else
   #echo "rest done"
#endif
#if (! -e $POPDDIR/$CASE.popd.tar) then
   #cd $USE_ARCHDIR
   #tar -cvf $POPDDIR/$CASE.popd.tar $CASE/ocn/hist/*.pop.d*
#else
   #echo "popd done"
#endif

end             # mon loop
end             # member loop

exit

