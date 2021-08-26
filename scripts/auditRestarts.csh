#!/bin/csh
### set env variables
module load ncl nco

setenv CESM2_TOOLS_ROOT /glade/work/$USER/cesm_tags/CASE_tools/cesm2-smyle/
setenv ARCHDIR  /glade/scratch/$USER/SMYLE/archive/
setenv TSERIES  /glade/campaign/cesm/development/espwg/SMYLE/archive
setenv LOGSDIR  /glade/campaign/cesm/development/espwg/SMYLE/logs
setenv RESTDIR  /glade/campaign/cesm/development/espwg/SMYLE/restarts
setenv POPDDIR  /glade/campaign/cesm/development/espwg/SMYLE/popd

set syr = 1970
set eyr = 2018

@ ib = $syr
@ ie = $eyr

foreach year ( `seq $ib $ie` )
#foreach mon ( 02 05 08 11 )
foreach mon ( 05 )


# case name counter
set smbr =  1
set embr =  20

@ mb = $smbr
@ me = $embr

foreach mbr ( `seq $mb $me` )
if ($mbr < 10) then
        set CASE = b.e21.BSMYLE.f09_g17.${year}-${mon}.00${mbr}
else
        set CASE = b.e21.BSMYLE.f09_g17.${year}-${mon}.0${mbr}
endif

#echo 'Year   = ' $year
#echo 'Member = ' $mbr
#echo 'Case   = ' $CASE

echo " =========================="
echo "${year}-${mon}.0${mbr} "
if (-d $TSERIES/$CASE/cpl/hist/) then
  set cpfl = `ls -lR $TSERIES/$CASE/cpl/hist/ | wc | cut -d" " -f5-10`
  echo " found $cpfl cpl files"
else
  echo "     missing cpl "
endif

if (! -e $LOGSDIR/$CASE.logs.tar) then
  echo "     missing logs "
endif
if (! -e $RESTDIR/$CASE.rest.tar) then
  echo "     missing restarts "
endif
if (! -e $POPDDIR/$CASE.popd.tar) then
  echo "     missing popd "
endif

end             # member loop
end             # year loop
end             # year loop

exit

