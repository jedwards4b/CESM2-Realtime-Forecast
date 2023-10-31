#!/usr/bin/env python
import ecflow, os

try:
    workflow = os.getenv("CESM_WORKFLOW")
    if not workflow:
        raise RuntimeError("CESM_WORKFLOW env variable not found")
    print(f"Loading definition in {workflow}  into the server")
    ci = ecflow.Client()

    host = os.getenv("ECF_HOST")
    if not host:
        raise RuntimeError("ECF_HOST env variable not found")
    port = os.getenv("ECF_PORT")
    if not port:
        raise RuntimeError("ECF_PORT env variable not found")

    ci.set_host_port(host,port)
    ci.delete_all()
    ci.load("cesm2espstoch.def")  # read definition from disk and load into the server
    ci.begin_suite("cesm2espstoch")
    
except RuntimeError as e:
    print("Failed:", e)
