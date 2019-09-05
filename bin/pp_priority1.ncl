begin

date = "1999-01-18"
member = "00"

histDir = "/glade/scratch/jedwards/archive/70Lwaccm6." + date + "." + member + "/atm/hist/"

; -------------------------- CREATE OUTPUT FILE --------------------------
fout = "/glade/work/sglanvil/S2S_postprocessing/70Lwaccm6." + date + "." + member + ".pp.nc"
system("/bin/rm -f " + fout)   ; remove any pre-existing file
ncdf = addfile(fout ,"c")  ; open output netCDF file
fAtt               = True            ; assign file attributes
fAtt@title         = "S2S priority 1 variables, post-processed, Glanville"
fAtt@Conventions   = "None"
fAtt@creation_date = systemfunc ("date")
fileattdef( ncdf, fAtt )            ; copy file attributes
filedimdef(ncdf,"time",-1,True)

; -------------------------- READ IN H2 VARIABLES --------------------------
h2files = systemfunc("ls " + histDir + "*cam.h2.*")
f = addfiles(h2files, "r")
ListSetType(f, "cat")
rlut = f[:]->FLUT
pr = f[:]->PRECT
tas_2m = f[:]->TREFHT
ts = f[:]->TS

; -------------------------- READ IN H3 VARIABLES --------------------------
h3files = systemfunc("ls " + histDir + "*cam.h3.*")
f = addfiles(h3files, "r")
ListSetType(f, "cat")
ua_200 = calculate_daily_values(f[:]->U200, "avg", 0, False)
ua_850 = calculate_daily_values(f[:]->U850, "avg", 0, False)
va_200 = calculate_daily_values(f[:]->V200, "avg", 0, False)
va_850 = calculate_daily_values(f[:]->V850, "avg", 0, False)
zg_200 = calculate_daily_values(f[:]->Z200, "avg", 0, False)
zg_500 = calculate_daily_values(f[:]->Z500, "avg", 0, False)

; -------------------------- HORIZONTAL INTERPOLATION --------------------------
xi = f[1]->lon
yi = f[1]->lat
xo = fspan(0., 359., 360)  ;1.0 degree
yo = fspan(-90., 90.,181)  ;1.0 degree
var = [/ rlut, pr, tas_2m, ts, ua_200, ua_850, va_200, va_850, zg_200, zg_500 /]
varStrings = (/ "rlut", "pr", "tas_2m", "ts", "ua_200", "ua_850", "va_200", "va_850", "zg_200", "zg_500" /)
do i = 0,ListCount(var)-1
	v:=linint2_Wrap(xi,yi,var[i],True,xo,yo,0)
	ncdf->$varStrings(i)$=v
end do

end

