

begin

var = "TMP_P0_L105_GGA0"

fn1= "./data_files/gdas.1989123118.sfluxgrbl06_V2.grib2"

;fn1 = "splanl.gdas.1989010100.grb2"
dat1 = addfile(fn1,"r")

;nms = getfilevarnames(dat1)
;print(nms)

t1 = dat1->$var$

printVarSummary(t1)
exit


print(dimsizes(t1))

fn2 = "./data_files/gdas.1989010100.sfluxgrbl06.grib2"
dat2 = addfile(fn2,"r")
nms2 = getfilevarnames(dat2)
print(nms2)

t2 = dat2->$var$

print(dimsizes(t2))

exit
tdiff= t1-t2
print(min(tdiff))
print(max(tdiff))

end
