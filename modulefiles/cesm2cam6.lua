help([[
  Set up the environment to run seasonal forecasts.
]])

conflict("70Lwaccm6")
conflict("cesm2cam6climoATMNS")
local machine = os.getenv("NCAR_HOST")
local user = os.getenv("USER")
local home = pathJoin("/glade/u/home/",user)
local work = pathJoin("/glade/work/",user,machine,"/cases/cesm2cam6")
if(machine == "cheyenne")
then
  local scratch = pathJoin("/glade/scratch/",user)
  setenv("SCRATCH", scratch)
end
if(user == "ssfcst")
then
  pushenv("PS1",'$HOST: $USER:cesm2cam6 $PWD > ')
end

setenv("CESM_WORKFLOW", "cesm2cam6")
setenv("FCST_HOME", pathJoin(home, "/cesm2cam6/CESM2-Realtime-Forecast/"))
setenv("CESM_ROOT", pathJoin(home, "cesm2_1"))
setenv("FCST_WORK", work)

