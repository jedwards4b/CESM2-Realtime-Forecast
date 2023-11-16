begin
; First index is intentionally blank
load "get_member_and_date.ncl"

histDir = getenv("DOUT_S_ROOT") + "/atm/hist/"
landDir = getenv("DOUT_S_ROOT") + "/lnd/hist/"
workflow = getenv("CESM_WORKFLOW")

; -------------------------- READ IN H2 VARIABLES --------------------------
h2files = systemfunc("ls " + histDir + "*cam.h2.*")
f = addfiles(h2files, "r")
ListSetType(f, "cat")
huss_850 = f[:]->Q850
tasmax_2m = f[:]->TREFHTMX
tasmin_2m = f[:]->TREFHTMN
hfss_sfc = f[:]->SHFLX
hfls_sfc = f[:]->LHFLX
stx_sfc = f[:]->TAUX
sty_sfc = f[:]->TAUY
FLNS = f[:]->FLNS
FSNS = f[:]->FSNS
rad_sfc = FLNS-FSNS
sic = f[:]->ICEFRAC*100 ; ----------- needs to be in percentage
cape = f[:]->CAPE
time = f[:]->time ; ----------------- make sure to get time from h2 (not h3) files


; -------------------------- READ IN H3 VARIABLES --------------------------
h3files = systemfunc("ls " + histDir + "*cam.h3.*")
f = addfiles(h3files, "r")
ListSetType(f, "cat")
wap_500 = calculate_daily_values(f[:]->OMEGA500, "avg", 0, False)
psl = calculate_daily_values(f[:]->PSL, "avg", 0, False)
ua_100 = calculate_daily_values(f[:]->U100, "avg", 0, False)
va_100 = calculate_daily_values(f[:]->V100, "avg", 0, False)
uvas = calculate_daily_values(f[:]->U10, "avg", 0, False)


; -------------------------- READ IN LAND VARIABLES --------------------------
landfiles = systemfunc("ls " + landDir + "*clm2.h0.*")
f = addfiles(landfiles, "r")
ListSetType(f, "cat")
snc = f[:]->FSNO*100 ; ----------- needs to be in percentage
mrro = f[:]->QRUNOFF
rzsm = f[:]->H2OSOI
mrso = f[:]->SOILLIQ

soillev = f[:]->levgrnd
soildim =dimsizes(soillev)
soillev := soillev(0:soildim-6) ; -------- always ignore bottom 5 levs
soil_1meter_inx=dimsizes(ind(soillev.le.1)) ; ------- go 1 meter down
soilthickness = center_finite_diff(soillev,1,False,0)
soilthickness_bigArray=conform_dims(dimsizes(rzsm),soilthickness,1)

rzsmXthickness=rzsm*soilthickness_bigArray
rzsm:=dim_sum_n(rzsmXthickness(:,0:soil_1meter_inx,:,:),1)/dim_sum_n(soilthickness_bigArray(:,0:soil_1meter_inx,:,:),1)
mrsoXthickness=mrso*soilthickness_bigArray
mrso:=dim_sum_n(mrsoXthickness(:,0:soil_1meter_inx,:,:),1)/dim_sum_n(soilthickness_bigArray(:,0:soil_1meter_inx,:,:),1)



; -------------------------- HORIZONTAL INTERP and FILE SAVING  --------------------------
xi = f[0]->lon
yi = f[0]->lat
xo = fspan(0., 359., 360)
yo = fspan(-90., 90.,181)
var = [/ huss_850,tasmax_2m,tasmin_2m,hfss_sfc,hfls_sfc,stx_sfc,sty_sfc,rad_sfc,sic,cape,wap_500,psl,ua_100,va_100,uvas,snc,mrro,rzsm,mrso /]
varStrings = (/ "huss_850","tasmax_2m","tasmin_2m","hfss_sfc","hfls_sfc","stx_sfc","sty_sfc","rad_sfc","sic","cape","wap_500","psl","ua_100","va_100","uvas","snc","mrro","rzsm","mrso" /)
do i = 0,ListCount(var)-1
        v:=linint2(xi,yi,var[i],True,xo,yo,0)

        outDir = getenv("SCRATCH") + "/" + workflow + "/p2/" + varStrings(i) + "/" + yyyy + "/" + mm + "/"
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

        if(varStrings(i) .eq. "rad_sfc") then
                v@long_name="Net Surface Radiation (FLNS-FSNS)"
                v@units="W/m2"
        end if
        if(varStrings(i) .eq. "sic") then
                v@long_name="Fraction of sfc area covered by sea-ice (converted to %)"
                v@units="%"
        end if
        if(varStrings(i) .eq. "snc") then
                v@long_name="Fraction of ground covered by snow (converted to %)"
                v@units="%"
        end if
        if(varStrings(i) .eq. "rzsm") then
                v@long_name="volumetric soil water, 1m vertical-weighted average (vegetated landunits only)"
                v@units="mm3/mm3"
        end if
        if(varStrings(i) .eq. "mrso") then
                v@long_name="soil liquid, 1m vertical-weighted averaged (vegetated landunits only)"
                v@units="kg/m2"
        end if

        ncdf->$varStrings(i)$=v
        print("Completed file: "+fout)
end do

end

