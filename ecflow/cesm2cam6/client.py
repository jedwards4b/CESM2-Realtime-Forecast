import ecflow

try:
    print("Loading definition in 'cesm2cam6.def' into the server")
    ci = ecflow.Client()
    ci.delete_all()
    ci.set_host_port("derecho6",4238)
    ci.load("cesm2cam6.def")  # read definition from disk and load into the server
    ci.begin_suite("cesm2cam6")
    
except RuntimeError as e:
    print("Failed:", e)
