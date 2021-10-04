help([[
  Set up the environment to run cesm2cam6NS seasonal forecasts.
]])

conflict("70Lwaccm6")
conflict("cesm2cam6")

local user = os.getenv("USER")
local home = pathJoin("/glade/u/home/",user)
local work = pathJoin("/glade/work/",user,"/cases/cesm2cam6NS")
local scratch = pathJoin("/glade/scratch/",user,"cesm2cam6NS")

setenv("FCST_HOME", pathJoin(home, "/sandboxes/CESM2-Realtime-Forecast/"))
setenv("CESM_ROOT", pathJoin(home, "/sandboxes/cesm2_1"))
setenv("WORK", work)
setenv("SCRATCH", scratch)
