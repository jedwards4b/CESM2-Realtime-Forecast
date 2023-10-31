help([[
  Set up the environment to run seasonal forecasts.
]])

conflict("70Lwaccm6")
conflict("cesm2cam6")

local user = os.getenv("USER")
local home = pathJoin("/glade/u/home/",user)
local work = pathJoin("/glade/work/",user,"/cases/cesm2cam6")
local scratch = pathJoin("/glade/",os.getenv("NCAR_HOST"),"/scratch/",user)
if(user == "ssfcst")
then
  pushenv("PS1",'$HOST: $USER:cesm2espstoch $PWD > ')
end

setenv("FCST_HOME", pathJoin(home, "/cesm2-espstoch/CESM2-Realtime-Forecast/"))
setenv("CESM_ROOT", pathJoin(home, "cesm2_1"))
setenv("WORK", work)
setenv("SCRATCH", scratch)
