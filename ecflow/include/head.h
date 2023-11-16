set -e          # stop the shell on first error
set -u          # fail when using an undefined variable
set -x          # echo script lines as they are executed
set -o pipefail # fail if last(rightmost) command exits with a non-zero status
 
# Defines the variables that are needed for any communication with ECF
export ECF_PORT=${ECF_PORT:=%ECF_PORT%}    # The server port number
export ECF_HOST=${ECF_HOST:=%ECF_HOST%}    # The host name where the server is running
export ECF_NAME=%ECF_NAME%    # The name of this current task
export ECF_PASS=%ECF_PASS%    # A unique password, used for job validation & zombie detection
export ECF_TRYNO=%ECF_TRYNO%  # Current try number of the task
export ECF_RID=$$             # record the process id. Also used for zombie detection
export FCST_HOME=%FCST_HOME%
export FCST_WORK=%FCST_WORK%
export CESM_ROOT=%CESM_ROOT%
export CESM_WORKFLOW=%CESM_WORKFLOW%

#source /etc/profile.d/z00_modules.sh
module load cesmdev/1.0 ncarenv/23.09 ecflow
module use %FCST_HOME%/modulefiles
module load %CESM_WORKFLOW%
  
# export NO_ECF=1             # uncomment to run as a standalone task on the command line
# Optionally define the path where to find ecflow_client
# make sure client and server use the *same* version.
# Important when there are multiple versions of ecFlow
# export PATH=/where/i/install/ecflow/%ECF_VERSION%/bin:$PATH
 
# Tell ecFlow we have started
ecflow_client --init=$$
 
 
# Define a error handler
ERROR() {
   set +e                      # Clear -e flag, so we don't fail
   wait                        # wait for background process to stop
   ecflow_client --abort=trap  # Notify ecFlow that something went wrong, using 'trap' as the reason
   trap 0                      # Remove the trap
   exit 0                      # End the script cleanly, server monitors child, an exit 1, will cause another abort and zombie
}
 
 
# Trap any calls to exit and errors caught by the -e flag
trap ERROR 0
 
 
# Trap any signal that may cause the script to fail
trap '{ echo "Killed by a signal"; ERROR ; }' 1 2 3 4 5 6 7 8 10 12 13 15
