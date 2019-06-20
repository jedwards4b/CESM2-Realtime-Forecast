load "./ss_extract.ncl"

begin

npath = "./data_files/"

;iy = ispan(1979,2018,1)
;iy = ispan(1983,2018,1)
;iy = ispan(1985,1985,1)
;iy = ispan(1994,1994,1)
;iy = ispan(2011,2018,1)
iy = 2018
;print(iy)

yr = tostring(iy)

;yr = (/"2012","2013","2014","2015","2016","2017","2018"/)
nyr = dimsizes(yr)

;mo = (/"01","02","03","04","05","06","07","08","09","10","11","12"/)
;nmo = dimsizes(mo)
;ndpm = (/31,28,31,30,31,30,31,31,30,31,30,31/) ; no leap

;mo = (/"02","03","04","05","06","07","08","09","10","11","12"/)
;nmo = dimsizes(mo)
;ndpm = (/28,31,30,31,30,31,31,30,31,30,31/) ; no leap

mo = (/"10","11","12"/)
nmo = dimsizes(mo)
ndpm = (/31,30,31/) ; no leap

;mo = (/"01","02","03","04","05"/)
;nmo = dimsizes(mo)
;ndpm = (/31,28,31,30,20/) ; SPECIAL NOTE... only goes up to yesterday

;mo = (/"07"/)
;nmo = dimsizes(mo)
;ndpm = (/31/) ; no leap

;mo = (/"07","08"/)
;nmo = dimsizes(mo)
;ndpm = (/31,31/) ; no leap
nhr = 4

; list untarred filenames and process each yr, mo at a time

do iyr = 0, nyr-1
 do imo = 0, nmo-1

; fns = systemfunc("ls "+npath+"*das*."+yr(iyr)+mo(imo)+"*.sfluxgrbl06_V2.grib2")
 fns = systemfunc("ls "+npath+"*das*."+yr(iyr)+mo(imo)+"*.sfluxgrbf06.grib2")
; print(fns)
 nf = dimsizes(fns)

 data = addfiles(fns,"r")
 ListSetType(data,"join")
 nms = getfilevarnames(data[0])
; print(nms)


; invars = (/"DSWRF_P8_L1_GGA0_avg","PRATE_P8_L1_GGA0_avg","DLWRF_P8_L1_GGA0_avg","PRES_P0_L1_GGA0","TMP_P0_L105_GGA0","SPFH_P0_L105_GGA0","UGRD_P0_L105_GGA0","VGRD_P0_L105_GGA0"/)

  invars = (/"DSWRF_P8_L1_GGA0_avg","PRATE_P8_L1_GGA0_avg","DLWRF_P8_L1_GGA0_avg","PRES_P0_L1_GGA0","TMP_P0_L105_GGA0","SPFH_P0_L105_GGA0","UGRD_P0_L105_GGA0"/)

 vnames = (/"FSDS","PRECTmms","FLDS","PSRF","TBOT","QBOT","WIND"/)

 nvars = dimsizes(invars)
 stream = (/"Solar","Precip","TPQWL"/)


;------------------------------------------------------------------------------
; naming convention for land files is 
; clmforc.<product>.cYYYY.resxres.<stream>.YYYY-MM.nc
; where cYYYY is the creation year, and YYYY-MM is the data year and month
; resxres is the resolution, product is CRUNCEP or NCEPCFSv2 etc and the stream
; is either TPQWL, Precip, or Solar.
;------------------------------------------------------------------------------

 nfd = "./forcing_files/"
; nfpre = "clmforc.NCEPCFSv2.c2019.T62.94x192."
 nfpre = "clmforc.NCEPCFSv2.c2019.0.2d.576x1152."

; begin with first of 3 streams

do ivar = 0, nvars-1
 if(ivar.le.2)then
  strm = stream(ivar)
 end if

; print(strm)

if(strm.eq."Solar")then
 tunits = "days since "+yr(iyr)+"-"+mo(imo)+"-01 00:00:00"

 hr = (/0,6,12,18/)
 time = new( (/ndpm(imo)*nhr/), "float")
 date = new( (/ndpm(imo)*nhr/), "integer")
 day = new( (/ndpm(imo)*nhr/), "integer")
  hcnt = 0
  inc = 0
 do idy = 0, ndpm(imo)*nhr-1
  date(idy) = ((((tointeger(yr(iyr)+mo(imo)))*100)+inc)*100)+hcnt
  if(hcnt.eq.0)then ; each time we hit a new day
   inc = inc + 1
   day(idy:idy+3) = inc ; fill 4 time steps with same day number
  end if

  time(idy) = tofloat(cd_inv_calendar(tointeger(yr(iyr)),tointeger(mo(imo)),day(idy),1.0*hcnt,0.,0.,tunits,0))
 if(hcnt.eq.18)then
  hcnt = 0
 else
  hcnt = hcnt + 6
 end if

 end do 

 time@long_name = "observation time"
 time@units = tunits 
 time@calendar = "noleap"
 delete(time@_FillValue)

 time!0 = "time"
 time&time = time
