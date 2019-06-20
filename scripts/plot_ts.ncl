

begin

 path = "./forcing_files/"
 fns = systemfunc("ls "+path+"clmforc.NCEPCFSv2.c2019.T62.94x192.TPQWL.*.nc")
 print(fns)

 ; look at trends over a subset of years

 nyr = 5
 nmo = 12

 nt = nyr*nmo

 data = addfiles(fns,"r")
 ListSetType(data,"cat")

 tbot = data[:]->TBOT(0:nt-1,:,:)

 tbot1 = dim_avg(tbot) ; average over all longitudes

 ; weight and average over lats (for global and polar regions)

 

; plot time series to look for trends





end