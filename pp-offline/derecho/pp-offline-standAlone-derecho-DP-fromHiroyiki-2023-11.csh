#!/bin/csh
# Created by nanr
# Redone by sglanvil (Sep/26/2023) 
module load ncl nco

setenv CESM2_TOOLS_ROOT /glade/work/nanr/cesm_tags/CASE_tools/cesm2-smyle-DP/pp-offline/derecho/
setenv DOUT_S_ROOT  /glade/derecho/scratch/nanr/SMYLE-DP/archive/fromHiroyuki/
setenv CASEROOT /glade/derecho/scratch/$USER/post-proc/DP-fromHiroyiki-2023-11/

# if ( ! -d "postprocess" ) then
   # module use /glade/work/bdobbins/Software/Modules
   # module load cesm_postprocessing_derecho
   # create_postprocess -caseroot=`pwd`
# endif

foreach YEAR ( `seq 2023 2023` )
	foreach mbr ( `seq 9 9` )
		set mbr_padZeros = `printf %03d $mbr`
		set CASE = b.e21.BSMYLE.f09_g17.${YEAR}-11.${mbr_padZeros}
		set usembr = ${mbr_padZeros}
		mkdir -p $CASEROOT/$CASE
		cd $CASEROOT/$CASE
		if ( ! -d "postprocess" ) then
   			module use /glade/work/bdobbins/Software/Modules
   			module load cesm_postprocessing_derecho
			create_postprocess -caseroot=`pwd`
		endif
		cd postprocess
#		pp_config --set TIMESERIES_OUTPUT_ROOTDIR=/glade/scratch/$USER/timeseries/$CASE
		pp_config --set TIMESERIES_OUTPUT_ROOTDIR=/glade/campaign/cesm/development/espwg/CESM2-DP/timeseries/fromHiroyuki/$CASE
		pp_config --set CASE=$CASE
		pp_config --set DOUT_S_ROOT=$DOUT_S_ROOT/$CASE
		pp_config --set ATM_GRID=0.9x1.25
		pp_config --set LND_GRID=0.9x1.25
		pp_config --set ICE_GRID=gx1v7
		pp_config --set OCN_GRID=gx1v7
		pp_config --set ICE_NX=320
		pp_config --set ICE_NY=384
		mv timeseries timeseries-OTB
		cp $CESM2_TOOLS_ROOT/timeseries-DP-fromHiroyiki-2023-11 $CASEROOT/$CASE/postprocess/timeseries
		# there is a hard-coded CASE in the timeseries file, so we need to replace it as we go...
		sed -i "s/MY_CASE_NAME/$CASE/g" $CASEROOT/$CASE/postprocess/timeseries
                sed -i "s/tPP/t.$YEAR-$mbr/g" $CASEROOT/$CASE/postprocess/timeseries
		qsub timeseries
	end 
end

exit

