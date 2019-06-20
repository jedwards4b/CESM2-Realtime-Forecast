pro cr
;--  create domain file for datm  ---------------------------------

 
;--  Read in example domain file  ---------------------------------
if 1 eq 2 then begin
    infile='domain.T62.050609.nc'
    id=ncdf_open(infile)
;--  Examine available variables  ---------------------------------
    print, id
;--  ncdf_inquire has tagnames: ndims, nvars, ngatts, recdim
    inq=ncdf_inquire(id)
    print, 'Number of variabiles: ',inq.nvars
    for i=0, inq.nvars-1 do begin
;--  ncdf_varinq has tagnames: name, dataype, ndims, natts, dim
        tmp=ncdf_varinq(id,i)
        print, tmp.name         ;,tmp.natts
;--  Check attributes and attribute names
        if 1 then begin
            for j=0,tmp.natts-1 do begin
                name=ncdf_attname(id,i,j)
                ncdf_attget,id,i,name,temp
                print, name, ': ',string(temp)
            endfor
        endif
;--  Check dimensions and dimension names
        if 1 then begin
            for j=0,tmp.ndims-1 do begin
                ncdf_diminq,id,tmp.dim[j],name,temp
                print, tmp.dim[j], name, ': ',string(temp)
            endfor
        endif
    endfor
    ncdf_close,id
endif

;--  read in input latitude and longitude
;infile='/project/bgc01/oleson/cruncep/cruncep_qair_1948.nc'
;infile='/glade/p/cesm/lmwg/atm_forcing.datm7.cruncep.0.5d.V5_2014.c140715/temp/cruncepv5_swdown_2001.nc'
infile='/glade/scratch/swensosc/CRUNCEP_v7_rawfiles/trendy/cruncepv7_press_2002.nc'
infile='/glade/scratch/dll/newTRENDYCRU/TRENDY_ENSO_CRUdata_17March2017download/cruncepv7_press_2016.nc'

id=ncdf_open(infile)
ncdf_varget,id,ncdf_varid(id,'latitude'),lat
ncdf_varget,id,ncdf_varid(id,'longitude'),lon
ncdf_varget,id,ncdf_varid(id,'mask'),mask
ncdf_close,id

dir='/glade/p/cesm/lmwg/atm_forcing.datm7.cruncep.0.5d.V7.c160714/'
dir='/glade/scratch/swensosc/CRUNCEP_v7_rawfiles/'
dir='/glade/scratch/swensosc/'

outfile=dir+'domain.cruncep.V7.c2017.0.5d.nc'

;--  reverse orientation to south -> north  ------------------------
lat=reverse(lat)
;for i=0,(size(lon,/dim))(0)-1 do mask[i,*]=reverse(mask[i,*],2)
mask=reverse(mask,2)

;--  Output variables needed for domain file  ----------------------
; Number of variabiles:            6
; ni=nlon, nj=nlat, nv=nvertices
; xc[nj,ni]
; long_name: longitude of grid cell center
; units: degrees east
; yc[nj,ni]
; long_name: latitude of grid cell center
; units: degrees north
; xv[nj,ni,nv]
; long_name: longitude of grid cell verticies
; units: degrees east
; yv[nj,ni,nv]
; long_name: latitude of grid cell verticies
; units: degrees north
; mask[nj,ni]
; long_name: domain mask
; units: unitless
; area[nj,ni]
; long_name: area of grid cell in radians squared
; units: area


;--  Output grid  ---------------------------------------------------
ni=(size(lon,/dim))(0)
nj=(size(lat,/dim))(0)
idel=360.0/float(ni)
jdel=180.0/float(nj)

;--  define variables  --------------------------------------------
xc=dblarr(ni,nj)
yc=dblarr(ni,nj)
nv=long(4)
xv=dblarr(ni,nj,nv)
yv=dblarr(ni,nj,nv)
;--  CRUNCEP has lat [90:-89.5], lon [-180:179.5] so shift both by
;   0.25 degrees for xc,yc
;--  V7 appears to be corrected
shiftcoord = 0
lonshift=0.5*idel
latshift=-0.5*jdel
for j=0,nj-1 do begin
   if shiftcoord eq 1 then begin
      xc[*,j]=lon+lonshift      ;shift was for original dataset
   endif else begin
      xc[*,j]=lon
   endelse
    ;; xv[*,j,0]=xc[*,j]-0.5*idel
    ;; xv[*,j,1]=xc[*,j]+0.5*idel
    ;; xv[*,j,2]=xc[*,j]+0.5*idel
    ;; xv[*,j,3]=xc[*,j]-0.5*idel
endfor
for i=0,ni-1 do begin
   if shiftcoord eq 1 then begin
      yc[i,*]=lat+latshift      ;shift was for original dataset
   endif else begin
      yc[i,*]=lat
   endelse
    ;; yv[i,*,0]=yc[i,*]-0.5*jdel
    ;; yv[i,*,1]=yc[i,*]-0.5*jdel
    ;; yv[i,*,2]=yc[i,*]+0.5*jdel
    ;; yv[i,*,3]=yc[i,*]+0.5*jdel
endfor

phi=!pi/180.0*lon
th=!pi/180.0*(90.0-lat)
dphi=abs(phi[0]-phi[1])
dth=abs(th[0]-th[1])

