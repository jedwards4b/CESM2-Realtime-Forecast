#! /bin/csh -fxv 

#foreach  year ( 1954 1964 1974 1984 1994 2004 )
set syr = 1959
set eyr = 1970
#set syr = 2007
#set eyr = 2007

@ ib = $syr
@ ie = $eyr

foreach year ( `seq $ib $ie` )
#foreach mon ( 02 05 08 11 )
#foreach mon ( 05 08 11 )
foreach mon ( 11 )

set case = b.e21.SMYLE_IC.f09_g17.${year}-${mon}.01
#set icdir = /glade/p/cesm/cseg/inputdata/ccsm4_init/{$case} 
set Picdir = /glade/scratch/nanr/SMYLE/inputdata/cesm2_init/{$case}/
set icdir  = /glade/scratch/nanr/SMYLE/inputdata/cesm2_init/{$case}/${year}-${mon}-01
if (! -d ${Picdir}) then
 mkdir ${Picdir}
endif
if (! -d ${icdir}) then
 mkdir ${icdir}
endif

# atm, lnd initial conditions
set atmcase =  JRA55_0.9x1.25_L32
set lndcase =  smyle_Transient

# names
set atmfname = ${atmcase}.cam2.i.${year}-${mon}-01-00000.nc
set lndfname = ${lndcase}.clm2.r.${year}-${mon}-01-00000.nc
set roffname = ${lndcase}.mosart.r.${year}-${mon}-01-00000.nc

# directories
set atmdir = /glade/p/cesm/espwg/CESM2-SMYLE/initial_conditions/cam/
set lnddir = /glade/p/cesm/espwg/CESM2-SMYLE/initial_conditions/clm/${year}-${mon}-01-00000/

# rename atm, land IC files
set atmfout = ${case}.cam.i.${year}-${mon}-01-00000.nc
set lndfout = ${case}.clm2.r.${year}-${mon}-01-00000.nc
set roffout = ${case}.mosart.r.${year}-${mon}-01-00000.nc

echo $atmfout

set doThis = 1

if ($doThis == 1) then
cp $atmdir/${atmfname} $icdir/$atmfout
cp $lnddir/${lndfname} $icdir/$lndfout
cp $lnddir/${roffname} $icdir/$roffout
ncatted -a OriginalFile,global,a,c,$atmfname $icdir/$atmfout
ncatted -a OriginalFile,global,a,c,$lndfname $icdir/$lndfout
ncatted -a OriginalFile,global,a,c,$roffname $icdir/$roffout

endif

# ocn/ice
# years used for ICs:   0306 (1958) - 0366 (2018)
set ocncase = g.e22.GOMIPECOIAF_JRA-1p4-2018.TL319_g17.SMYLE.005
set first_rest_year = 1958
set ocean_base_year = 306


# Comment:  year translation:  if ($year == 2018 ) set ocnyr = 0366
# years used for ICs:   0306 (1958) - 0366 (2018)
# atmyr 1958 = ocnyr 306
@ offset = $first_rest_year - $ocean_base_year 
@ ocnyr   = $year - $offset
set ocndir = /glade/p/cesm/espwg/CESM2-SMYLE/initial_conditions/pop_cice/0${ocnyr}-${mon}-01-00000/
set icefout = ${case}.cice.r.${year}-${mon}-01-00000.nc
set lndfout = ${case}.clm2.r.${year}-${mon}-01-00000.nc
set roffout = ${case}.mosart.r.${year}-${mon}-01-00000.nc

set icefname   = ${ocncase}.cice.r.0${ocnyr}-${mon}-01-00000.nc 
set poprfname  = ${ocncase}.pop.r.0${ocnyr}-${mon}-01-00000.nc  
set poprofname = ${ocncase}.pop.ro.0${ocnyr}-${mon}-01-00000    
set poprhfname = ${ocncase}.pop.rh.ecosys.nyear1.0${ocnyr}-${mon}-01-00000.nc 
set popwwfname = ${ocncase}.ww3.r.0${ocnyr}-${mon}-01-00000    

set poprfout  = ${case}.pop.r.${year}-${mon}-01-00000.nc
set poprofout = ${case}.pop.ro.${year}-${mon}-01-00000 
set poprhfout = ${case}.pop.rh.ecosys.nyear1.${year}-${mon}-01-00000.nc
set popwwfout = ${case}.ww3.r.${year}-${mon}-01-00000

echo $icefname
echo $poprfname

set doThis2 = 1
if ($doThis2 == 1) then

cp $ocndir/${icefname}    $icdir/${icefout}
cp $ocndir/${poprfname}   $icdir/${poprfout}
cp $ocndir/${poprofname}  $icdir/${poprofout}
cp $ocndir/${poprhfname}  $icdir/${poprhfout}
cp $ocndir/${popwwfname}  $icdir/${popwwfout}

ncatted -a OriginalFile,global,a,c,$icefname    $icdir/$icefout
ncatted -a OriginalFile,global,a,c,$poprfname   $icdir/$poprfout
ncatted -a OriginalFile,global,a,c,$poprofname  $icdir/$poprofout
ncatted -a OriginalFile,global,a,c,$poprhfname  $icdir/$poprhfout

# create rpointer files

echo "$case.cice.r.$year-${mon}-01-00000.nc"  > ${icdir}/rpointer.ice
echo "./$case.pop.ro.$year-${mon}-01-00000"   > ${icdir}/rpointer.ocn.ovf
echo "$case.cam.r.$year-${mon}-01-00000.nc"   > ${icdir}/rpointer.atm
echo "$case.cpl.r.$year-${mon}-01-00000.nc"   > ${icdir}/rpointer.drv
echo "$case.clm2.r.$year-${mon}-01-00000.nc"  > ${icdir}/rpointer.clm
echo "$case.mosart.r.$year-${mon}-01-00000.nc"   > ${icdir}/rpointer.rof
echo "$case.pop.rh.ecosys.nyear1.$year-${mon}-01-00000.nc"   > ${icdir}/rpointer.ocn.tavg.5
echo "$case.pop.rh.$year-${mon}-01-00000.nc"   > ${icdir}/rpointer.ocn.tavg

echo "./$case.pop.r.$year-${mon}-01-00000.nc"    >> ${icdir}/rpointer.ocn.restart
echo "RESTART_FMT=nc"                          >> ${icdir}/rpointer.ocn.restart

endif	# doThis2

#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

end
end

exit
 
 


