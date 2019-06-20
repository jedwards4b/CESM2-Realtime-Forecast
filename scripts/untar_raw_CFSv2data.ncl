load "./ss_extract.ncl"

begin

;yrs = (/"2011"/) ; has both cdas and gdas files
yrs = (/"2019"/)
;yrs = (/"2012","2013","2014","2015","2016","2017","2018"/)
;yrs = (/"2017","2018"/)
nyr = dimsizes(yrs)
nmo = 12
nhr = 4

do iyr = 0, nyr-1

; original tar file names on NCEP RDA archive

; to do == set up to do flag check on gdas vs cdas file for pre april 2011 
; flxf01.gdas.<daterange>.tar with 5 days per tar ball

;cdas path

path = "/glade/collections/rda/data/ds094.0/"+yrs(iyr)+"/"
tarfns = systemfunc("ls "+path+"cdas1.*.sfluxgrbf.tar")

ntf = dimsizes(tarfns)

; untar original files and rename to keep date information

hr = (/"00","06","12","18"/)
nhr = 4

do itf = 0, ntf-1

 yr = ss_extract(tarfns(itf),48,51)
 mo = ss_extract(tarfns(itf),52,53)
 dy = ss_extract(tarfns(itf),54,55)
 fdate = ss_extract(tarfns(itf),48,55)

 npath = "./data_files/"

    print("tar -xvf "+tarfns(itf))
    system("tar -xvf "+tarfns(itf))

   do indx = 0, nhr-1
    ofn = "cdas1.t"+hr(indx)+"z.sfluxgrbf06.grib2"
    nfn = "cdas1."+fdate+hr(indx)+".sfluxgrbf06.grib2" 

    print("mv "+ofn+" "+npath+nfn)
    system("mv "+ofn+" "+npath+nfn)
   end do

 ; clean up files

     system("rm cdas1.t*z.sfluxgrb*.grib2")


end do ; file loop for a given year

 delete(tarfns)

end do ; year loop


end