else
 tunits = "days since "+yr(iyr)+"-"+mo(imo)+"-01 00:00:00"

 hr = (/3,9,15,21/)

 time = new( (/ndpm(imo)*nhr/), "float")
 date = new( (/ndpm(imo)*nhr/), "integer")
 day = new( (/ndpm(imo)*nhr/), "integer")

  hcnt = 3
  inc = 0
 do idy = 0, ndpm(imo)*nhr-1
  date(idy) = ((((tointeger(yr(iyr)+mo(imo)))*100)+inc)*100)+hcnt
  if(hcnt.eq.3)then ; each time we hit a new day
   inc = inc + 1
   day(idy:idy+3) = inc ; fill 4 time steps with same day number
  end if

  time(idy) = tofloat(cd_inv_calendar(tointeger(yr(iyr)),tointeger(mo(imo)),day(idy),1.0*hcnt,0.,0.,tunits,0))

; print(time(idy))

 if(hcnt.eq.21)then
  hcnt = 3
 else
  hcnt = hcnt + 6
 end if

 end do 

 time@long_name = "observation time"
 time@units = tunits 
 time@calendar = "noleap"
 delete(time@_FillValue)

 time!0 = "time"
 time&time = time

end if


 arrin = data[:]->$invars(ivar)$(0:(ndpm(imo)*nhr)-1,::-1,:)
 delete_VarAtts(arrin,-1)
 

; variables and attributes for all streams

if(yr(iyr).lt."2011")then

 arr = arrin

 latin = data[0]->lat_0(::-1)
 lonin = data[0]->lon_0
 delete_VarAtts(latin,-1)
 delete_VarAtts(lonin,-1)

else
; beginning in 2011, grid changes to higher res. read in desired lat, lon 
; for regridding
 fnd = "dims.nc"
 datd = addfile(fnd,"r")
 latin = datd->lat
 lonin = datd->lon
 nlat = dimsizes(latin)
 nlon = dimsizes(lonin)

 delete_VarAtts(latin,-1)
 delete_VarAtts(lonin,-1)

 arr = f2fsh(arrin,(/nlat,nlon/))

end if

; latin!0 = "lat"
; lonin!0 = "lon"

 nlat = dimsizes(latin)
 nlon = dimsizes(lonin)
 LATIXY = new( (/nlat,nlon/), "float")
 LONGXY = new( (/nlat,nlon/), "float")

 do il = 0,nlon-1
   LATIXY(:,il)= tofloat(latin)
 end do
 do il = 0, nlat-1
   LONGXY(il,:) = tofloat(lonin)
 end do

 LATIXY!0 = "lat"
 LATIXY!1 = "lon"

; LATIXY&lat = latin
; LATIXY&lon = lonin

 LATIXY&lat = LATIXY(:,0)
 LATIXY&lon = LATIXY(0,:)

 LONGXY!0 = "lat"
 LONGXY!1 = "lon"

 LONGXY&lat = LONGXY(:,0)
 LONGXY&lon = LONGXY(0,:)

; LONGXY&lat = latin
; LONGXY&lon = lonin

 LATIXY@long_name = "latitude"
 LATIXY@units = "degrees_north"
 LATIXY@mode = "time-invariant"

 LONGXY@long_name = "longitude"
 LONGXY@units = "degrees_east"
 LONGXY@mode = "time-invariant"

 delete(LATIXY@_FillValue)
 delete(LONGXY@_FillValue)

 edgee = 360.
 edgew = 0.
 edges = -90.
 edgen = 90.

 edgee!0 = "scalar"
 edgew!0 = "scalar"
 edges!0 = "scalar"
 edgen!0 = "scalar"


 edgee@long_name = "eastern edge in atmospheric data"
 edgee@units = "degrees_east"
 edgee@mode = "time-invariant"

 edgew@long_name = "western edge in atmospheric data"
 edgew@units = "degrees_east"
 edgew@mode = "time-invariant"

 edges@long_name = "southern edge in atmospheric data"
 edges@units = "degrees_north"
 edges@mode = "time-invariant"

 edgen@long_name = "northern edge in atmospheric data"
 edgen@units = "degrees_north"
 edgen@mode = "time-invariant"

 if(strm.eq."Solar")then

  nfn = nfd+nfpre+strm+"."+yr(iyr)+"-"+mo(imo)+".nc"
