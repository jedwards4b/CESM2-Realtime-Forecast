begin
; First index is intentionally blank
load "get_member_and_date.ncl"

histDir = getenv("DOUT_S_ROOT") + "/atm/hist/"
workflow = getenv("CESM_WORKFLOW")

; -------------------------- READ IN H2 VARIABLES --------------------------
h2files = systemfunc("ls " + histDir + "*cam.h2.*")
f = addfiles(h2files, "r")
ListSetType(f, "cat")
ta_100 = f[:]->T100
ta_10 = f[:]->T010
ta_30 = f[:]->T030
ta_50 = f[:]->T050
time = f[:]->time ; ----------------- make sure to get time from h2 (not h3) files


; -------------------------- READ IN H3 VARIABLES --------------------------
h3files = systemfunc("ls " + histDir + "*cam.h3.*")
f = addfiles(h3files, "r")
ListSetType(f, "cat")
ua_10 = calculate_daily_values(f[:]->U010, "avg", 0, False)
va_10 = calculate_daily_values(f[:]->V010, "avg", 0, False)
ua_30 = calculate_daily_values(f[:]->U030, "avg", 0, False)
va_30 = calculate_daily_values(f[:]->V030, "avg", 0, False)
ua_50 = calculate_daily_values(f[:]->U050, "avg", 0, False)
va_50 = calculate_daily_values(f[:]->V050, "avg", 0, False)
zg_10 = calculate_daily_values(f[:]->Z010, "avg", 0, False)
zg_30 = calculate_daily_values(f[:]->Z030, "avg", 0, False)
zg_50 = calculate_daily_values(f[:]->Z050, "avg", 0, False)
zg_850 = calculate_daily_values(f[:]->Z850, "avg", 0, False)

; -------------------------- HORIZONTAL INTERP and FILE SAVING  --------------------------
xi = f[0]->lon
yi = f[0]->lat
xo = fspan(0., 359., 360)
yo = fspan(-90., 90.,181)
var = [/ ta_100, ta_10, ta_30, ta_50, ua_10, va_10, ua_30, va_30, ua_50, va_50, zg_10, zg_30, zg_50, zg_850 /]
varStrings = (/ "ta_100", "ta_10", "ta_30", "ta_50", "ua_10", "va_10", "ua_30", "va_30", "ua_50", "va_50", "zg_10", "zg_30", "zg_50", "zg_850" /)
do i = 0,ListCount(var)-1
	v:=linint2(xi,yi,var[i],True,xo,yo,0)
        outDir = getenv("SCRATCH") + "/" + workflow + "/p3/" + varStrings(i) + "/" + yyyy + "/" + mm + "/"
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

	ncdf->$varStrings(i)$=v
	print("Completed file: "+fout)
end do
end
