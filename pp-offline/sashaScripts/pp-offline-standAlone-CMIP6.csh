#!/bin/csh
# Created by nanr
# Redone by sglanvil (Sep/26/2023) 
module load ncl nco

setenv CESM2_TOOLS_ROOT /glade/work/nanr/cesm_tags/CASE_tools/cesm2-smyle-PACEMAKER/pp-offline/sashaScripts/
setenv DOUT_S_ROOT  /glade/scratch/sglanvil/SMYLE-PACEMAKER/archive/
setenv CASEROOT /glade/scratch/$USER/post-proc/
module use /glade/work/bdobbins/Software/Modules
module load cesm_postprocessing

foreach YEAR ( `seq 2004 2004` )
	foreach mbr ( `seq 7 10` )
		set mbr_padZeros = `printf %03d $mbr`
		set CASE = b.e21.BSMYLE.f09_g17.TBI-SOC_15d50m-anom.${YEAR}-02.${mbr_padZeros}
		set usembr = ${mbr_padZeros}
		mkdir -p $CASEROOT/$CASE
		cd $CASEROOT/$CASE
		if ( ! -d "postprocess" ) then
			create_postprocess -caseroot=`pwd`
		endif
		cd postprocess
#		pp_config --set TIMESERIES_OUTPUT_ROOTDIR=/glade/scratch/$USER/timeseries/$CASE
		pp_config --set TIMESERIES_OUTPUT_ROOTDIR=/glade/campaign/cesm/development/espwg/SMYLE-PACEMAKER/archive/$CASE
		pp_config --set CASE=$CASE
		pp_config --set DOUT_S_ROOT=$DOUT_S_ROOT/$CASE
		pp_config --set ATM_GRID=0.9x1.25
		pp_config --set LND_GRID=0.9x1.25
		pp_config --set ICE_GRID=gx1v7
		pp_config --set OCN_GRID=gx1v7
		pp_config --set ICE_NX=320
		pp_config --set ICE_NY=384
		mv timeseries timeseries-OTB
		cp $CESM2_TOOLS_ROOT/timeseries $CASEROOT/$CASE/postprocess
		# there is a hard-coded CASE in the timeseries file, so we need to replace it as we go...
		sed -i "s/b.e21.BSMYLE.f09_g17.TBI-PAC_15d50m-anom.1990-02.002/$CASE/g" $CASEROOT/$CASE/postprocess/timeseries
		qsub timeseries
	end 
end

exit

