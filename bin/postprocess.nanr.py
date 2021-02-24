#! /usr/bin/env python
import os, sys, glob, shutil, subprocess
import distutils.dir_util
import json

# Get the casename 
for i in range(0, len(sys.argv)):
    if '-case' in sys.argv[i]:
        case_root = sys.argv[i+1]
        casename = os.path.basename(sys.argv[i+1])
    elif '-compset' in sys.argv[i]:
        compset = sys.argv[i+1]

#############################################################################
#
# User Modify Section
#
#############################################################################

# Central location for all of your cylc suites (it is recomended to keep this the same for all cylc suites)
suite_location = '/glade/u/home/'+os.environ['USER']+'/cylc_suites/'

# Email address to have cylc send wf status updates as it runs
email = 'nanr@ucar.edu'

# svn username
svn_username = "cmip6"

# Machine to run pp on (geyser, caldera, cheyenne, default)
ppmach = 'cheyenne'

# Set ensemble start and finish
ensemble_start = 1
ensemble_end = 10

# Add a specific queue to use.  Set to None if you want the default.  Set to 'queue name' if you want a specific queue.
queue = 'economy'


# Add/Revove/Modify any of the CESM xml variables you would like to set or change
cesm_xml={
         'RESUBMIT': '2',
         'STOP_N': '2',
         'STOP_OPTION': 'nyears',
         'DOUT_S': 'TRUE'
         }

# Add/Revove/Modify any of the post processing xml variables you would like to set or change
pp_xml={
       'GENERATE_TIMESERIES': 'TRUE',
       'STANDARDIZE_TIMESERIES': 'TRUE',
       'TIMESERIES_OUTPUT_ROOTDIR': '/gpfs/fs1/collections/cdg/timeseries-cmip6/'+case_root.split('/')[-1],
       'USER_NAME': 'nanr',
       'GLOBAL_WEBHOST': 'burnt.cgd.ucar.edu',
       'GLOBAL_WEBLOGIN': 'cmip6',
       'GLOBAL_REMOTE_WEBDIR': '/project/diagnostics/external/'+compset+'/'+casename
       }


def main(argv=None):
    # Location of cesm code base
    cesm_code_base = '/glade/work/nanr/cesm_tags/cesm2.1.4-SMYLE/"

    create(cesm_code_base, testing=False)



