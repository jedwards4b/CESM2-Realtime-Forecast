begin
; First index is intentionally blank
load "get_member_and_date.ncl"

histDir = getenv("DOUT_S_ROOT") + "/atm/hist/"
workflow = getenv("CESM_WORKFLOW")

; -------------------------- READ IN H2 VARIABLES --------------------------
h2files = systemfunc("ls " + histDir + "*cam.h2.*")
f = addfiles(h2files, "r")
ListSetType(f, "cat")
rlut = f[:]->FLUT
pr = (f[:]->PRECT)*1000 ; ----------- to get from (m/s) to kg/(m^2s)
tas_2m = f[:]->TREFHT
ts = f[:]->TS
time = f[:]->time ; ----------------- make sure to get time from h2 (not h3) files


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


; -------------------------- HORIZONTAL INTERP and FILE SAVING  --------------------------
xi = f[0]->lon
yi = f[0]->lat
xo = fspan(0., 359., 360)
yo = fspan(-90., 90.,181)
var = [/ rlut, pr, tas_2m, ts, ua_200, ua_850, va_200, va_850, zg_200, zg_500 /]

varStrings = (/ "rlut", "pr_sfc", "tas_2m", "ts", "ua_200", "ua_850", "va_200", "va_850", "zg_200", "zg_500" /)
  do i = 0,ListCount(var)-1
	v:=linint2(xi,yi,var[i],True,xo,yo,0)
        outDir = getenv("SCRATCH") + "/" + workflow + "/p1/" + varStrings(i) + "/" + yyyy + "/" + mm + "/"
    	fout = outDir + varStrings(i) + "_" + workflow + "_" + outdate + "_00z_d01_d46_m" + member + ".nc"

	if (.not. fileexists(outDir)) then
          system("mkdir -p "+outDir)
        end if
	if (fileexists(fout)) then
          system("/bin/rm -f " + fout)   ; remove any pre-existing file
	end if
        setfileoption("nc", "Format", "NetCDF4")
	setfileoption("nc", "CompressionLevel", 1)
	ncdf = addfile(fout ,"c")  ; open output netCDF file
	filedimdef(ncdf,"time",-1,True)

	v!0 = "time"
	v!1 = "lat"
	v!2 = "lon"
	v&time = time
	v&lat = yo
	v&lon = xo
        copy_VarAtts(var[i],v)
	if(varStrings(i) .eq. "pr_sfc") then
		v@long_name="Total (convective and large-scale) precipitation rate (liq + ice)"
		v@units="kg/m2/s"
	end if

	ncdf->$varStrings(i)$=v
	print("Completed file: "+fout)
  end do
end
