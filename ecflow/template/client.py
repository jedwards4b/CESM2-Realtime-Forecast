#!/usr/bin/env python
import sys,ecflow, os

def _main(description):
    
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

        suite = os.path.basename(os.path.dirname(os.path.realpath(__file__)))
        ci.set_host_port(host,port)
        try:
            ci.delete(suite, True)
        except Exception as e:
            if not "could not find node" in e.args:
                print(type(e))
                print(e.args)
            
        ci.load(suite+".def")  # read definition from disk and load into the server
        ci.begin_suite(suite)
    
    except RuntimeError as e:
        print("Failed:", e)

if __name__ == "__main__":
    _main(__doc__)

