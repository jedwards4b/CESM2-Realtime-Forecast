begin

; ------------------------ SPECIFY LEVELS and VARIABLES ------------------------ 
lev_p = todouble((/0.0001,0.001,0.01,0.1,0.5,1,5,10/))
varStrings = (/ "U_24_COS", "U_24_SIN", "U_12_COS", "U_12_SIN", "V_24_COS", "V_24_SIN", "V_12_COS", "V_12_SIN", "T_24_COS", "T_24_SIN", "T_12_COS", "T_12_SIN" /)

; -------------------------------- SPECIFY H FILES -------------------------------
date = "1999-08-02"
member = "00"
histDir = "/glade/scratch/ssfcst/archive/70Lwaccm6" + date + "." + member + "/atm/hist/"
hfiles = systemfunc("ls " + histDir + "*cam.h4.*")
fin = addfile(hfiles,"r")

; -------------------------------- NEED TO GRAB "PS" FROM ANOTHER H FILE (if missing) -------------------------------
h2files = systemfunc("ls " + histDir + "*cam.h2.*")
h2fin = addfile(h2files,"r")

hyam=fin->hyam
hybm=fin->hybm
P0mb=0.01*fin->P0
lev_p!0         = "lev_p"                  ; variable/dim name 
lev_p&lev_p     =  lev_p                   ; create coordinate variable
lev_p@long_name = "pressure"               ; attach some attributes
lev_p@units     = "hPa"
lev_p@positive  = "down"

do i = 0,dimsizes(varStrings)-1
	v = fin->$varStrings(i)$
	PS = h2fin->PS
	vnew = vinth2p(v,hyam,hybm,lev_p,PS,1,P0mb,1,False)
	copy_VarAtts(v,vnew)

        fout = "/glade/work/sglanvil/S2S_postprocessing/" + varStrings(i) + "_70Lwaccm6_" + date + "_" + member + ".nc"
        system("/bin/rm -f " + fout)   ; remove any pre-existing file
        ncdf = addfile(fout ,"c")  ; open output netCDF file
        filedimdef(ncdf,"time",-1,True)

        ncdf->$varStrings(i)$=vnew
end do

end

