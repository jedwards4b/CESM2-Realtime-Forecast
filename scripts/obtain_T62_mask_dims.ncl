

begin

 path = "/glade/collections/nmme/ncgd0022/jcaron/CFSv2/data_files/"
 fn = "gdas.1981032506.sfluxgrbl03.grib2"
 data = addfile(path+fn,"r")
 nms = getfilevarnames(data)

print(nms)

; printVarSummary(data)

lat = data->lat_0(::-1)
lat!0 = "lat"
lat&lat = lat
lon = data->lon_0
lon!0 = "lon"
lon&lon = lon

;print(lat)

print(lon)

; read in land field to determine land vs. ocean mask

msk= data->SOTYP_P0_L1_GGA0(::-1,:)
;msk = data->HGT_P0_L1_GGA0(::-1,:)

print(min(msk))
print(max(msk))

if(any(ismissing(msk)))then
 print("missing over ocean")
end if

; mask ocn vs land data

msk = where(ismissing(msk),0,msk)
msk = where(msk.gt.0.,1,msk)

; plot it for sanity check

wks = gsn_open_wks("png" ,"land_var")

 res                       = True     

 res@gsnMaximize           = True    
 res@cnFillOn              = True     
 res@cnLinesOn             = False    
 res@cnLevelSpacingF       = 0.5      
 res@cnFillPalette         = "BlAqGrYeOrRe"
 res@lbOrientation         = "Vertical"

 res@tiMainString = "land variable to get mask from"
 plot = gsn_csm_contour_map(wks,msk, res)

; output mask, lat, lon to file for domain script to use (create_domain.pro)

nfn = "T62_NCEP_CFSv2_dims.nc"
system("rm "+nfn)
cdf = addfile(nfn,"c")

msk!0 = "lat"
msk!1 = "lon"
msk&lat = lat
msk&lon = lon

msk@long_name = "mask 0 = ocn, 1 = land"


cdf->lat = lat
cdf->lon = lon
cdf->mask = msk


end