begin
load "get_member_and_date.ncl"
; ------------------------ SPECIFY LEVELS and VARIABLES ------------------------ 
lev_p = todouble((/0.0001,0.001,0.01,0.1,0.5,1,5,10/))
varStrings = (/ "U_24_COS", "U_24_SIN", "U_12_COS", "U_12_SIN", "V_24_COS", "V_24_SIN", "V_12_COS", "V_12_SIN", "T_24_COS", "T_24_SIN", "T_12_COS", "T_12_SIN" /)

; -------------------------------- SPECIFY H FILES -------------------------------

histDir = getenv("DOUT_S_ROOT") + "/atm/hist/"
workflow = getenv("CESM_WORKFLOW")
hfiles = systemfunc("ls " + histDir + "*cam.h4.*")
fin = addfile(hfiles,"r")

; -------------------------------- NEED TO GRAB "PS" FROM ANOTHER H FILE (if missing) -------------------------------

hyam=fin->hyam
hybm=fin->hybm
P0mb=0.01*fin->P0
lev_p!0         = "lev_p"                  ; variable/dim name 
lev_p&lev_p     =  lev_p                   ; create coordinate variable
lev_p@long_name = "pressure"               ; attach some attributes
lev_p@units     = "hPa"
lev_p@positive  = "down"
PS = fin->PS	

  do i = 0,dimsizes(varStrings)-1
        outDir = getenv("SCRATCH") + "/" + workflow + varStrings(i) + "/" + yyyy + "/" + mm + "/"
    	fout = outDir + varStrings(i) + "_" + workflow + "_" + outdate + "_00z_d01_d46_m" + member + ".nc"

    if (.not. fileexists(outDir)) then
      system("mkdir -p "+outDir)
    end if
    if (fileexists(fout)) then
      system("/bin/rm -f " + fout)   ; remove any pre-existing file
    end if
    v = fin->$varStrings(i)$

    vnew = vinth2p(v,hyam,hybm,lev_p,PS,1,P0mb,1,False)
    copy_VarAtts(v,vnew)


    ncdf = addfile(fout ,"c")  ; open output netCDF file
    filedimdef(ncdf,"time",-1,True)

    ncdf->$varStrings(i)$=vnew
    print("Completed file: "+fout)
  end do

end

