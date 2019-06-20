

begin

fn = "./data_files/gdas.2001010100.sfluxgrbf06.grib2"
data = addfile(fn,"r")

 latin = data->lat_0(::-1)
 lonin = data->lon_0

 latin!0 = "lat"
 lonin!0 = "lon"

 nlat = dimsizes(latin)
 nlon = dimsizes(lonin)

nfn = "dims.nc"
system("rm "+nfn)
cdf = addfile(nfn,"c")

filedimdef(cdf,(/"lat","lon"/), \
                     (/nlat, nlon/), \
                     (/False,False/) )


cdf->lat = latin
cdf->lon = lonin


end