; use original mask, after converting to 0/1
mask=long(mask gt -1)
; or try using mask = 1 everywhere
;mask[*,*]=1

area=dblarr(ni,nj)
for i=0,ni-1 do area[i,*]=sin(th)*dth*dphi
area=mask*area

; shift from -180:180 to 0:360
shiftnum=1
if shiftnum eq 1 then begin
    for j=0,nj-1 do begin
        xc[*,j]=shift(reform(xc[*,j]),ni/2)
        yc[*,j]=shift(reform(yc[*,j]),ni/2)
;        xv[*,j,*]=shift(reform(xv[*,j,*]),ni/2,0)
;        yv[*,j,*]=shift(reform(yv[*,j,*]),ni/2,0)
        area[*,j]=shift(reform(area[*,j]),ni/2)
        mask[*,j]=shift(reform(mask[*,j]),ni/2)
    endfor
    ind=where(xc lt 0,cnt)
    if cnt gt 0 then xc[ind]+=360
;    ind=where(xv lt 0,cnt)
;    if cnt gt 0 then xv[ind]+=360
endif

for j=0,nj-1 do begin
    xv[*,j,0]=xc[*,j]-0.5*idel
    xv[*,j,1]=xc[*,j]+0.5*idel
    xv[*,j,2]=xc[*,j]+0.5*idel
    xv[*,j,3]=xc[*,j]-0.5*idel
endfor
for i=0,ni-1 do begin
    yv[i,*,0]=yc[i,*]-0.5*jdel
    yv[i,*,1]=yc[i,*]-0.5*jdel
    yv[i,*,2]=yc[i,*]+0.5*jdel
    yv[i,*,3]=yc[i,*]+0.5*jdel
endfor


;--  Create a new NetCDF file with the filename inquire.nc:  
id = NCDF_CREATE(outfile, /CLOBBER)  
;--  Fill the file with default values:  -----------------
NCDF_CONTROL, id, /FILL  
;==  Begin defining dimensions, ids, and variables  ======
sid = NCDF_DIMDEF(id, 'scalar', 1) ; Define the scalar dimension.  
xid = NCDF_DIMDEF(id, 'ni', ni) ; Define the longitude dimension.  
yid = NCDF_DIMDEF(id, 'nj', nj) ; Define the latitude dimension.  
vid = NCDF_DIMDEF(id, 'nv', 4)  ; Define the time dimension.  
;--  Setup variable ids  ---------------------------------  
lonid = NCDF_VARDEF(id, 'xc', [xid,yid], /double)  
latid = NCDF_VARDEF(id, 'yc', [xid,yid], /DOUBLE)  
lonedgeid = NCDF_VARDEF(id, 'xv', [xid,yid,vid], /double)  
latedgeid = NCDF_VARDEF(id, 'yv', [xid,yid,vid], /DOUBLE)  
maskid = NCDF_VARDEF(id, 'mask', [xid,yid], /long)  
areaid = NCDF_VARDEF(id, 'area', [xid,yid], /double)  

;--  Setup variable attributes  --------------------------
NCDF_ATTPUT, id, /GLOBAL, 'case_title', $
  'CRUNCEP 6-Hourly Atmospheric Forcing'  
NCDF_ATTPUT, id, lonid, 'long_name', 'longitude of grid cell center'
NCDF_ATTPUT, id, lonid, 'units', 'degrees_east'
NCDF_ATTPUT, id, lonid, 'mode', 'time-invariant'
NCDF_ATTPUT, id, latid, 'long_name', 'latitude of grid cell center'
NCDF_ATTPUT, id, latid, 'units', 'degrees_north'
NCDF_ATTPUT, id, latid, 'mode', 'time-invariant'
NCDF_ATTPUT, id, lonedgeid, 'long_name', 'longitude of grid cell vertices'
NCDF_ATTPUT, id, lonedgeid, 'units', 'degrees_east'
NCDF_ATTPUT, id, lonedgeid, 'mode', 'time-invariant'
NCDF_ATTPUT, id, latedgeid, 'long_name', 'latitude of grid cell vertices'
NCDF_ATTPUT, id, latedgeid, 'units', 'degrees_east'
NCDF_ATTPUT, id, latedgeid, 'mode', 'time-invariant'
NCDF_ATTPUT, id, maskid, 'long_name', 'domain mask'
NCDF_ATTPUT, id, maskid, 'units', 'unitless'
NCDF_ATTPUT, id, maskid, 'mode', 'time-invariant'
NCDF_ATTPUT, id, areaid, 'long_name', 'area of grid cell in radians squared'
NCDF_ATTPUT, id, areaid, 'units', 'area'
NCDF_ATTPUT, id, areaid, 'mode', 'time-invariant'
    
; Put file in data mode:  
NCDF_CONTROL, id, /ENDEF  
; Input data:  
NCDF_VARPUT, id, lonid, xc
NCDF_VARPUT, id, latid, yc
NCDF_VARPUT, id, lonedgeid, xv
NCDF_VARPUT, id, latedgeid, yv
NCDF_VARPUT, id, maskid, mask
NCDF_VARPUT, id, areaid, area
    
;--  Close the NetCDF file  --------------------------------
NCDF_CLOSE, id 

print,crashnow
end
