import os
date = "1999-06-14"
rvals_file = os.path.join(os.getenv("WORK"),"cases","70Lwaccm6","camic_"+date+".txt")
if os.path.isfile(rvals_file):
    rvals = []
    with open(rvals_file,"r") as fd:
        rawvals = fd.read().split(',')
    for rval in rawvals:
        if rval.startswith('['):
            rval = int(rval[1:])
        elif rval.endswith(']'):
            rval = int(rval[:-1])
        else:
            rval = int(rval)
        rvals.append(rval)
    print( "rvals = {}".format(rvals))
