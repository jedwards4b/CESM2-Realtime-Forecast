load "./scripts/ss_extract.ncl"
load "./bin/streamfilelib.ncl"
load "./bin/get_member_and_date.ncl"
begin
  ; NOTE still need to generalize with perl script or csh call for any year,month
  ; combination
  ndpm = (/31,28,31,30,31,30,31,31,30,31,30,31/) ; no leap
  ; npath = "/glade/p/nsc/ncgd0042/ssfcst/cdas_data/"
  scratch = getenv("SCRATCH")
  npath = scratch + "/cdas_data/"

  fns = systemfunc("ls "+npath+"*das*."+yyyy+mm+"*.sfluxgrbf06.grib2")

  minday = 32
  maxday = 0
  nf = dimsizes(fns)
  nhr = 4
  do f = 0, nf-1

;    blah = ss_extract(fns(f),45,46)
;    print("yyyy is "+yyyy)
;    print("mm is "+mm)
;    print("blah is "+blah)
;    print("fns(f) is "+fns(f))

;    fday = tointeger(ss_extract(fns(f),52,53)) ; I think maybe the rda filenames changed? sasha, aug 24 2020
    fday = tointeger(ss_extract(fns(f),45,46))
    print("fday is "+fday+" fns "+fns(f))
    if (fday .lt. minday) then
      minday = fday
    end if
    if (fday .gt. maxday) then
      maxday = fday
    end if
  end do
  minob = (minday-1)*nhr
  maxob = maxday*nhr-1
  
  cmo = tointeger(mm)-1
  
  data = addfiles(fns,"r")
  ListSetType(data,"join")
  nms = getfilevarnames(data[0])

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

;  nfd = "/glade/p/nsc/ncgd0042/ssfcst/forcing_files/"
  nfd = scratch + "/forcing_files/"
  nfpre = "clmforc.NCEPCFSv2.c2019.0.2d.576x1152."

; begin with first of 3 streams

  do ivar = 0, nvars-1
    print("Handling var "+invars(ivar)+" > "+vnames(ivar))
    if(ivar.le.2)then
      strm = stream(ivar)
    end if
    tunits = "days since "+yyyy+"-"+mm+"-01 00:00:00"
    time = new( (/ndpm(cmo)*nhr/), "float")
    vdate = new( (/ndpm(cmo)*nhr/), "integer")
    iday = new( (/ndpm(cmo)*nhr/), "integer")
    inc = 0

    if(strm.eq."Solar")then
      hr = (/0,6,12,18/)
    else
      hr = (/3,9,15,21/)
    end if ; strm

      ; time is based off of the number of days in the month for 6 hour timestep

    hcnt = hr(0)
    do idy = 0, ndpm(cmo)*nhr-1
      vdate(idy) = ((((tointeger(yyyy+mm))*100)+inc)*100)+hcnt
      if(hcnt.eq.hr(0))then ; each time we hit a new day
        inc = inc + 1
        iday(idy:idy+3) = inc ; fill 4 time steps with same day number
      end if

      time(idy) = tofloat(cd_inv_calendar(tointeger(yyyy),tointeger(mm),iday(idy),1.0*hcnt,0.,0.,tunits,0))
      if(hcnt.eq.hr(3))then
        hcnt = hr(0)
      else
        hcnt = hcnt + 6
      end if
    end do


    time@long_name = "observation time"
    time@units = tunits
    time@calendar = "noleap"
;    delete(time@_FillValue)

    time!0 = "time"
    time&time = time

    nt = dimsizes(time)
    nct = dimsizes(data[:]->$invars(ivar)$(:,0,0))

    arrin = data[:]->$invars(ivar)$(:,::-1,:)
    if (any(ismissing(arrin))) then
      print(ivar+" contains missing values.")
    end if		   

    delete_VarAtts(arrin,-1)

    ; variables and attributes for all streams

    if(yyyy.lt."2011")then
      ; JPE:This block is as yet untested
      arr = arrin

      latin = data[0]->lat_0(::-1)
      lonin = data[0]->lon_0
      nlat = dimsizes(latin)
      nlon = dimsizes(lonin)

    else
      ; beginning in 2011, grid changes to higher res. read in desired lat, lon
      ; for regridding
