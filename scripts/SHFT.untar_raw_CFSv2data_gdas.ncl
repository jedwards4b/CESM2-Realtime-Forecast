load "./ss_extract.ncl"

begin

;yrs = (/"1979","1980","1981","1982","1983","1984","1985","1986","1987","1988","1989","1990",\
;yrs = (/"1982","1983","1984","1985","1986","1987","1988","1989","1990",\
;        "1991","1992","1993","1994","1995","1996","1997","1998","1999","2000","2001","2002",\
;        "2003","2004","2005","2006","2007","2008","2009","2010"/)
;yrs = (/"2011"/) ; has both cdas and gdas files
yrs = (/"1989"/)
;yrs = (/"1980","1981"/)
nyr = dimsizes(yrs)
nmo = 12
;nmo = 3

do iyr = 0, nyr-1

; original tar file names on NCEP RDA archive

; to do == set up to do flag check on gdas vs cdas file for pre april 2011 
; flxl01.gdas.<daterange>.tar with 5 days per tar ball

if(yrs(iyr).eq."2011")then
 nmo = 3
 ;cdas path
  path = "/glade/collections/rda/data/ds094.0/"+yrs(iyr)+"/"
  intyr = tointeger(yrs(iyr))
  pyr = tostring(intyr-1)
  ppath = "/glade/collections/rda/data/ds093.0/"+pyr+"/"
else
 nmo = 12
 ;gdas path
  path = "/glade/collections/rda/data/ds093.0/"+yrs(iyr)+"/"
  intyr = tointeger(yrs(iyr))
  pyr = tostring(intyr-1)
  ppath = "/glade/collections/rda/data/ds093.0/"+pyr+"/"
end if

tarfns = systemfunc("ls "+path+"flxl06.gdas.*.tar")

ntf = dimsizes(tarfns)

; untar original files and rename to keep date information

do itf = 0, ntf-1

 print("tar -xvf "+tarfns(itf))
 system("tar -xvf "+tarfns(itf))

end do

 delete(tarfns)

;system("rm flxl01.gdas.*06.grb2  flxl01.gdas.*12.grb2  flxl01.gdas.*18.grb2")
fns = systemfunc("ls flxl06.gdas."+yrs(iyr)+"*.grb2")
print(fns)
nf = dimsizes(fns)

do k = 0, nf-1
 yr = ss_extract(fns(k),13,16)
 mo = ss_extract(fns(k),17,18)
 dy = ss_extract(fns(k),19,20)
 hr = ss_extract(fns(k),21,22)

 fdate = ss_extract(fns(k),13,22)

print(yr)
print(mo)
print(dy)
print(hr)

 npath = "./data_files/"

 finit = (/"18","00","06","12"/)
 fval  = (/"00","06","12","18"/)
 sday = (/"01","02","03","04","05","06","07","08","09","10","11","12","13",\
          "14","15","16","17","18","19","20","21","22","23","24","25","26",\
          "27","28","29","30","31"/)

if((yr.eq."1979").and.(mo.eq."01").and.(dy.eq."01"))then

 print("repeat day 2 for jan 1,2 1979 ONLY")
 ; hardcoded ofns to day 2 for 0,6,12,18z and cp to day 1 
 intdy = tointeger(dy)
 fdy = sday(intdy) ; day plus one
 print("should be 2")
 print(fdy)

 indx = ind(hr.eq.fval)
 print(indx)

 if(indx.eq.0)then
  ofn = "flxl06.gdas."+yr+mo+dy+finit(indx)+".grb2" ;day 1 18z init is 00z valid
  nfn = "gdas."+yr+mo+dy+fval(indx)+".sfluxgrbl06.grib2"

  print("cp "+ofn+" "+npath+nfn)
  system("cp "+ofn+" "+npath+nfn)
 else
  ofn = "flxl06.gdas."+yr+mo+fdy+finit(indx)+".grb2" 
  nfn = "gdas."+yr+mo+dy+fval(indx)+".sfluxgrbl06.grib2"

  print("cp "+ofn+" "+npath+nfn)
  system("cp "+ofn+" "+npath+nfn)
 end if

else if((yr.ne."1979").and.(mo.eq."01").and.(dy.eq."01"))then
 print("JAN 1 day 1. need previous year info.")

 indx = ind(hr.eq.fval)
 if(indx.eq.0)then

  ;untar last few days of previous year (these are removed in yr loop otherwise)

  print("tar -xvf "+ppath+"flxl06.gdas."+pyr+"1226-"+pyr+"1231.tar")
  system("tar -xvf "+ppath+"flxl06.gdas."+pyr+"1226-"+pyr+"1231.tar")
 
  ofn = "flxl06.gdas."+pyr+"1231"+finit(indx)+".grb2"
  nfn = "gdas."+yr+mo+dy+fval(indx)+".sfluxgrbl06.grib2" 

  print("mv "+ofn+" "+npath+nfn)
  system("mv "+ofn+" "+npath+nfn)

 else

 ; doing 6,12,and 18z valid times 

  ofn = "flxl06.gdas."+yr+mo+dy+finit(indx)+".grb2"
  nfn = "gdas."+yr+mo+dy+fval(indx)+".sfluxgrbl06.grib2" 

  print("mv "+ofn+" "+npath+nfn)
  system("mv "+ofn+" "+npath+nfn)

 end if

else if((mo.ne."01").and.(dy.eq."01"))then

 print("day 1 of month other than jan. need info from previous month.")

 pmo = (/"01","02","03","04","5","06","07","08","09","10","11","12"/)
 ndpm = (/"31","28","31","30","31","30","31","31","30","31","30","31"/)
 indpmo = tointeger(mo)-2

 indx = ind(hr.eq.fval)

 if(indx.eq.0)then

  ofn = "flxl06.gdas."+yr+pmo(indpmo)+ndpm(indpmo)+finit(indx)+".grb2"
  nfn = "gdas."+yr+mo+dy+fval(indx)+".sfluxgrbl06.grib2" 

  print("mv "+ofn+" "+npath+nfn)
  system("mv "+ofn+" "+npath+nfn)
 
 else

  print("hours 6,12,18 of day 1 of new month")
  ofn = "flxl06.gdas."+yr+mo+dy+finit(indx)+".grb2"
  nfn = "gdas."+yr+mo+dy+fval(indx)+".sfluxgrbl06.grib2" 

  print("mv "+ofn+" "+npath+nfn)
  system("mv "+ofn+" "+npath+nfn)

 end if

else

 print("rest of the days")

 sday = (/"01","02","03","04","05","06","07","08","09","10","11","12","13",\
          "14","15","16","17","18","19","20","21","22","23","24","25","26",\
          "27","28","29","30","31"/)

 indx = ind(hr.eq.fval)

 dindx = tointeger(dy)
 pdy = sday(dindx-2)
 print(dy)
 print(pdy)

 if(indx.eq.0)then

  ofn = "flxl06.gdas."+yr+mo+pdy+finit(indx)+".grb2"
  nfn = "gdas."+yr+mo+dy+fval(indx)+".sfluxgrbl06.grib2" 

  print("mv "+ofn+" "+npath+nfn)
  system("mv "+ofn+" "+npath+nfn)

 else
 ; do the other 3 time steps of the day

   print("hours 6,12,18 of rest of days in month")
   ofn = "flxl06.gdas."+yr+mo+dy+finit(indx)+".grb2"
   nfn = "gdas."+yr+mo+dy+fval(indx)+".sfluxgrbl06.grib2" 

   print("mv "+ofn+" "+npath+nfn)
   system("mv "+ofn+" "+npath+nfn)

 end if

end if
end if
end if

end do

 delete(fns)

end do ; year loop


end
