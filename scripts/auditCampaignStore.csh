#!/bin/csh 
### set env variables
module load ncl nco

setenv CESM2_TOOLS_ROOT /glade/work/nanr/cesm_tags/CASE_tools/cesm2-smyle/
setenv TSERIES2  /glade/campaign/cesm/development/espwg/CESM2-SMYLE-AMIP/timeseries

# case name counter
set smbr =  01
set embr =  50


@ mb = $smbr
@ me = $embr

foreach mbr ( `seq $mb $me` )
set mbr_padZeros = `printf %02d $mbr`
set CASE = f.e21.FHIST_Obs_TPacAMIP_SSTSIC_2023.f09_f09_mg17.2023-11.1${mbr_padZeros}
set CASE = f.e21.FHIST_Obs_Tzonal_SSTSIC_1979cf.f09_f09_mg17.1979-11.1${mbr_padZeros}
set CASE = f.e21.FHIST_Obs_Tzonal_SSTSIC_2023.f09_f09_mg17.2023-11.1${mbr_padZeros}
set CASE = f.e21.FHIST_Obs_TIndAtlAMIP_SSTSIC_1979cf.f09_f09_mg17.1979-11.1${mbr_padZeros}
set CASE = f.e21.FHIST_Obs_TIndAtlAMIP_SSTSIC_2023.f09_f09_mg17.2023-11.1${mbr_padZeros}

#set CASE = f.e21.FHIST_Obs_TPacAMIP_SSTSIC_1979cf.f09_f09_mg17.1979-11.1${mbr_padZeros}
#set CASE = f.e21.FHIST_SMYLE_1979cntl.f09_f09_mg17.1979-11.${mbr_padZeros}
#set CASE = f.e21.FHIST_SMYLE_1979CF-Tropics.f09_f09_mg17.1979-11.${mbr_padZeros}
#set CASE = f.e21.FHIST_SMYLE_SSTv2-Tropics.f09_f09_mg17.2023-11.${mbr_padZeros}

#echo "==================================    " 
#echo $CASE 
if (-d $TSERIES2/$CASE) then
    cd $TSERIES2/$CASE
    #set t1 = `ls  $TSERIES2/$CASE/atm/proc/tseries/month_1/*ZM_CLUBB* | wc -l`
    set t2 = `ls -lR $TSERIES2/$CASE | wc -l`
    set s2 = `du . -sh`
    if ($t2 < 1425 ) then
       echo  $CASE " ==============    " $t2  $s2
    else
       echo  $CASE " ===    " $t2  $s2
    endif
else
    echo " missing   ===    " $CASE
endif

end             # member loop

exit