;      fnd = "/glade/p/nsc/ncgd0042/ssfcst/cdas_data/dims.nc"
      fnd = scratch + "/cdas_data/dims.nc"
      datd = addfile(fnd,"r")
      latin = datd->lat
      lonin = datd->lon
      nlat = dimsizes(latin)
      nlon = dimsizes(lonin)

      if(nct.lt.nt)then
        print("NOTE! Number of time steps in data is less than a full month. Assuming we are at the end of the current record. Filling remaining times with missing values")

	time(nct:nt-1) = default_fillvalue("float")

        arrtmp = f2fsh(arrin,(/nlat,nlon/))
        arr = new( (/nt,nlat,nlon/), "float", default_fillvalue("float"))
        arr(minob:maxob,:,:) = arrtmp
        delete(arrtmp)
      else
        arr = f2fsh(arrin,(/nlat,nlon/))
      end if
    end if

    delete_VarAtts(latin,-1)
    delete_VarAtts(lonin,-1)


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

    LATIXY&lat = LATIXY(:,0)
    LATIXY&lon = LATIXY(0,:)

    LONGXY!0 = "lat"
    LONGXY!1 = "lon"

    LONGXY&lat = LONGXY(:,0)
    LONGXY&lon = LONGXY(0,:)

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
      arr@long_name = "total incident solar radiation"
      arr@units = "W/m^2"
      arr@mode = "time-dependent"
      arr@_FillValue = default_fillvalue("float")
      arr@missing_value = default_fillvalue("float")
      arr!0 = "time"
      arr!1 = "lat"
      arr!2 = "lon"
      arr&time = time
      arr&lat = LATIXY(:,0)
      arr&lon = LONGXY(0,:)
      ; make sure it's not negative after regrid
      arr = arr>0.0;

      nfn = nfd+nfpre+strm+"."+yyyy+"-"+mm+".nc"
      if (.not. fileexists(nfn)) then
        case_title = "NCEP CFSv2 6_Hourly Atmospheric Forcing: Incoming Solar"
        cdf = create_stream_file(nfn, time,LATIXY, LONGXY, edgee, edgew, edges, edgen, case_title)
        print("Done creating "+case_title)
        filevardef(cdf,"FSDS","float",(/"time","lat","lon"/))

        ; file and variable attributes set
        cdf->FSDS = arr
      else
        cdf = addfile(nfn,"w")
	printVarSummary(arr)
        cdf->FSDS(minob:maxob,:,:) = arr(minob:maxob,:,:)
      end if
      delete(arr)
    end if ; strm.eq."Solar"


    if(strm.eq."Precip")then
      ; file and variable attributes set
      arr@long_name = "PRECTmms total precipitation"
      arr@units = "mm H2O / sec"
      arr@mode = "time-dependent"
      arr@_FillValue = default_fillvalue("float")
      arr@missing_value = default_fillvalue("float")
      arr!0 = "time"
      arr!1 = "lat"
      arr!2 = "lon"
      arr&time = time
      arr&lat = (/latin/)
      arr&lon = (/lonin/)

      nfn = nfd+nfpre+strm+"."+yyyy+"-"+mm+".nc"
      if (.not. fileexists(nfn)) then
        case_title = "NCEP CFSv2 6_Hourly Atmospheric Forcing: Precipitation"
        cdf = create_stream_file(nfn, time,LATIXY, LONGXY, edgee, edgew, edges, edgen, case_title)
        cdf->PRECTmms = arr
      else
        cdf = addfile(nfn,"w")
        cdf->PRECTmms(minob:maxob,:,:) = arr(minob:maxob,:,:)
      end if
      delete(arr)
    end if

    if(strm.eq."TPQWL")then
      if(ivar.eq.2)then ; first time through loop define file and write coordinate vars
        nfn = nfd+nfpre+strm+"."+yyyy+"-"+mm+".nc"
        if (.not. fileexists(nfn)) then
          newfile = 1
          case_title = "NCEP CFSv2 6_Hourly Atmospheric Forcing: Temperature, Pressure, Winds, Humidity, and Downward Longwave Radiation"
          cdf = create_stream_file(nfn, time,LATIXY, LONGXY, edgee, edgew, edges, edgen, case_title)
          filevardef(cdf,vnames(ivar),"float",(/"time","lat","lon"/))
        else
	  newfile = 0
          cdf = addfile(nfn,"w")
        end if
      end if ; ivar == 2

      ; file and variable attributes set
      arr@mode = "time-dependent"
      arr@_FillValue = default_fillvalue("float")
      arr@missing_value = default_fillvalue("float")
      if(vnames(ivar).eq."FLDS")
        arr@long_name = "incident longwave radiation"
        arr@units = "W/m^2"
      end if

      if(vnames(ivar).eq."PSRF")
        arr@long_name = "surface pressure at the lowest atm level"
        arr@units = "Pa"
      end if

      if(vnames(ivar).eq."TBOT")
        arr@long_name = "temperature at the lowest atm level"
        arr@units = "K"
      end if

      if(vnames(ivar).eq."QBOT")
        nt = dimsizes(arr(:,0,0))

        arr = arr>1.e-7
        arr@long_name = "specific humidity at the lowest atm level"
        arr@units = "kg/kg"
      end if

      if(vnames(ivar).eq."WIND")

        ; regrid vector pair

        delete(arr)
        arr1in = data[:]->UGRD_P0_L105_GGA0(0:(ndpm(cmo)*nhr)-1,::-1,:)
        arr2in = data[:]->VGRD_P0_L105_GGA0(0:(ndpm(cmo)*nhr)-1,::-1,:)
	print ("after var read")
        arr1 = new( (/dimsizes(arr1in(:,0,0)),nlat,nlon/), "float")
        arr2 = new( (/dimsizes(arr1in(:,0,0)),nlat,nlon/), "float")
        f2fshv(arr1in,arr2in,arr1,arr2)
	print ("before sqrt")
        arr = sqrt(arr1^2+arr2^2)
	print ("after sqrt")
        arr@long_name = "wind at the lowest atm level"
        arr@units = "m/s"

        delete(arr1)
        delete(arr2)
        delete(arr1in)
        delete(arr2in)
      end if

      arr!0 = "time"
      arr!1 = "lat"
      arr!2 = "lon"
      arr@mode = "time-dependent"
      arr@_FillValue = default_fillvalue("float")
      arr@missing_value = default_fillvalue("float")

      arr&time = time
      arr&lat = LATIXY(:,0)
      arr&lon = LONGXY(0,:)
      if (newfile .gt. 0) then
        cdf->$vnames(ivar)$ = arr
      else
        printVarSummary(arr)
        cdf->$vnames(ivar)$(minob:maxob,:,:) = arr(minob:maxob,:,:)
      end if
      delete(arr)
    end if

    delete(arrin)

  end do ; variable loop


  delete(fns)
  delete(iday)
  delete(time)
  delete(vdate)

end
