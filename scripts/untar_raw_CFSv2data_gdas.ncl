load "./ss_extract.ncl"

begin

;yrs = (/"1979","1980","1981","1982","1983","1984","1985","1986","1987","1988"/)
;yrs = (/"1980","1981","1982","1983","1984","1985","1986","1987","1988","1989","1990",\
;        "1991","1992","1993","1994","1995","1996","1997","1998","1999","2000","2001","2002",\
;yrs = (/"1990","1991","1992","1993","1994","1995","1996","1997","1998","1999","2000","2001","2002",\
;        "2003","2004","2005","2006","2007","2008","2009","2010"/)
;yrs = (/"2001","2002","2003","2004","2005","2006","2007","2008","2009","2010"/)
yrs = (/"2011"/) ; has both cdas and gdas files
;yrs = (/"1987","1988","1989"/)
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

tarfns = systemfunc("ls "+path+"flxf06.gdas.*.tar")

ntf = dimsizes(tarfns)

; untar original files and rename to keep date information

do itf = 0, ntf-1

 print("tar -xvf "+tarfns(itf))
 system("tar -xvf "+tarfns(itf))

end do

 delete(tarfns)


fns = systemfunc("ls flxf06.gdas."+yrs(iyr)+"*.grb2")

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

 finit = (/"00","06","12","18"/)

 indx = ind(hr.eq.finit)

  ofn = "flxf06.gdas."+yr+mo+dy+hr+".grb2"
  nfn = "gdas."+yr+mo+dy+hr+".sfluxgrbl06_V2.grib2" 

  print("mv "+ofn+" "+npath+nfn)
  system("mv "+ofn+" "+npath+nfn)


end do

 delete(fns)

end do ; year loop


end
