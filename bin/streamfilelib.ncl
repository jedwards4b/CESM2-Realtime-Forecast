undef("create_stream_file")
function create_stream_file(fname, time, LATIXY, LONGXY, edgee, edgew, edges, edgen, case_title)
  begin
    print("Creating file "+fname)
    cdf = addfile(fname,"c")
    ; file global attributes

    globalAtt = True
    globalAtt@case_title = case_title

    nlat = dimsizes(LATIXY&lat)
    nlon = dimsizes(LATIXY&lon)


    filedimdef(cdf,(/"time","lat","lon","scalar"/),\
                 (/-1,nlat,nlon,1/), \
                 (/True,False,False,False/) )
    filevardef(cdf,"time","float",(/"time"/))
    filevardef(cdf,"LATIXY","float",(/"lat","lon"/))
    filevardef(cdf,"LONGXY","float",(/"lat","lon"/))
    filevardef(cdf,"EDGEE","float",(/"scalar"/))
    filevardef(cdf,"EDGEW","float",(/"scalar"/))
    filevardef(cdf,"EDGEN","float",(/"scalar"/))
    filevardef(cdf,"EDGES","float",(/"scalar"/))

    cdf->time = time
    cdf->LATIXY = LATIXY
    cdf->LONGXY = LONGXY
    cdf->EDGEE = edgee
    cdf->EDGEW = edgew
    cdf->EDGES = edges
    cdf->EDGEN = edgen
    return(cdf)
  end