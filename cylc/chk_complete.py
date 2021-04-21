#!/bin/env python
import os, glob

# use psl as a proxy for completion
ps1path = os.path.join(os.getenv("ARCHIVEROOT"),"70Lwaccm6","p2","psl")

for _file in glob.iglob(ps1path+"/*/*/*"):
    print ("found {}".format(_file))