;  nfn = nfd+nfpre+strm+"."+yr(iyr)+"-"+mo(imo)+"v2.nc"
  print("creating "+nfn)

  system("rm "+nfn)
  cdf = addfile(nfn,"c")

; file global attributes

 globalAtt = True
 globalAtt@case_title = "NCEP CFSv2 6_Hourly Atmospheric Forcing: Incoming Solar"


  filedimdef(cdf,(/"time","lat","lon","scalar"/),\ 
                 (/-1,nlat,nlon,1/), \
                 (/True,False,False,False/) )
  filevardef(cdf,"time","float",(/"time"/))
;  filevardef(cdf,"lat","float",(/"lat"/))
;  filevardef(cdf,"lon","float",(/"lon"/))
  filevardef(cdf,"LATIXY","float",(/"lat","lon"/))
  filevardef(cdf,"LONGXY","float",(/"lat","lon"/))
  filevardef(cdf,"EDGEE","float",(/"scalar"/))
  filevardef(cdf,"EDGEW","float",(/"scalar"/))
  filevardef(cdf,"EDGEN","float",(/"scalar"/))
  filevardef(cdf,"EDGES","float",(/"scalar"/))

  filevardef(cdf,"FSDS","float",(/"time","lat","lon"/))

; file and variable attributes set

  arr@long_name = "total incident solar radiation"
  arr@units = "W/m^2"
  arr@mode = "time-dependent"
  arr@_FillValue = 1.e+36
  arr@missing_value = 1.e+36

  arr!0 = "time"
  arr!1 = "lat"
  arr!2 = "lon"

  arr&time = time
;  arr&lat = latin
;  arr&lon = lonin

  arr&lat = LATIXY(:,0)
  arr&lon = LONGXY(0,:)

  cdf->time = time
;  cdf->lat = LATIXY(:,0)
;  cdf->lon = LONGXY(0,:)
  cdf->LATIXY = LATIXY
  cdf->LONGXY = LONGXY
  cdf->EDGEE = edgee
  cdf->EDGEW = edgew
  cdf->EDGES = edges
  cdf->EDGEN = edgen

  arr = arr>0.0 ; make sure it's not negative after regrid

; print(min(arrin))
; print(max(arrin))
; print(min(arr))
; print(max(arr))
 
  cdf->FSDS = arr

 end if


 if(strm.eq."Precip")then
  nfn = nfd+nfpre+strm+"."+yr(iyr)+"-"+mo(imo)+".nc"
;  nfn = nfd+nfpre+strm+"."+yr(iyr)+"-"+mo(imo)+"v2.nc"
;  print(nfn)
  print("creating "+nfn)

  system("rm "+nfn)
  cdf = addfile(nfn,"c")

; file global attributes

 globalAtt = True
 globalAtt@case_title = "NCEP CFSv2 6_Hourly Atmospheric Forcing: Precipitation"


  filedimdef(cdf,(/"time","lat","lon","scalar"/),\ 
                 (/-1,nlat,nlon,1/), \
                 (/True,False,False,False/) )
  filevardef(cdf,"time","float",(/"time"/))
  filevardef(cdf,"LATIXY","float",(/"lat","lon"/))
  filevardef(cdf,"LONGXY","float",(/"lat","lon"/))
  filevardef(cdf,"EDGEE","float",(/"scalar"/))
  filevardef(cdf,"EDGEW","float",(/"scalar"/))
  filevardef(cdf,"EDGEN","float",(/"scalar"/))
  filevardef(cdf,"EDGES","float",(/"scalar"/))

  filevardef(cdf,"PRECTmms","float",(/"time","lat","lon"/))

; file and variable attributes set

  arr@long_name = "PRECTmms total precipitation"
  arr@units = "mm H2O / sec"
  arr@mode = "time-dependent"
  arr@_FillValue = 1.e+36
  arr@missing_value = 1.e+36

  arr!0 = "time"
  arr!1 = "lat"
  arr!2 = "lon"

  arr&time = time
  arr&lat = (/latin/)
  arr&lon = (/lonin/)


; arr = arr*1000. ; m/s to mm/s

;arr&lat = LATIXY(:,0)
;arr&lon = LONGXY(0,:)


  cdf->time = time
  cdf->lat = latin
  cdf->lon = lonin
  cdf->LATIXY = LATIXY
  cdf->LONGXY = LONGXY
  cdf->EDGEE = edgee
  cdf->EDGEW = edgew
  cdf->EDGES = edges
  cdf->EDGEN = edgen

  cdf->PRECTmms = arr

 end if

 if(strm.eq."TPQWL")then
  if(ivar.eq.2)then ; first time through loop define file and write coordinate vars
   nfn = nfd+nfpre+strm+"."+yr(iyr)+"-"+mo(imo)+".nc"
