being

fn = "flxl04.gdas.1989010100.grb2"
dat = addfile(fn,"r")

nms = getfilevarnames(dat)
print(nms)

sol = dat->DSWRF_P8_L1_GGA0_avg

printVarSummary(sol)


end