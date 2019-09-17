begin
load "get_member_and_date.ncl"

; ------------------------ SPECIFY LEVELS and VARIABLES ------------------------ 
lev_p = todouble((/1,2,3,5,10,50,100,200,300,500,700,850,925,1000/))
varStrings = (/ "U","V","T","OMEGA","Z3","Q","UQ","VQ","O3" /)

; -------------------------------- SPECIFY FILES -------------------------------

histDir = getenv("SCRATCH")+"/archive/70Lwaccm6." + date + "." + member + "/atm/hist/"
hfiles = systemfunc("ls " + histDir + "*cam.h1.*")
f = addfiles(hfiles, "r")
ListSetType(f, "cat")

hyam=f[1]->hyam
hybm=f[1]->hybm
P0mb=0.01*f[1]->P0
lev_p!0         = "lev_p"                  ; variable/dim name 
lev_p&lev_p     =  lev_p                   ; create coordinate variable
lev_p@long_name = "pressure"               ; attach some attributes
lev_p@units     = "hPa"
lev_p@positive  = "down"

  do i = 0,dimsizes(varStrings)-1
        outDir = getenv("SCRATCH")+"/70Lwaccm6/" + varStrings(i) + "/" + yyyy + "/" + mm + "/"
	v = f[:]->$varStrings(i)$
	PS = f[:]->PS
	vnew = vinth2p(v,hyam,hybm,lev_p,PS,1,P0mb,1,False)
	copy_VarAtts(v,vnew)
	fout = outDir + varStrings(i) + "_70Lwaccm6_" + outdate + "00z_d01_d46_m" + member + ".nc"
	if (.not. fileexists(outDir)) then
          system("mkdir -p "+outDir)
        end if
	if (fileexists(fout)) then
          system("/bin/rm -f " + fout)   ; remove any pre-existing file
        end if
        ncdf = addfile(fout ,"c")  ; open output netCDF file
        filedimdef(ncdf,"time",-1,True)

        ncdf->$varStrings(i)$=vnew
  end do

end