;   nfn = nfd+nfpre+strm+"."+yr(iyr)+"-"+mo(imo)+"v2.nc"
;   print(nfn)
  print("creating "+nfn)

   system("rm "+nfn)
   cdf = addfile(nfn,"c")

; file global attributes

  globalAtt = True
  globalAtt@case_title = "NCEP CFSv2 6_Hourly Atmospheric Forcing: Temperature, Pressure, Winds, Humidity, and Downward Longwave Radiation"


  filedimdef(cdf,(/"time","lat","lon","scalar"/),\ 
                 (/-1,nlat,nlon,1/), \
                 (/True,False,False,False/) )
  filevardef(cdf,"time","float",(/"time"/))
  filevardef(cdf,"LATIXY","float",(/"lat","lon"/))
  filevardef(cdf,"LONGXY","float",(/"lat","lon"/))
  filevardef(cdf,"EDGEE","float",(/"scalar"/))
  filevardef(cdf,"EDGEW","float",(/"scalar"/))
  filevardef(cdf,"EDGEN","float",(/"scalar"/))
  filevardef(cdf,"EDGES","float",(/"scalar"/))

  cdf->time = time
;  cdf->lat = latin
;  cdf->lon = lonin
  cdf->LATIXY = LATIXY
  cdf->LONGXY = LONGXY
  cdf->EDGEE = edgee
  cdf->EDGEW = edgew
  cdf->EDGES = edges
  cdf->EDGEN = edgen

 end if

  filevardef(cdf,vnames(ivar),"float",(/"time","lat","lon"/))

; file and variable attributes set
 if(vnames(ivar).eq."FLDS")
  arr@long_name = "incident longwave radiation"
  arr@units = "W/m^2"
  arr@mode = "time-dependent"
  arr@_FillValue = 1.e+36
  arr@missing_value = 1.e+36
 end if

 if(vnames(ivar).eq."PSRF")
  arr@long_name = "surface pressure at the lowest atm level"
  arr@units = "Pa"
  arr@mode = "time-dependent"
  arr@_FillValue = 1.e+36
  arr@missing_value = 1.e+36
 end if

 if(vnames(ivar).eq."TBOT")
  arr@long_name = "temperature at the lowest atm level"
  arr@units = "K"
  arr@mode = "time-dependent"
  arr@_FillValue = 1.e+36
  arr@missing_value = 1.e+36
 end if

 if(vnames(ivar).eq."QBOT")
  if(any(arr.lt.0.0))then
   print("found negative specific humidity")
   nt = dimsizes(arr(:,0,0))
   do i = 0, nt-1
    do j = 0, nlat-1
     do k = 0, nlon -1
       if(arr(i,j,k).lt.0.0)then
        print("at "+date(i)+" "+latin(j)+" "+lonin(k))
       end if
     end do
    end do
   end do
     
  end if

  arr = arr>1.e-7

  arr@long_name = "specific humidity at the lowest atm level"
  arr@units = "kg/kg"
  arr@mode = "time-dependent"
  arr@_FillValue = 1.e+36
  arr@missing_value = 1.e+36
 end if

 if(vnames(ivar).eq."WIND")

; regrid vector pair

  delete(arr) 
  arr1in = data[:]->UGRD_P0_L105_GGA0(0:(ndpm(imo)*nhr)-1,::-1,:)
  arr2in = data[:]->VGRD_P0_L105_GGA0(0:(ndpm(imo)*nhr)-1,::-1,:)
  arr1 = new( (/dimsizes(arr1in(:,0,0)),nlat,nlon/), "float")
  arr2 = new( (/dimsizes(arr1in(:,0,0)),nlat,nlon/), "float")
  f2fshv(arr1in,arr2in,arr1,arr2)
  arr = sqrt(arr1^2+arr2^2)

  arr@long_name = "wind at the lowest atm level"
  arr@units = "m/s"
  arr@mode = "time-dependent"
  arr@_FillValue = 1.e+36
  arr@missing_value = 1.e+36

  delete(arr1)
  delete(arr2)
  delete(arr1in)
  delete(arr2in)
 end if

  arr!0 = "time"
  arr!1 = "lat"
  arr!2 = "lon"

  arr&time = time
;  arr&lat = latin
;  arr&lon = lonin
  arr&lat = LATIXY(:,0)
  arr&lon = LONGXY(0,:)

  cdf->$vnames(ivar)$ = arr

 end if

 delete(arr)
 delete(arrin)

end do ; variable loop


 delete(fns)
 delete(day)
 delete(time)
 delete(date)

end do ; month loop

end do ; year loop








end