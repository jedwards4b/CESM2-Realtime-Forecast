#!/usr/bin/env python
import ecflow, os

try:
    print("Loading definition in 'cesm2cam6.def' into the server")
    ci = ecflow.Client()

    host = os.getenv("ECF_HOST")
    port = os.getenv("ECF_PORT")
    ci.set_host_port(host,port)
    ci.delete_all()
    ci.load("cesm2cam6.def")  # read definition from disk and load into the server
    ci.begin_suite("cesm2cam6")
    
except RuntimeError as e:
    print("Failed:", e)
