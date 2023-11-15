help([[
  Set up the environment to run seasonal forecasts.
]])

conflict("70Lwaccm6")

local workflow = os.getenv("CESM_WORKFLOW")
local work = pathJoin(os.getenv("WORK"),"derecho","cases",workflow)
local home = os.getenv("HOME")
if(user == "ssfcst")
then
  pushenv("PS1",'$HOST: $USER:'+workflow+' $PWD > ')
end
setenv("CESM_ROOT", pathJoin(home, "cesm2_1"))
setenv("FCST_HOME", pathJoin(home, workflow, "CESM2-Realtime-Forecast"))
