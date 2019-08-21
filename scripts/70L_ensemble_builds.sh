#!/usr/bin/env sh

date=1999-01-04 # pipe this to 70L_get_restarts.sh

# AT THIS POINT: run 70L_get_restarts.sh

pertDir=/glade/scratch/sglanvil/S2S_70LIC/FINAL/${date}-0.15_RFIC/ # cam.i perturbations (ensemble) dir
SDrestDir=/glade/scratch/sglanvil/S2S_70LIC_globus/SD/rest/$date/


for ensemble in {002..003};  do # usually {000..010}...do 1 day with higher NSPLIT...then go back down (need to figure this out)

echo -------------------------------------------
echo Creating Ensemble Number ... ${ensemble}
echo -------------------------------------------

cp ${pertDir}70Lwaccm6.cam.i.${date}-00000-${ensemble}.nc $SDrestDir/b.e21.BWHIST.SD.f09_g17.002.cam.i.${date}-00000.nc                                            
CESM_ROOT="/gpfs/u/home/cmip6/cesm_tags/cesm2.1.1-exp13/"
caseroot="/glade/work/sglanvil/cases_S2S/"
casename=70Lwaccm6.${date}-${ensemble}
res="f09_g17"
compset="BWHIST"

cd $CESM_ROOT/cime/scripts
./create_newcase --res $res --compset $compset --case $caseroot/$casename --queue regular --project NCGD0042 --mach cheyenne --run-unsupported 
cd $caseroot/$casename

./xmlchange RUN_TYPE="hybrid"
./xmlchange RUN_REFDIR="${SDrestDir}"
./xmlchange RUN_REFCASE="b.e21.BWHIST.SD.f09_g17.002"
./xmlchange RUN_REFDATE="${date}"
./xmlchange RUN_STARTDATE="${date}"
./xmlchange STOP_OPTION="ndays"
./xmlchange STOP_N=1
./xmlchange REST_OPTION="ndays"
./xmlchange REST_N=45
./xmlchange OCN_TRACER_MODULES=''
./xmlchange CCSM_BGC="CO2A"
./xmlchange PROJECT="P03010041"

./case.setup --clean
./case.setup

cp /glade/work/sglanvil/cases_S2S/cam_diagnostics.F90 $caseroot/$casename/SourceMods/src.cam/

cat <<EOF >> user_nl_pop
  chl_option='file'
EOF

cat <<EOF >> user_nl_cam
  fv_nsplit=16
  fv_nspltrac=16
  fv_nspltvrm=16
  avgflag_pertape = 'A', 'A', 'A', 'I', 'A'
  nhtfrq = 0, -24, -24, -6, -24
  mfilt = 1, 45, 1, 1, 1
  empty_htapes = .true. 
  fincl1 = ''
  fincl2 = 'U','V','T','OMEGA','Z3','PS','PHIS','Q','UQ','VQ','O3'
  fincl3 = 'PRECT','TS','FLUT','TREFHT','Q850','TREFHTMX','TREFHTMN','SHFLX','LHFLX','TAUX','TAUY','FSNS','ICEFRAC','CAPE','T100','T010','T030','T050','FLNT','FLNS','FSNT','FSNS','FLDS','FSDS','PRECC','PRECL','QREFHT','RHREFHT','RH600','PSL','PS','SNOWHICE','SNOWHLND','CLDTOT','TMQ','SST','LANDFRAC','OCNFRAC','UVzm','VTHzm','UWzm','WTHzm','TROP_P','TROP_T','TREFHTMX','TREFHTMN'
  fincl4 = 'Z200','Z500','U850','U200','V850','V200','OMEGA500','PSL','PS','U100','V100','U10','UBOT','VBOT','Z850','U010','V010','U030','V030','U050','V050','Z010','Z030','Z050' 
  fincl5 = 'U_24_COS','U_24_SIN','U_12_COS','U_12_SIN','V_24_COS','V_24_SIN','V_12_COS','V_12_SIN','T_24_COS','T_24_SIN','T_12_COS','T_12_SIN'
EOF

cat <<EOF >> user_nl_clm
  hist_empty_htapes  = .true.
  hist_fincl1 = 'TLAI', 'NPP', 'GPP', 'AR', 'ER', 'NBP', 'QVEGT', 'CPHASE', 'TWS', 'QRUNOFF', 'H2OSOI','FSNO','H2OSNO','H2OCAN','SOILICE','QOVER','SOILWATER_10CM','SNOWDP'
  hist_mfilt = 45
  hist_nhtfrq = -24
EOF

cat <<EOF >> user_nl_mosart
  rtmhist_fincl1 = 'RIVER_DISCHARGE_OVER_LAND_LIQ', 'TOTAL_DISCHARGE_TO_OCEAN_LIQ'
  rtmhist_mfilt = 45
  rtmhist_nhtfrq = -24
EOF

cat <<EOF >> user_nl_cice
  histfreq = 'm','d','x','x','x'
  histfreq_n = 1,1,1,1,1
  f_snowfrac = 'mdxxx'
  f_aice = 'mdxxx'
  f_hi = 'mdxxx'
  f_hs = 'mdxxx'
  f_uvel = 'mdxxx'
  f_vvel = 'mdxxx'
  f_aicen = 'mdxxx'
  f_daidtt = 'mdxxx'
  f_daidtd = 'mdxxx'
  f_dvidtt = 'mdxxx'
  f_dvidtd = 'mdxxx'
  f_apond = 'mdxxx'
  f_meltb = 'mdxxx'
  f_meltt = 'mdxxx'
EOF

./case.build --clean
qcmd -- ./case.build
./case.submit

done

