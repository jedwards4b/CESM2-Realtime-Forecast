begin
load "get_member_and_date.ncl"

; ------------------------ SPECIFY LEVELS and VARIABLES ------------------------ 
;lev_p = todouble((/0.0001,0.001,0.01,0.1,0.5,1,2,3,5,10,20,30,50,70,100,200,300,500,700,850,925,1000/))
;lev_p = todouble((/5,10,20,30,50,70,100,200,300,500,700,850,925,1000/))
;varStrings = (/ "U","V","T","OMEGA","Z3","Q","UQ","VQ" /)
;varStrings = (/ "U","V","T","OMEGA","Z3","Q","UQ","VQ","RELHUM","O3" /)
; -------------------------------- SPECIFY FILES -------------------------------
print("HERE mm="+mm+" date="+date+" member="+member)
histDir = getenv("DOUT_S_ROOT")+ "/atm/hist/"
hfiles = systemfunc("ls " + histDir + "*cam.h1.*")
f = addfiles(hfiles, "r")
ListSetType(f, "cat")

hyam=f[0]->hyam
hybm=f[0]->hybm
P0mb=0.01*f[0]->P0
waccm = isStrSubset(getenv("DOUT_S_ROOT"),"70Lwaccm6")
if (waccm) then
  lev_p = todouble((/0.0001,0.001,0.01,0.1,0.5,1,2,3,5,10,20,30,50,70,100,200,300,500,700,850,925,1000/))
  varStrings = (/ "U","V","T","OMEGA","Z3","Q","UQ","VQ","O3","RELHUM" /)
else
  lev_p = todouble((/5,10,20,30,50,70,100,200,300,500,700,850,925,1000/))
  varStrings = (/ "U","V","T","OMEGA","Z3","Q","UQ","VQ","RELHUM" /)
end if
lev_p!0         = "lev_p"                  ; variable/dim name 
lev_p&lev_p     =  lev_p                   ; create coordinate variable
lev_p@long_name = "pressure"               ; attach some attributes
lev_p@units     = "hPa"
lev_p@positive  = "down"

  do i = 0,dimsizes(varStrings)-1
        if (waccm) then
          outDir = getenv("ARCHIVEROOT")+"/70Lwaccm6/" + varStrings(i) + "/" + yyyy + "/" + mm + "/"	
          fout = outDir + varStrings(i) + "_70Lwaccm6_" + outdate + "00z_d01_d46_m" + member + ".nc"
        else
          outDir = getenv("ARCHIVEROOT")+"/cesm2cam6climoALLv2/" + varStrings(i) + "/" + yyyy + "/" + mm + "/"
  	  fout = outDir + varStrings(i) + "_cesm2cam6climoALLv2_" + outdate + "00z_d01_d46_m" + member + ".nc"
        end if
	v = f[:]->$varStrings(i)$
	PS = f[:]->PS
	vnew = vinth2p(v,hyam,hybm,lev_p,PS,1,P0mb,1,False)
	copy_VarAtts(v,vnew)

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

        ncdf->$varStrings(i)$=vnew
  end do
end