def create(cesm_code_base, testing=True, command=None):

    #############################################################################
    #
    # Do not make any changes below this line
    #
    #############################################################################

    first = True
    first_case_root = None
    cdir = os.getcwd()

    for i in range(ensemble_start,ensemble_end+1):
	n = str(i).zfill(3)

	print '############################################'
	print ''
	print '   Create CESM Case '+n
        print '   Using code base: '+cesm_code_base
	print ''
	print '############################################'
	print ''
	os.chdir(cesm_code_base+'/cime/scripts/')
        if command == None:
            new_case = ' '.join(sys.argv)
        else:
            new_case = command
	new_case = new_case.replace(os.path.basename(__file__),'create_newcase')
	for i in range(0, len(sys.argv)):
	    if '-case' in sys.argv[i]:
		case_root = sys.argv[i+1]
        new_case = new_case.replace(case_root, case_root+'.'+n)
       #new_case = new_case.replace(case_root, case_root+n)
	case_root = case_root+'.'+n
	err=os.system(new_case)
	if err!=0:
	    print '\033[91m','Error: Failed to create new CESM case.','\033[0m'
	    print '\033[91m','Tried running: ',new_case,'\033[0m'
	    sys.exit()
	os.chdir(case_root)
        case_root = os.getcwd()
        if first:
            first_case_root = case_root
            ensemble_path = case_root[:-4]
            first = False

	if os.path.isfile(os.environ['POSTPROCESS_PATH']+'/cesm-env2/bin/activate_this.py'):
	    print '############################################'
	    print ''
	    print '   Create CESM Postprocessing '+n
            print '   Using '+os.environ['POSTPROCESS_PATH']+'/cesm-env2'
	    print ''
	    print '############################################'
	    print ''
	    # Save old values
	    old_os_path = os.environ['PATH']
	    old_sys_path = list(sys.path)
	    old_sys_prefix = sys.prefix
	    activate_file = os.environ['POSTPROCESS_PATH']+'/cesm-env2/bin/activate_this.py'
	    execfile(activate_file, dict(__file__=activate_file))
	    err=os.system('create_postprocess -caseroot '+case_root)
	    if err!=0:
		print '\033[91m','Error: Failed to create post processing','\033[0m'                            
		print '\033[91m','Tried running: ','create_postprocess -caseroot '+case_root,'\033[0m'
		sys.exit()

            print '############################################'
            print ''
            print '   Getting experiment details from the db   '
            print ''
            print '############################################'
            print ''
            case_name = os.path.basename(os.path.normpath(case_root))


            print '############################################'
            print ''
            print '   Figuring out which variables need to be '
            print '   outputted by CESM'
            print ''
            print '############################################'
            print ''
            exp_name = 'cesm2-smyle'

	    # Get old values back
	    os.environ['PATH'] = old_os_path
	    sys.prefix = old_sys_prefix
	    sys.path[:0] = old_sys_path
	else:
	    print '\033[91m','Warning: Cannot add postprocessing to Cylc workflow because the package cannot be found.','\033[0m'
	    print '\033[91m','Execting: ',os.environ['POSTPROCESS_PATH']+'/cesm-env2/bin/activate_this.py','\033[0m'


	print '############################################'
	print ''
	print '   Set XML Variables '+n
	print ''
	print '############################################'
	print ''
	for k,v in cesm_xml.iteritems():
	    print 'Setting ',k,' to ',v
	    err=os.system('./xmlchange '+k+'='+v)
	    if err!=0:
		print '\033[91m','Error: Failed to change an xml variable','\033[0m'
		print '\033[91m','Tried running: ','./xmlchange '+k+'='+v,'\033[0m'
		sys.exit()
	if os.path.isdir(case_root+'/postprocess/'):
	    os.chdir(case_root+'/postprocess/')
	    for k,v in pp_xml.iteritems():
                if 'TIMESERIES_OUTPUT_ROOTDIR' in k:
                    v = v+'.'+n
                elif 'GLOBAL_REMOTE_WEBDIR' in k:
                    v = v+'.'+n+'/'
		print 'Setting ',k,' to ',v
		err=os.system('./pp_config --set '+k+'='+v)
		if err!=0:
		    print '\033[91m','Error: Failed to change a post processing xml variable','\033[0m'
		    print '\033[91m','Tried running: ','./pp_config --set '+k+'='+v,'\033[0m'
		    sys.exit()

	if cp_namelist == True or cp_namelist == 'TRUE' or cp_namelist == 'true':
	    print '############################################'
	    print ''
	    print '   Copy user_namelists '+n
	    print ''
	    print '############################################'
	    print ''
	    os.chdir(case_root)
	    for f in glob.glob(namelist_root+n+'/user_nl_*'):
		fn = os.path.basename(f)
		shutil.copyfile(f,case_root+'/'+fn)
		print 'Copied: ', f, ' to ', case_root+'/'+fn
	    err=os.system('./preview_namelists')
	    if err!=0:
		print '\033[91m','Error: Failed in call to preview_namelist','\033[0m'
		sys.exit() 

        os.chdir(case_root+'/postprocess/')
        conform = subprocess.check_output('./pp_config -value -caseroot '+case_root+'/postprocess/'+' --get STANDARDIZE_TIMESERIES', shell=True)

    
	print '##########################################################################'
	print ''
	print '   New CESM case created with Post Processing and Cylc Suite Enabled in'
	print '     '+first_case_root+'-'+case_root
	print '  '
	print '   Next steps: '
	if build == False or build == 'FALSE' or build == 'false':
	    print '               - build the cases'
	print '               - open this file to make sure the workflow looks as expected: '+suite_location+'/'+case_name_base+'.'+uid+'/workflow.png'
	print '                  - if the workflow is not what you expect, cd into your new case directory, modify cesm xml env, and run: '
	print '                    '+cdir+'/src/CESM_Cylc_setup -c '+ cesm_code_base+'/cime/'+' -p '+suite_location+'/'+case_name_base+'.'+uid+' -s '+case_name_base+'.'+uid+'.suite'+' -d '+ensemble_path+' -u '+svn_username+' -1 '+str(ensemble_start)+' -2 '+str(ensemble_end)+' -g workflow.png'+' -e '+email+' -m '+ppmach+' -q '+queue
	print '               - execute: gcylc '+case_name_base+'.'+uid+'.suite.cmip6'
	print ''
        print '   These instructions have also been written to '+first_case_root+"/Cylc.Instructions.txt"
	print '#########################################################################'
	print ''

if __name__ == '__main__':
    main()
