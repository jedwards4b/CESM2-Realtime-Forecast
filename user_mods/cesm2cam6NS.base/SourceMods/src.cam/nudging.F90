module nudging
!=====================================================================
! Simplified
!=====================================================================
  ! Useful modules
  !------------------
  use shr_kind_mod,only:r8=>SHR_KIND_R8,cs=>SHR_KIND_CS,cl=>SHR_KIND_CL
  use time_manager, only:timemgr_time_ge,timemgr_time_inc,get_curr_date,get_step_size,is_first_step
  use phys_grid   ,only:scatter_field_to_chunk
  use cam_abortutils  ,only:endrun
  use spmd_utils  ,only:masterproc
  use cam_logfile ,only:iulog
#ifdef SPMD
  use mpishorthand
#endif

  ! Set all Global values and routines to private by default 
  ! and then explicitly set their exposure.
  !----------------------------------------------------------
  implicit none
  private

  public:: Nudge_Model,Nudge_ZMLin
  public:: nudging_readnl
  !public:: nudging_register
  public:: Nudge_tscale
  public:: nudging_init
  public:: nudging_timestep_init
  public:: nudging_timestep_tend
  public:: Nudge_p1bot, Nudge_p2bot, Nudge_lat1, Nudge_lat2, Nudge_latdelta
  public:: Nudge_p1top, Nudge_p2top
  private::nudging_update_analyses_fv
  private::nudging_update_analyses_fv_spec
  private::nudging_set_profile

  ! Nudging Parameters
  !--------------------
  logical::         Nudge_ZMLin = .false. !IRS
  logical::         Nudge_Model       =.false.
  logical::         Nudge_Initialized =.false.
  character(len=cl) Nudge_Path
  character(len=cs) Nudge_File,Nudge_File_Template,Nudge_Filep
  character(len=cl) Nudge_Spec_Path
  character(len=cs) Spec_File ,Nudge_Spec_Template
  logical::         LNudge_Q
  logical::         LNudge_U
  logical::         LNudge_V
  logical::         LNudge_T
  logical::         LNudge_PS
  logical::         LTend_Q
  logical::         LTend_U
  logical::         LTend_V
  logical::         LTend_T
  logical::         LTend_PS
  integer           Nudge_Times_Per_Day
  integer           Model_Times_Per_Day
!  real(r8)          Nudge_Ucoef,Nudge_Vcoef
!  integer           Nudge_Uprof,Nudge_Vprof
!  real(r8)          Nudge_Qcoef,Nudge_Tcoef
!  integer           Nudge_Qprof,Nudge_Tprof
!  real(r8)          Nudge_PScoef
!  integer           Nudge_PSprof
!  integer           Nudge_Beg_Year ,Nudge_Beg_Month
!  integer           Nudge_Beg_Day  ,Nudge_Beg_Sec
!  integer           Nudge_End_Year ,Nudge_End_Month
!  integer           Nudge_End_Day  ,Nudge_End_Sec
  integer           Nudge_Curr_Year,Nudge_Curr_Month
  integer           Nudge_Curr_Day ,Nudge_Curr_Sec
  integer           Nudge_Next_Year,Nudge_Next_Month
  integer           Nudge_Next_Day ,Nudge_Next_Sec
  integer           Nudge_Step
  integer           Model_Curr_Year,Model_Curr_Month
  integer           Model_Curr_Day ,Model_Curr_Sec
  integer           Model_Next_Year,Model_Next_Month
  integer           Model_Next_Day ,Model_Next_Sec
  integer           Model_Step
  real(r8)          Nudge_tscale
  real(r8)          Nudge_p1bot
  real(r8)          Nudge_p2bot
  real(r8)          Nudge_p1top
  real(r8)          Nudge_p2top
  logical::         NudgeQ_taper
  logical::         NudgeV_taper
  logical::         NudgeU_taper
  logical::         NudgeT_taper
  logical::         NudgeQ_taperlat
  logical::         NudgeV_taperlat
  logical::         NudgeU_taperlat
  logical::         NudgeT_taperlat
  real(r8)          Nudge_lat1
  real(r8)          Nudge_lat2
  real(r8)          Nudge_latdelta

  ! Nudging State Arrays
  !-----------------------
  integer Nudge_nlon,Nudge_nlat,Nudge_ncol,Nudge_nlev
  real(r8),allocatable::Target_U(:,:,:)     !(pcols,pver,begchunk:endchunk)
  real(r8),allocatable::Target_V(:,:,:)     !(pcols,pver,begchunk:endchunk)
  real(r8),allocatable::Target_T(:,:,:)     !(pcols,pver,begchunk:endchunk)
  real(r8),allocatable::Target_S(:,:,:)     !(pcols,pver,begchunk:endchunk)
  real(r8),allocatable::Target_Q(:,:,:)     !(pcols,pver,begchunk:endchunk)
  real(r8),allocatable::Target_PS(:,:)      !(pcols,begchunk:endchunk)
  real(r8),allocatable::Model_U(:,:,:)      !(pcols,pver,begchunk:endchunk)
  real(r8),allocatable::Model_V(:,:,:)      !(pcols,pver,begchunk:endchunk)
  real(r8),allocatable::Model_T(:,:,:)      !(pcols,pver,begchunk:endchunk)
  real(r8),allocatable::Model_S(:,:,:)      !(pcols,pver,begchunk:endchunk)
  real(r8),allocatable::Model_Q(:,:,:)      !(pcols,pver,begchunk:endchunk)
  real(r8),allocatable::Model_PS(:,:)       !(pcols,begchunk:endchunk)
  real(r8),allocatable::Nudge_Utau(:,:,:)   !(pcols,pver,begchunk:endchunk)
  real(r8),allocatable::Nudge_Vtau(:,:,:)   !(pcols,pver,begchunk:endchunk)
  real(r8),allocatable::Nudge_Stau(:,:,:)   !(pcols,pver,begchunk:endchunk)
  real(r8),allocatable::Nudge_Qtau(:,:,:)   !(pcols,pver,begchunk:endchunk)
  real(r8),allocatable::Nudge_PStau(:,:)    !(pcols,begchunk:endchunk)
  real(r8),allocatable::Nudge_Ustep(:,:,:)  !(pcols,pver,begchunk:endchunk)
  real(r8),allocatable::Nudge_Vstep(:,:,:)  !(pcols,pver,begchunk:endchunk)
  real(r8),allocatable::Nudge_Sstep(:,:,:)  !(pcols,pver,begchunk:endchunk)
  real(r8),allocatable::Nudge_Qstep(:,:,:)  !(pcols,pver,begchunk:endchunk)
  real(r8),allocatable::Nudge_PSstep(:,:)   !(pcols,begchunk:endchunk)

! ****IRS
  real(r8), allocatable::Target_Szm(:,:,:) !(pcols,pver,begchunk:endchunk)
  real(r8), allocatable::Target_Uzm(:,:,:) !(pcols,pver,begchunk:endchunk)
  real(r8), allocatable::Target_Vzm(:,:,:) !(pcols,pver,begchunk:endchunk)
  real(r8), allocatable::Target_Qzm(:,:,:) !(pcols,pver,begchunk:endchunk)
  real(r8), allocatable::Model_Szm(:,:,:)      !(pcols,pver,begchunk:endchunk)
  real(r8), allocatable::Model_Uzm(:,:,:)      !(pcols,pver,begchunk:endchunk)
  real(r8), allocatable::Model_Vzm(:,:,:)      !(pcols,pver,begchunk:endchunk)
  real(r8), allocatable::Model_Qzm(:,:,:)      !(pcols,pver,begchunk:endchunk)
  real(r8), allocatable::Nobs_U_zm_1(:,:,:)
  real(r8), allocatable::Nobs_V_zm_1(:,:,:)
  real(r8), allocatable::Nobs_T_zm_1(:,:,:)
  real(r8), allocatable::Nobs_Q_zm_1(:,:,:)
  real(r8), allocatable::Nobs_U_zm_2(:,:,:)
  real(r8), allocatable::Nobs_V_zm_2(:,:,:)
  real(r8), allocatable::Nobs_T_zm_2(:,:,:)
  real(r8), allocatable::Nobs_Q_zm_2(:,:,:)

  ! Nudging Observation Arrays
  !-----------------------------
  integer               Nudge_NumObs
  integer,allocatable:: Nudge_ObsInd(:)
  logical ,allocatable::Nudge_File_Present(:)
!  real(r8)              Nudge_Acoef
!  real(r8),allocatable::Nudge_Bcoef(:)
!  real(r8),allocatable::Nudge_Ccoef(:)
  real(r8),allocatable::Nobs_U(:,:,:,:) !(pcols,pver,begchunk:endchunk,Nudge_NumObs)
  real(r8),allocatable::Nobs_V(:,:,:,:) !(pcols,pver,begchunk:endchunk,Nudge_NumObs)
  real(r8),allocatable::Nobs_T(:,:,:,:) !(pcols,pver,begchunk:endchunk,Nudge_NumObs)
  real(r8),allocatable::Nobs_Q(:,:,:,:) !(pcols,pver,begchunk:endchunk,Nudge_NumObs)
  real(r8),allocatable::Nobs_PS(:,:,:)  !(pcols,begchunk:endchunk,Nudge_NumObs)

  ! Specified Tendency Arrays
  !--------------------------
  logical ,allocatable::Spec_File_Present(:)
  real(r8),allocatable::Sndg_U(:,:,:,:) !(pcols,pver,begchunk:endchunk,Nudge_NumObs)
  real(r8),allocatable::Sndg_V(:,:,:,:) !(pcols,pver,begchunk:endchunk,Nudge_NumObs)
  real(r8),allocatable::Sndg_S(:,:,:,:) !(pcols,pver,begchunk:endchunk,Nudge_NumObs)
  real(r8),allocatable::Sndg_Q(:,:,:,:) !(pcols,pver,begchunk:endchunk,Nudge_NumObs)

  ! Physics Buffer Indices
  !------------------------
  integer:: NUDGE_UVAL_IDX = -1
  integer:: NUDGE_VVAL_IDX = -1
  integer:: NUDGE_SVAL_IDX = -1
  integer:: NUDGE_QVAL_IDX = -1

contains
  !================================================================
  subroutine nudging_readnl(nlfile)
   ! 
   ! NUDGING_READNL: Initialize default values controlling the Nudging 
   !                 process. Then read namelist values to override 
   !                 them.
   !===============================================================
   use ppgrid        ,only: pver
   use namelist_utils,only:find_group_name
   use units         ,only:getunit,freeunit
   !
   ! Arguments
   !-------------
   character(len=*),intent(in)::nlfile
   !
   ! Local Values
   !---------------
   integer ierr,unitn

   namelist /nudging_nl/ Nudge_Model,Nudge_Path,Nudge_Spec_Path,       &
                         Nudge_File_Template,Nudge_Spec_Template,      &
                         Nudge_Times_Per_Day,Model_Times_Per_Day,      &
                         LNudge_Q, LNudge_T, LNudge_U, LNudge_V, LNudge_PS,  &
                         LTend_Q, LTend_T, LTend_U, LTend_V, LTend_PS,       &
                         Nudge_Times_Per_Day, Model_Times_Per_Day, &
                         Nudge_tscale, Nudge_p1bot, Nudge_p2bot, &
                         Nudge_p1top, Nudge_p2top, &  
                         Nudge_lat1, Nudge_lat2, Nudge_latdelta, &
                         NudgeQ_taper, NudgeU_taper, NudgeV_taper, NudgeT_taper, &
                         NudgeQ_taperlat, NudgeU_taperlat, NudgeV_taperlat, & 
                         NudgeT_taperlat , &
                         Nudge_ZMLin

   ! Nudging is NOT initialized yet, For now
   ! Nudging will always begin/end at midnight.
   !--------------------------------------------
   Nudge_Initialized =.false.
   !Nudge_Beg_Sec=0
   !Nudge_End_Sec=0

   ! Set Default Namelist values
   !-----------------------------
   Nudge_Model         =.false.
   Nudge_ZMLin         =.false.
   Nudge_Path          ='./Data/YOTC_ne30np4_001/'
   Nudge_File_Template ='YOTC_ne30np4_L30.cam2.i.%y-%m-%d-%s.nc'
   Nudge_Spec_Path     ='/glade/scratch/USER/inputdata/nudging/'
   Nudge_Spec_Template ='Nudge.%y-%m-%d-%s.nc'
   LNudge_Q=.false.
   LNudge_T=.false.
   LNudge_U=.false.
   LNudge_V=.false.
   LNudge_PS=.false.
   LTend_Q=.false.
   LTend_T=.false.
   LTend_U=.false.
   LTend_V=.false.
   LTend_PS=.false.
   Nudge_Times_Per_Day=4
   Model_Times_Per_Day=4
   Nudge_tscale=6.
   Nudge_p1bot=1000.
   Nudge_p2bot=1000.
   Nudge_p1top=0.
   Nudge_p2top=0.
   Nudge_lat1=-90.
   Nudge_lat2=90.
   Nudge_latdelta=0.
   NudgeQ_taper=.false.
   NudgeU_taper=.false.
   NudgeV_taper=.false.
   NudgeT_taper=.false.
   NudgeQ_taperlat=.false.
   NudgeV_taperlat=.false.
   NudgeU_taperlat=.false.
   NudgeT_taperlat=.false.


   ! Read in namelist values
   !------------------------
   if(masterproc) then
     unitn = getunit()
     open(unitn,file=trim(nlfile),status='old')
     call find_group_name(unitn,'nudging_nl',status=ierr)
     if(ierr.eq.0) then
       read(unitn,nudging_nl,iostat=ierr)
       if(ierr.ne.0) then
         call endrun('nudging_readnl:: ERROR reading namelist')
       endif
     endif
     close(unitn)
     call freeunit(unitn)
   endif

   ! Broadcast namelist variables
   !------------------------------
#ifdef SPMD
   if (masterproc) then
    write(iulog,*),'???????????????'
    write(iulog,*),'Nudge_Path=',Nudge_Path
    write(iulog,*),'Nudge_File_Template=',Nudge_File_Template
    write(iulog,*),'Nudge_Spec_Path=',Nudge_Spec_Path
    write(iulog,*),'Nudge_Spec_Template=',Nudge_Spec_Template
    write(iulog,*),'Nudge_Model=',Nudge_Model
    write(iulog,*),'Nudge_Initialize=',Nudge_Initialized
    write(iulog,*),'LNudge_Q=',LNudge_Q
    write(iulog,*),'LNudge_U=',LNudge_U
    write(iulog,*),'LNudge_V=',LNudge_V
    write(iulog,*),'LNudge_T=',LNudge_T
    write(iulog,*),'LNudge_PS=',LNudge_PS
    write(iulog,*),'LTend_Q=',LTend_Q
    write(iulog,*),'LTend_U=',LTend_U
    write(iulog,*),'LTend_V=',LTend_V
    write(iulog,*),'LTend_T=',LTend_T
    write(iulog,*),'LTend_PS=',LTend_PS
    write(iulog,*),'Nudge_Times_Per_Day=',Nudge_Times_Per_Day
    write(iulog,*),'Model_Times_Per_Day=',Model_Times_Per_Day
    write(iulog,*),'Nudge_tscale=',Nudge_tscale
    write(iulog,*),'Nudge_p1bot=',Nudge_p1bot
    write(iulog,*),'Nudge_p2bot=',Nudge_p2bot
    write(iulog,*),'Nudge_p1top=',Nudge_p1top
    write(iulog,*),'Nudge_p2top=',Nudge_p2top
    write(iulog,*),'Nudge_lat1=',Nudge_lat1
    write(iulog,*),'Nudge_lat2=',Nudge_lat2
    write(iulog,*),'Nudge_latdelta=',Nudge_latdelta
    write(iulog,*),'NudgeQ_taper=',NudgeQ_taper
    write(iulog,*),'NudgeU_taper=',NudgeU_taper
    write(iulog,*),'NudgeV_taper=',NudgeV_taper
    write(iulog,*),'NudgeT_taper=',NudgeT_taper
    write(iulog,*),'NudgeQ_taperlat=',NudgeQ_taperlat
    write(iulog,*),'NudgeU_taperlat=',NudgeU_taperlat
    write(iulog,*),'NudgeV_taperlat=',NudgeV_taperlat
    write(iulog,*),'NudgeT_taperlat=',NudgeT_taperlat


   endif

   call mpibcast(Nudge_Path         ,len(Nudge_Path)         ,mpichar,0,mpicom)
   call mpibcast(Nudge_File_Template,len(Nudge_File_Template),mpichar,0,mpicom)
   call mpibcast(Nudge_Spec_Path    ,len(Nudge_Spec_Path)    ,mpichar,0,mpicom)
   call mpibcast(Nudge_Spec_Template,len(Nudge_Spec_Template),mpichar,0,mpicom)
   call mpibcast(Nudge_Model        , 1, mpilog, 0, mpicom)
   call mpibcast(Nudge_ZMLin        , 1, mpilog, 0, mpicom) !IRS
   call mpibcast(Nudge_Initialized  , 1, mpilog, 0, mpicom)
   call mpibcast(LNudge_Q            , 1, mpilog, 0, mpicom)
   call mpibcast(LNudge_U            , 1, mpilog, 0, mpicom)
   call mpibcast(LNudge_V            , 1, mpilog, 0, mpicom)
   call mpibcast(LNudge_T            , 1, mpilog, 0, mpicom)
   call mpibcast(LNudge_PS           , 1, mpilog, 0, mpicom)
   call mpibcast(LTend_Q            , 1, mpilog, 0, mpicom)
   call mpibcast(LTend_U            , 1, mpilog, 0, mpicom)
   call mpibcast(LTend_V            , 1, mpilog, 0, mpicom)
   call mpibcast(LTend_T            , 1, mpilog, 0, mpicom)
   call mpibcast(LTend_PS           , 1, mpilog, 0, mpicom)
   call mpibcast(Nudge_Times_Per_Day, 1, mpiint, 0, mpicom)
   call mpibcast(Model_Times_Per_Day, 1, mpiint, 0, mpicom)
   call mpibcast(Nudge_tscale       , 1, mpir8, 0, mpicom)
   call mpibcast(Nudge_p1bot     , 1, mpir8 , 0, mpicom)
   call mpibcast(Nudge_p2bot     , 1, mpir8 , 0, mpicom)
   call mpibcast(Nudge_p1top     , 1, mpir8 , 0, mpicom)
   call mpibcast(Nudge_p2top     , 1, mpir8 , 0, mpicom)
   call mpibcast(Nudge_lat1     , 1, mpir8 , 0, mpicom)
   call mpibcast(Nudge_lat2     , 1, mpir8 , 0, mpicom)
   call mpibcast(Nudge_latdelta , 1, mpir8 , 0, mpicom)
   call mpibcast(NudgeQ_taper, 1, mpilog, 0, mpicom)
   call mpibcast(NudgeU_taper, 1, mpilog, 0, mpicom)
   call mpibcast(NudgeV_taper, 1, mpilog, 0, mpicom)
   call mpibcast(NudgeT_taper, 1, mpilog, 0, mpicom)
   call mpibcast(NudgeQ_taperlat, 1, mpilog, 0, mpicom)
   call mpibcast(NudgeU_taperlat, 1, mpilog, 0, mpicom)
   call mpibcast(NudgeV_taperlat, 1, mpilog, 0, mpicom)
   call mpibcast(NudgeT_taperlat, 1, mpilog, 0, mpicom)
#endif

   ! End Routine
   !------------
   return
  end subroutine ! nudging_readnl
  !================================================================


  !================================================================
!  subroutine nudging_register
!   ! 
!   ! NUDGING_REGISTER: Register model state fields in the physics buffer 
!   !                   to be used for bulk estimates of dynamics and
!   !                   physics tendencies.
!   !===============================================================
!   use ppgrid        ,only: pver,pcols
!   use physics_buffer,only: pbuf_add_field,dtype_r8
!   !
!   ! Local Values
!   !---------------
!   if(Nudge_Model) then
!     call pbuf_add_field('NUDGE_UVAL','global',dtype_r8,(/pcols,pver/),NUDGE_UVAL_IDX)
!     call pbuf_add_field('NUDGE_VVAL','global',dtype_r8,(/pcols,pver/),NUDGE_VVAL_IDX)
!     call pbuf_add_field('NUDGE_SVAL','global',dtype_r8,(/pcols,pver/),NUDGE_SVAL_IDX)
!     call pbuf_add_field('NUDGE_QVAL','global',dtype_r8,(/pcols,pver/),NUDGE_QVAL_IDX)
!   endif
!
!   ! End Routine
!   !------------
!   return
!  end subroutine ! nudging_register
!  !================================================================

  !================================================================
  subroutine nudging_init
   ! 
   ! NUDGING_INIT: Allocate space and initialize Nudging values
   !===============================================================
   use ppgrid        ,only: pver,pcols,begchunk,endchunk
   use error_messages,only: alloc_err
   use dycore        ,only: dycore_is
   use dyn_grid      ,only: get_horiz_grid_dim_d
   use phys_grid     ,only: get_rlat_p,get_rlon_p,get_ncols_p
!   use cam_history,  only: addfld, phys_decomp
   use cam_history, only: addfld,horiz_only
   use shr_const_mod ,only: SHR_CONST_PI

   ! Local values
   !----------------
   integer  Year,Month,Day,Sec
   integer  YMD1,YMD
   logical  After_Beg,Before_End
   integer  istat,lchnk,ncol,icol,ilev
   integer  hdim1_d,hdim2_d
   real(r8) rlat,rlon
   real(r8) Wprof(pver)
   real(r8) lonp,lon0,lonn,latp,lat0,latn
   integer               nn
   real(r8)              NumObs,Freq

   !IRS
   integer :: dtime
   dtime=get_step_size()

   ! Allocate Space for Nudging data arrays
   !-----------------------------------------
   allocate(Target_U(pcols,pver,begchunk:endchunk),stat=istat)
   call alloc_err(istat,'nudging_init','Target_U',pcols*pver*((endchunk-begchunk)+1))
   allocate(Target_V(pcols,pver,begchunk:endchunk),stat=istat)
   call alloc_err(istat,'nudging_init','Target_V',pcols*pver*((endchunk-begchunk)+1))
   allocate(Target_T(pcols,pver,begchunk:endchunk),stat=istat)
   call alloc_err(istat,'nudging_init','Target_T',pcols*pver*((endchunk-begchunk)+1))
   allocate(Target_S(pcols,pver,begchunk:endchunk),stat=istat)
   call alloc_err(istat,'nudging_init','Target_S',pcols*pver*((endchunk-begchunk)+1))
   allocate(Target_Q(pcols,pver,begchunk:endchunk),stat=istat)
   call alloc_err(istat,'nudging_init','Target_Q',pcols*pver*((endchunk-begchunk)+1))
   allocate(Target_PS(pcols,begchunk:endchunk),stat=istat)
   call alloc_err(istat,'nudging_init','Target_PS',pcols*((endchunk-begchunk)+1))

   allocate(Model_U(pcols,pver,begchunk:endchunk),stat=istat)
   call alloc_err(istat,'nudging_init','Model_U',pcols*pver*((endchunk-begchunk)+1))
   allocate(Model_V(pcols,pver,begchunk:endchunk),stat=istat)
   call alloc_err(istat,'nudging_init','Model_V',pcols*pver*((endchunk-begchunk)+1))
   allocate(Model_T(pcols,pver,begchunk:endchunk),stat=istat)
   call alloc_err(istat,'nudging_init','Model_T',pcols*pver*((endchunk-begchunk)+1))
   allocate(Model_S(pcols,pver,begchunk:endchunk),stat=istat)
   call alloc_err(istat,'nudging_init','Model_S',pcols*pver*((endchunk-begchunk)+1))
   allocate(Model_Q(pcols,pver,begchunk:endchunk),stat=istat)
   call alloc_err(istat,'nudging_init','Model_Q',pcols*pver*((endchunk-begchunk)+1))
   allocate(Model_PS(pcols,begchunk:endchunk),stat=istat)
   call alloc_err(istat,'nudging_init','Model_PS',pcols*((endchunk-begchunk)+1))

   ! ****IRS
   allocate(Target_Szm(pcols,pver,begchunk:endchunk),stat=istat)
   call alloc_err(istat,'nudging_init','Target_Szm',pcols*pver*((endchunk-begchunk)+1))
   allocate(Target_Uzm(pcols,pver,begchunk:endchunk),stat=istat)
   call alloc_err(istat,'nudging_init','Target_Uzm',pcols*pver*((endchunk-begchunk)+1))
   allocate(Target_Vzm(pcols,pver,begchunk:endchunk),stat=istat)
   call alloc_err(istat,'nudging_init','Target_Vzm',pcols*pver*((endchunk-begchunk)+1))
   allocate(Target_Qzm(pcols,pver,begchunk:endchunk),stat=istat)
   call alloc_err(istat,'nudging_init','Target_Qzm',pcols*pver*((endchunk-begchunk)+1))

   allocate(Model_Szm(pcols,pver,begchunk:endchunk),stat=istat)
   call alloc_err(istat,'nudging_init','Model_Szm',pcols*pver*((endchunk-begchunk)+1))
   allocate(Model_Uzm(pcols,pver,begchunk:endchunk),stat=istat)
   call alloc_err(istat,'nudging_init','Model_Uzm',pcols*pver*((endchunk-begchunk)+1))
   allocate(Model_Vzm(pcols,pver,begchunk:endchunk),stat=istat)
   call alloc_err(istat,'nudging_init','Model_Vzm',pcols*pver*((endchunk-begchunk)+1))
   allocate(Model_Qzm(pcols,pver,begchunk:endchunk),stat=istat)
   call alloc_err(istat,'nudging_init','Model_Qzm',pcols*pver*((endchunk-begchunk)+1))

   allocate(Nobs_U_zm_1(pcols,pver,begchunk:endchunk),stat=istat)
   call alloc_err(istat,'nudging_init','Nobs_U_zm_1',pcols*pver*((endchunk-begchunk)+1))
   allocate(Nobs_V_zm_1(pcols,pver,begchunk:endchunk),stat=istat)
   call alloc_err(istat,'nudging_init','Nobs_V_zm_1',pcols*pver*((endchunk-begchunk)+1))
   allocate(Nobs_T_zm_1(pcols,pver,begchunk:endchunk),stat=istat)
   call alloc_err(istat,'nudging_init','Nobs_T_zm_1',pcols*pver*((endchunk-begchunk)+1))
   allocate(Nobs_Q_zm_1(pcols,pver,begchunk:endchunk),stat=istat)
   call alloc_err(istat,'nudging_init','Nobs_Q_zm_1',pcols*pver*((endchunk-begchunk)+1))

   allocate(Nobs_U_zm_2(pcols,pver,begchunk:endchunk),stat=istat)
   call alloc_err(istat,'nudging_init','Nobs_U_zm_2',pcols*pver*((endchunk-begchunk)+1))
   allocate(Nobs_V_zm_2(pcols,pver,begchunk:endchunk),stat=istat)
   call alloc_err(istat,'nudging_init','Nobs_V_zm_2',pcols*pver*((endchunk-begchunk)+1))
   allocate(Nobs_T_zm_2(pcols,pver,begchunk:endchunk),stat=istat)
   call alloc_err(istat,'nudging_init','Nobs_T_zm_2',pcols*pver*((endchunk-begchunk)+1))
   allocate(Nobs_Q_zm_2(pcols,pver,begchunk:endchunk),stat=istat)
   call alloc_err(istat,'nudging_init','Nobs_Q_zm_2',pcols*pver*((endchunk-begchunk)+1))
   ! ---end IRS



   allocate(Nudge_Utau(pcols,pver,begchunk:endchunk),stat=istat)
   call alloc_err(istat,'nudging_init','Nudge_Utau',pcols*pver*((endchunk-begchunk)+1))
   allocate(Nudge_Vtau(pcols,pver,begchunk:endchunk),stat=istat)
   call alloc_err(istat,'nudging_init','Nudge_Vtau',pcols*pver*((endchunk-begchunk)+1))
   allocate(Nudge_Stau(pcols,pver,begchunk:endchunk),stat=istat)
   call alloc_err(istat,'nudging_init','Nudge_Stau',pcols*pver*((endchunk-begchunk)+1))
   allocate(Nudge_Qtau(pcols,pver,begchunk:endchunk),stat=istat)
   call alloc_err(istat,'nudging_init','Nudge_Qtau',pcols*pver*((endchunk-begchunk)+1))
   allocate(Nudge_PStau(pcols,begchunk:endchunk),stat=istat)
   call alloc_err(istat,'nudging_init','Nudge_PStau',pcols*((endchunk-begchunk)+1))

   allocate(Nudge_Ustep(pcols,pver,begchunk:endchunk),stat=istat)
   call alloc_err(istat,'nudging_init','Nudge_Ustep',pcols*pver*((endchunk-begchunk)+1))
   allocate(Nudge_Vstep(pcols,pver,begchunk:endchunk),stat=istat)
   call alloc_err(istat,'nudging_init','Nudge_Vstep',pcols*pver*((endchunk-begchunk)+1))
   allocate(Nudge_Sstep(pcols,pver,begchunk:endchunk),stat=istat)
   call alloc_err(istat,'nudging_init','Nudge_Sstep',pcols*pver*((endchunk-begchunk)+1))
   allocate(Nudge_Qstep(pcols,pver,begchunk:endchunk),stat=istat)
   call alloc_err(istat,'nudging_init','Nudge_Qstep',pcols*pver*((endchunk-begchunk)+1))
   allocate(Nudge_PSstep(pcols,begchunk:endchunk),stat=istat)
   call alloc_err(istat,'nudging_init','Nudge_PSstep',pcols*((endchunk-begchunk)+1))

   ! Register output fields with the cam history module
   !-----------------------------------------------------
!   call addfld('Nudge_U'    , 'm/s/s', pver, 'A', 'U  Nudging Tendency', phys_decomp)
!   call addfld('Nudge_V'    , 'm/s/s', pver, 'A', 'V  Nudging Tendency', phys_decomp)
!   call addfld('Nudge_T'    , 'Cp*K/s', pver, 'A', 'S  Nudging Tendency', phys_decomp)
!   call addfld('Nudge_Q'    , 'kg/kg/s', pver, 'A', 'Q  Nudging Tendency', phys_decomp)

    call addfld('Nudge_U'    , (/ 'lev' /), 'A', 'm/s/s'  ,'U  Nudging Tendency')
    call addfld('Nudge_V'    , (/ 'lev' /), 'A', 'm/s/s'  ,'V  Nudging Tendency')
    call addfld('Nudge_T'    , (/ 'lev' /), 'A', 'Cp*K/s' ,'S  Nudging Tendency')
    call addfld('Nudge_Q'    , (/ 'lev' /), 'A', 'kg/kg/s','Q  Nudging Tendency')

!    call addfld('Target_U'    , (/ 'lev' /), 'A', 'm/s/s'  ,'U  Nudging Target')
!    call addfld('Target_V'    , (/ 'lev' /), 'A', 'm/s/s'  ,'V  Nudging Target')
!    call addfld('Target_T'    , (/ 'lev' /), 'A', 'Cp*K/s' ,'S  Nudging Target')
!    call addfld('Target_Q'    , (/ 'lev' /), 'A', 'kg/kg/s','Q  Nudging Target')


!   call addfld('Spec_U'    , (/ 'lev' /), 'A', 'm/s/s'  ,'U  Specified Tendency')
!   call addfld('Spec_V'    , (/ 'lev' /), 'A', 'm/s/s'  ,'V  Specified Tendency')
!   call addfld('Spec_T'    , (/ 'lev' /), 'A', 'Cp*K/s' ,'S  Specified Tendency')
!   call addfld('Spec_Q'    , (/ 'lev' /), 'A', 'kg/kg/s','Q  Specified Tendency')
 
 
   !-----------------------------------------
   ! Values initialized only by masterproc
   !-----------------------------------------
   if(masterproc) then

     ! Set the Stepping intervals for Model and Nudging values
     ! Ensure that the Model_Step is not smaller then one timestep
     !  and not larger then the Nudge_Step.
     !--------------------------------------------------------
     Model_Step=86400/Model_Times_Per_Day
     Nudge_Step=86400/Nudge_Times_Per_Day
     if(Model_Step.lt.dtime) then
       write(iulog,*) ' '
       write(iulog,*) 'NUDGING: Model_Step cannot be less than a model timestep'
       write(iulog,*) 'NUDGING:  Setting Model_Step=dtime , dtime=',dtime
       write(iulog,*) ' '
       Model_Step=dtime
     endif
     if(Model_Step.gt.Nudge_Step) then
       write(iulog,*) ' '
       write(iulog,*) 'NUDGING: Model_Step cannot be more than Nudge_Step'
       write(iulog,*) 'NUDGING:  Setting Model_Step=Nudge_Step, Nudge_Step=',Nudge_Step
       write(iulog,*) ' '
       Model_Step=Nudge_Step
     endif

     ! Initialize column and level dimensions
     !--------------------------------------------------------
     call get_horiz_grid_dim_d(hdim1_d,hdim2_d)
     Nudge_nlon=hdim1_d
     Nudge_nlat=hdim2_d
     Nudge_ncol=hdim1_d*hdim2_d
     Nudge_nlev=pver

     ! Check the time relative to the nudging window
     !------------------------------------------------
     call get_curr_date(Year,Month,Day,Sec)
   !  YMD=(Year*10000) + (Month*100) + Day
   !  YMD1=(Nudge_Beg_Year*10000) + (Nudge_Beg_Month*100) + Nudge_Beg_Day
   !  call timemgr_time_ge(YMD1,Nudge_Beg_Sec,         &
   !                       YMD ,Sec          ,After_Beg)
   !  YMD1=(Nudge_End_Year*10000) + (Nudge_End_Month*100) + Nudge_End_Day
   !  call timemgr_time_ge(YMD ,Sec          ,          &
   !                       YMD1,Nudge_End_Sec,Before_End)
  
       ! Set Time indicies so that the next call to 
       ! timestep_init will initialize the data arrays.
       !--------------------------------------------
       Model_Next_Year =Year
       Model_Next_Month=Month
       Model_Next_Day  =Day
       Model_Next_Sec  =(Sec/Model_Step)*Model_Step
       Nudge_Next_Year =Year
       Nudge_Next_Month=Month
       Nudge_Next_Day  =Day
       Nudge_Next_Sec  =(Sec/Nudge_Step)*Nudge_Step

       Nudge_NumObs=2

     allocate(Nudge_ObsInd(Nudge_NumObs),stat=istat)
     call alloc_err(istat,'nudging_init','Nudge_ObsInd',Nudge_NumObs)
     allocate(Nudge_File_Present(Nudge_NumObs),stat=istat)
     call alloc_err(istat,'nudging_init','Nudge_File_Present',Nudge_NumObs)
     do nn=1,Nudge_NumObs
       Nudge_ObsInd(nn) = Nudge_NumObs+1-nn
     end do
     allocate(Spec_File_Present(Nudge_NumObs),stat=istat)
     call alloc_err(istat,'nudging_init','Spec_File_Present',Nudge_NumObs)
     Nudge_File_Present(:)=.false.
     Spec_File_Present(:)=.false.

     ! Initialization is done, 
     !--------------------------
     Nudge_Initialized=.true.

     ! Check that this is a valid DYCORE model
     !------------------------------------------
!     if((.not.dycore_is('UNSTRUCTURED')).and. &
!        (.not.dycore_is('EUL')         ).and. &
!        (.not.dycore_is('LR')          )      ) then
!       call endrun('NUDGING IS CURRENTLY ONLY CONFIGURED FOR CAM-SE, FV, or EUL')
!     endif

     if (.not.dycore_is('LR')) then 
       call endrun('This Nudging modeul is only configured for FV')
     endif

     ! Informational Output
     !---------------------------
     write(iulog,*) ' '
     write(iulog,*) '---------------------------------------------------------'
     write(iulog,*) '  MODEL NUDGING INITIALIZED WITH THE FOLLOWING SETTINGS: '
     write(iulog,*) '---------------------------------------------------------'
     write(iulog,*) 'NUDGING: Nudge_Model=',Nudge_Model
     write(iulog,*) 'NUDGING: Nudge_ZMLin=',Nudge_ZMLin !IRS
     write(iulog,*) 'NUDGING: Nudge_Path=',Nudge_Path
     write(iulog,*) 'NUDGING: Nudge_File_Template =',Nudge_File_Template
     write(iulog,*) 'NUDGING: Nudge_Spec_Path=',Nudge_Spec_Path
     write(iulog,*) 'NUDGING: Nudge_Spec_Template =',Nudge_Spec_Template
     write(iulog,*) 'NUDGING: Nudge_Times_Per_Day=',Nudge_Times_Per_Day
     write(iulog,*) 'NUDGING: Model_Times_Per_Day=',Model_Times_Per_Day
     write(iulog,*) 'NUDGING: Nudge_Step=',Nudge_Step
     write(iulog,*) 'NUDGING: Model_Step=',Model_Step
     write(iulog,*) 'NUDGING: LNudge_Q=',LNudge_Q
     write(iulog,*) 'NUDGING: LNudge_T=',LNudge_T
     write(iulog,*) 'NUDGING: LNudge_U=',LNudge_U
     write(iulog,*) 'NUDGING: LNudge_V=',LNudge_V
     write(iulog,*) 'NUDGING: LNudge_PS=',LNudge_PS
     write(iulog,*) 'NUDGING: LTend_Q=',LTend_Q
     write(iulog,*) 'NUDGING: LTend_T=',LTend_T
     write(iulog,*) 'NUDGING: LTend_U=',LTend_U
     write(iulog,*) 'NUDGING: LTend_V=',LTend_V
     write(iulog,*) 'NUDGING: LTend_PS=',LTend_PS
     write(iulog,*) 'Nudge_tscale = ',Nudge_tscale
     write(iulog,*) 'NUDGING: Nudge_Initialized   =',Nudge_Initialized
     write(iulog,*) 'NUDGING: Nudge_p1bot = ',Nudge_p1bot 
     write(iulog,*) 'NUDGING: Nudge_p2bot = ',Nudge_p2bot
     write(iulog,*) 'NUDGING: Nudge_p1top = ',Nudge_p1top
     write(iulog,*) 'NUDGING: Nudge_p2top = ',Nudge_p2top
     write(iulog,*) ' '
     write(iulog,*) ' '

   endif ! (masterproc) then

   ! Broadcast other variables that have changed
   !---------------------------------------------
#ifdef SPMD
   call mpibcast(Model_Step          ,            1, mpir8 , 0, mpicom)
   call mpibcast(Nudge_Step          ,            1, mpir8 , 0, mpicom)
   call mpibcast(Model_Next_Year     ,            1, mpiint, 0, mpicom)
   call mpibcast(Model_Next_Month    ,            1, mpiint, 0, mpicom)
   call mpibcast(Model_Next_Day      ,            1, mpiint, 0, mpicom)
   call mpibcast(Model_Next_Sec      ,            1, mpiint, 0, mpicom)
   call mpibcast(Nudge_Next_Year     ,            1, mpiint, 0, mpicom)
   call mpibcast(Nudge_Next_Month    ,            1, mpiint, 0, mpicom)
   call mpibcast(Nudge_Next_Day      ,            1, mpiint, 0, mpicom)
   call mpibcast(Nudge_Next_Sec      ,            1, mpiint, 0, mpicom)
   call mpibcast(Nudge_Model         ,            1, mpilog, 0, mpicom)
   call mpibcast(Nudge_ZMLin         ,            1, mpilog, 0, mpicom) !IRS
   call mpibcast(Nudge_Initialized   ,            1, mpilog, 0, mpicom)
   call mpibcast(Nudge_ncol          ,            1, mpiint, 0, mpicom)
   call mpibcast(Nudge_nlev          ,            1, mpiint, 0, mpicom)
   call mpibcast(Nudge_nlon          ,            1, mpiint, 0, mpicom)
   call mpibcast(Nudge_nlat          ,            1, mpiint, 0, mpicom)
   call mpibcast(Nudge_tscale      ,            1, mpir8, 0, mpicom)
   call mpibcast(Nudge_NumObs        ,            1, mpiint, 0, mpicom)
   call mpibcast(Nudge_p1bot            ,            1, mpir8, 0, mpicom)
   call mpibcast(Nudge_p2bot            ,            1, mpir8, 0, mpicom)
   call mpibcast(Nudge_p1top            ,            1, mpir8, 0, mpicom)
   call mpibcast(Nudge_p2top            ,            1, mpir8, 0, mpicom)
   call mpibcast(NudgeQ_taper        ,            1, mpilog, 0, mpicom)
   call mpibcast(NudgeT_taper        ,            1, mpilog, 0, mpicom)
   call mpibcast(NudgeU_taper        ,            1, mpilog, 0, mpicom)
   call mpibcast(NudgeV_taper        ,            1, mpilog, 0, mpicom)
   call mpibcast(NudgeQ_taperlat        ,            1, mpilog, 0, mpicom)
   call mpibcast(NudgeT_taperlat        ,            1, mpilog, 0, mpicom)
   call mpibcast(NudgeU_taperlat        ,            1, mpilog, 0, mpicom)
   call mpibcast(NudgeV_taperlat        ,            1, mpilog, 0, mpicom)
#endif

   ! All non-masterproc processes also need to allocate space
   ! before the broadcast of Nudge_NumObs dependent data.
   !------------------------------------------------------------
   if(.not.masterproc) then
     allocate(Nudge_ObsInd(Nudge_NumObs),stat=istat)
     call alloc_err(istat,'nudging_init','Nudge_ObsInd',Nudge_NumObs)
     allocate(Nudge_File_Present(Nudge_NumObs),stat=istat)
     call alloc_err(istat,'nudging_init','Nudge_File_Present',Nudge_NumObs)
     allocate(Spec_File_Present(Nudge_NumObs),stat=istat)
     call alloc_err(istat,'nudging_init','Spec_File_Present',Nudge_NumObs)
   endif
#ifdef SPMD
   call mpibcast(Nudge_ObsInd        , Nudge_NumObs, mpiint, 0, mpicom)
   call mpibcast(Nudge_File_Present  , Nudge_NumObs, mpilog, 0, mpicom)
   call mpibcast(Spec_File_Present   , Nudge_NumObs, mpilog, 0, mpicom)
#endif

   ! Allocate Space for Nudging observation arrays, initialize with 0's
   !---------------------------------------------------------------------
   allocate(Nobs_U(pcols,pver,begchunk:endchunk,Nudge_NumObs),stat=istat)
   call alloc_err(istat,'nudging_init','Nobs_U',pcols*pver*((endchunk-begchunk)+1)*Nudge_NumObs)
   allocate(Nobs_V(pcols,pver,begchunk:endchunk,Nudge_NumObs),stat=istat)
   call alloc_err(istat,'nudging_init','Nobs_V',pcols*pver*((endchunk-begchunk)+1)*Nudge_NumObs)
   allocate(Nobs_T(pcols,pver,begchunk:endchunk,Nudge_NumObs),stat=istat)
   call alloc_err(istat,'nudging_init','Nobs_T',pcols*pver*((endchunk-begchunk)+1)*Nudge_NumObs)
   allocate(Nobs_Q(pcols,pver,begchunk:endchunk,Nudge_NumObs),stat=istat)
   call alloc_err(istat,'nudging_init','Nobs_Q',pcols*pver*((endchunk-begchunk)+1)*Nudge_NumObs)
   allocate(Nobs_PS(pcols,begchunk:endchunk,Nudge_NumObs),stat=istat)
   call alloc_err(istat,'nudging_init','Nobs_PS',pcols*((endchunk-begchunk)+1)*Nudge_NumObs)

     allocate(Sndg_U(pcols,pver,begchunk:endchunk,Nudge_NumObs),stat=istat)
     call alloc_err(istat,'nudging_init','Sndg_U',pcols*pver*((endchunk-begchunk)+1)*Nudge_NumObs)
     allocate(Sndg_V(pcols,pver,begchunk:endchunk,Nudge_NumObs),stat=istat)
     call alloc_err(istat,'nudging_init','Sndg_V',pcols*pver*((endchunk-begchunk)+1)*Nudge_NumObs)
     allocate(Sndg_S(pcols,pver,begchunk:endchunk,Nudge_NumObs),stat=istat)
     call alloc_err(istat,'nudging_init','Sndg_S',pcols*pver*((endchunk-begchunk)+1)*Nudge_NumObs)
     allocate(Sndg_Q(pcols,pver,begchunk:endchunk,Nudge_NumObs),stat=istat)
     call alloc_err(istat,'nudging_init','Sndg_Q',pcols*pver*((endchunk-begchunk)+1)*Nudge_NumObs)
     Sndg_U(:pcols,:pver,begchunk:endchunk,:Nudge_NumObs)=0._r8
     Sndg_V(:pcols,:pver,begchunk:endchunk,:Nudge_NumObs)=0._r8
     Sndg_S(:pcols,:pver,begchunk:endchunk,:Nudge_NumObs)=0._r8
     Sndg_Q(:pcols,:pver,begchunk:endchunk,:Nudge_NumObs)=0._r8

   Nobs_U(:pcols,:pver,begchunk:endchunk,:Nudge_NumObs)=0._r8
   Nobs_V(:pcols,:pver,begchunk:endchunk,:Nudge_NumObs)=0._r8
   Nobs_T(:pcols,:pver,begchunk:endchunk,:Nudge_NumObs)=0._r8
   Nobs_Q(:pcols,:pver,begchunk:endchunk,:Nudge_NumObs)=0._r8
   Nobs_PS(:pcols     ,begchunk:endchunk,:Nudge_NumObs)=0._r8


!!DIAG
   if(masterproc) then
     write(iulog,*) 'NUDGING: nudging_init() OBS arrays allocated and initialized'
     write(iulog,*) 'NUDGING: nudging_init() SIZE#',(9*pcols*pver*((endchunk-begchunk)+1)*Nudge_NumObs)
     write(iulog,*) 'NUDGING: nudging_init() MB:',float(8*9*pcols*pver*((endchunk-begchunk)+1)*Nudge_NumObs)/(1024.*1024.)
     write(iulog,*) 'NUDGING: nudging_init() pcols=',pcols,' pver=',pver
     write(iulog,*) 'NUDGING: nudging_init() begchunk:',begchunk,' endchunk=',endchunk
     write(iulog,*) 'NUDGING: nudging_init() chunk:',(endchunk-begchunk+1),' Nudge_NumObs=',Nudge_NumObs
     write(iulog,*) 'NUDGING: nudging_init() Nudge_ObsInd=',Nudge_ObsInd
     write(iulog,*) 'NUDGING: nudging_init() Nudge_File_Present=',Nudge_File_Present
     write(iulog,*) 'NUDGING: nudging_init() Spec_File_Present=',Spec_File_Present
   endif
!!DIAG
  
    ! Initialize Nudging Coeffcient profiles in local arrays
    ! Load zeros into nudging arrays
    !------------------------------------------------------
    do lchnk=begchunk,endchunk
     ncol=get_ncols_p(lchnk)
     do icol=1,ncol
       rlat=get_rlat_p(lchnk,icol)*180._r8/SHR_CONST_PI
       rlon=get_rlon_p(lchnk,icol)*180._r8/SHR_CONST_PI

       call nudging_set_profile(rlat,rlon,NudgeU_taper,NudgeU_taperlat,Wprof,pver)
       Nudge_Utau(icol,:,lchnk)=Wprof(:)
       call nudging_set_profile(rlat,rlon,NudgeV_taper,NudgeV_taperlat,Wprof,pver)
       Nudge_Vtau(icol,:,lchnk)=Wprof(:)
       call nudging_set_profile(rlat,rlon,NudgeT_taper,NudgeT_taperlat,Wprof,pver)
       Nudge_Stau(icol,:,lchnk)=Wprof(:)
       call nudging_set_profile(rlat,rlon,NudgeQ_taper,NudgeQ_taperlat,Wprof,pver)
       Nudge_Qtau(icol,:,lchnk)=Wprof(:)
     end do



     Nudge_Ustep(:pcols,:pver,lchnk)=0._r8
     Nudge_Vstep(:pcols,:pver,lchnk)=0._r8
     Nudge_Sstep(:pcols,:pver,lchnk)=0._r8
     Nudge_Qstep(:pcols,:pver,lchnk)=0._r8
     Nudge_PSstep(:pcols,lchnk)=0._r8
     Target_U(:pcols,:pver,lchnk)=0._r8
     Target_V(:pcols,:pver,lchnk)=0._r8
     Target_T(:pcols,:pver,lchnk)=0._r8
     Target_S(:pcols,:pver,lchnk)=0._r8
     Target_Q(:pcols,:pver,lchnk)=0._r8
     Target_PS(:pcols,lchnk)=0._r8

     ! ******IRS
     Target_Szm(:pcols,:pver,lchnk)=0._r8
     Target_Uzm(:pcols,:pver,lchnk)=0._r8
     Target_Vzm(:pcols,:pver,lchnk)=0._r8
     Target_Qzm(:pcols,:pver,lchnk)=0._r8

     Model_Szm(:pcols,:pver,lchnk)=0._r8
     Model_Uzm(:pcols,:pver,lchnk)=0._r8
     Model_Vzm(:pcols,:pver,lchnk)=0._r8
     Model_Qzm(:pcols,:pver,lchnk)=0._r8



    end do

!   end do

   ! End Routine
   !------------
   return
  end subroutine ! nudging_init
  !================================================================


  !================================================================
  subroutine nudging_timestep_init(phys_state)
   ! 
   ! NUDGING_TIMESTEP_INIT: 
   !                 Check the current time and update Model/Nudging 
   !                 arrays when necessary. Toggle the Nudging flag
   !                 when the time is withing the nudging window.
   !===============================================================
   use physconst    ,only: cpair
   use physics_types,only: physics_state
   use constituents ,only: cnst_get_ind
   use dycore       ,only: dycore_is
   use ppgrid       ,only: pver,pcols,begchunk,endchunk
   use filenames    ,only: interpret_filename_spec
   use ESMF

   ! Arguments
   !-----------
   type(physics_state),intent(in):: phys_state(begchunk:endchunk)

   ! Local values
   !----------------
   integer Year,Month,Day,Sec
   integer YMD1,YMD2,YMD,YMDSNOW,YMDSPAST,YMDSNEXT
   logical Update_Model,Update_Nudge,Sync_Error
   logical After_Beg   ,Before_End
   integer lchnk,ncol,indw

   type(ESMF_Time) Date1,Date2
   type(ESMF_TimeInterval) DateDiff
!   real(r8) Date1, Date2
!   real(r8) DateDiff
   integer                 DeltaT
   real(r8)                Tscale
   real(r8)                Tfrac
   real(r8)                Tfcst
   integer                 rc
   integer                 nn
   integer                 kk
   real(r8)                Sbar,Qbar,Wsum

   real(r8) Utend (pcols,pver)
   real(r8) Vtend (pcols,pver)
   real(r8) Stend (pcols,pver)
   real(r8) Qtend (pcols,pver)
   real(r8) Mext_U(pcols,pver)
   real(r8) Mext_V(pcols,pver)
   real(r8) Mext_S(pcols,pver)
   real(r8) Mext_Q(pcols,pver)

   !IRS
   integer :: dtime
   dtime=get_step_size()

   ! Check if Nudging is initialized
   !---------------------------------
   if(.not.Nudge_Initialized) then
     call endrun('nudging_timestep_init:: Nudging NOT Initialized')
   endif

   ! Get Current time
   !--------------------
   call get_curr_date(Year,Month,Day,Sec)
   YMD=(Year*10000) + (Month*100) + Day
!
   !--------------------------------------------------------------
   ! When past the NEXT time, Update Model Arrays and time indices
   !--------------------------------------------------------------
   YMD1=(Model_Next_Year*10000) + (Model_Next_Month*100) + Model_Next_Day
   call timemgr_time_ge(YMD1,Model_Next_Sec,            &
                        YMD ,Sec           ,Update_Model)
!   if (masterproc) then 
!    write(iulog,*),'aaaa2'
!    write(iulog,*),'YMD=',YMD
!    write(iulog,*),'sec=',sec
!    write(iulog,*),'YMD1=',YMD1
!    write(iulog,*),'Update_Model=',Update_Model
!    write(iulog,*),'YMDSNOW=',YMDSNOW
!    write(iulog,*),'YMDSPAST=',YMDSPAST
!    write(iulog,*),'YMDSNEXT=',YMDSNEXT
!   endif


    if (Update_Model) then 
     ! Increment the Model times by the current interval
     !---------------------------------------------------
     Model_Curr_Year =Model_Next_Year
     Model_Curr_Month=Model_Next_Month
     Model_Curr_Day  =Model_Next_Day
     Model_Curr_Sec  =Model_Next_Sec
     YMD1=(Model_Curr_Year*10000) + (Model_Curr_Month*100) + Model_Curr_Day
     call timemgr_time_inc(YMD1,Model_Curr_Sec,              &
                           YMD2,Model_Next_Sec,Model_Step,0,0)

     ! Check for Sync Error where NEXT model time after the update
     ! is before the current time. If so, reset the next model 
     ! time to a Model_Step after the current time.
     !--------------------------------------------------------------
     call timemgr_time_ge(YMD2,Model_Next_Sec,            &
                          YMD ,Sec           ,Sync_Error)

     if(Sync_Error) then
       Model_Curr_Year =Year
       Model_Curr_Month=Month
       Model_Curr_Day  =Day
       Model_Curr_Sec  =Sec
       call timemgr_time_inc(YMD ,Model_Curr_Sec,              &
                             YMD2,Model_Next_Sec,Model_Step,0,0)
       write(iulog,*) 'NUDGING: WARNING - Model_Time Sync ERROR... CORRECTED'
     endif
     Model_Next_Year =(YMD2/10000)
     YMD2            = YMD2-(Model_Next_Year*10000)
     Model_Next_Month=(YMD2/100)
     Model_Next_Day  = YMD2-(Model_Next_Month*100)

     ! Load values at Current into the Model arrays
     !-----------------------------------------------
     call cnst_get_ind('Q',indw)
     do lchnk=begchunk,endchunk
       ncol=phys_state(lchnk)%ncol
       Model_U(:ncol,:pver,lchnk)=phys_state(lchnk)%u(:ncol,:pver)
       Model_V(:ncol,:pver,lchnk)=phys_state(lchnk)%v(:ncol,:pver)
       Model_T(:ncol,:pver,lchnk)=phys_state(lchnk)%t(:ncol,:pver)
       Model_Q(:ncol,:pver,lchnk)=phys_state(lchnk)%q(:ncol,:pver,indw)
       Model_PS(:ncol,lchnk)=phys_state(lchnk)%ps(:ncol)
     end do

     ! Load Dry Static Energy values for Model
     !-----------------------------------------
       !---------------------------------------
       do lchnk=begchunk,endchunk
         ncol=phys_state(lchnk)%ncol
         Model_S(:ncol,:pver,lchnk)=cpair*Model_T(:ncol,:pver,lchnk)
       end do
   endif ! (Update_Model) then


   !----------------------------------------------------------------
   ! When past the NEXT time, Update Nudging Arrays and time indices
   !----------------------------------------------------------------
   YMD1=(Nudge_Next_Year*10000) + (Nudge_Next_Month*100) + Nudge_Next_Day
   call timemgr_time_ge(YMD1,Nudge_Next_Sec,            &
                        YMD ,Sec           ,Update_Nudge)

!   if((Before_End).and.(Update_Nudge)) then
   if (Update_Nudge) then 
     ! Increment the Nudge times by the current interval
     !---------------------------------------------------
     Nudge_Curr_Year =Nudge_Next_Year
     Nudge_Curr_Month=Nudge_Next_Month
     Nudge_Curr_Day  =Nudge_Next_Day
     Nudge_Curr_Sec  =Nudge_Next_Sec
     YMD1=(Nudge_Curr_Year*10000) + (Nudge_Curr_Month*100) + Nudge_Curr_Day
     call timemgr_time_inc(YMD1,Nudge_Curr_Sec,              &
                           YMD2,Nudge_Next_Sec,Nudge_Step,0,0)
     Nudge_Next_Year =(YMD2/10000)
     YMD2            = YMD2-(Nudge_Next_Year*10000)
     Nudge_Next_Month=(YMD2/100)
     Nudge_Next_Day  = YMD2-(Nudge_Next_Month*100)

     ! At startup, we would like the current analysis data to be 
     ! initialized if it is available.
     !-----------------------------------------------------------

!     if (masterproc) then 
!      write(iulog,*),'is_first_step=',is_first_step
!     endif
     if(is_first_step()) then
       ! Set the analysis filename at the CURR time.
       !---------------------------------------------------------------
       Nudge_File=interpret_filename_spec(Nudge_File_Template      , &
                                           yr_spec=Nudge_Curr_Year , &
                                          mon_spec=Nudge_Curr_Month, &
                                          day_spec=Nudge_Curr_Day  , &
                                          sec_spec=Nudge_Curr_Sec    )
       Spec_File = interpret_filename_spec(Nudge_Spec_Template     , &
                                           yr_spec=Nudge_Curr_Year , &
                                          mon_spec=Nudge_Curr_Month, &
                                          day_spec=Nudge_Curr_Day  , &
                                          sec_spec=Nudge_Curr_Sec    )


       if (masterproc) then 
         if ((LNudge_Q).or.(LNudge_T).or.(LNudge_U).or.(LNudge_V).or.(LNudge_PS)) then 
          write(iulog,*) 'NUDGING: Reading analyses: first step',trim(Nudge_Path)//trim(Nudge_File)
         endif
         if ((LTend_Q).or.(LTend_T).or.(LTend_U).or.(LTend_V).or.(LTend_PS)) then 
          write(iulog,*) 'NUDGING: Reading Specified Tendencies: first step',trim(Nudge_Spec_Path )//trim(Spec_File)
         endif
       endif

       if ((LNudge_Q).or.(LNudge_T).or.(LNudge_U).or.(LNudge_V).or.(LNudge_PS)) then
        if (dycore_is('LR')) then
            call nudging_update_analyses_fv (trim(Nudge_Path)//trim(Nudge_File))
          endif
       endif
       if ((LTend_Q).or.(LTend_T).or.(LTend_U).or.(LTend_V).or.(LTend_PS)) then
        if (dycore_is('LR')) then
            call nudging_update_analyses_fv_spec(trim(Nudge_Spec_Path)&
           //trim(Spec_File))
        endif
       endif


     endif !(is_first_step()) then

     ! Set the analysis filename at the NEXT time.
     !---------------------------------------------------------------
     Nudge_File=interpret_filename_spec(Nudge_File_Template      , &
                                         yr_spec=Nudge_Next_Year , &
                                        mon_spec=Nudge_Next_Month, &
                                        day_spec=Nudge_Next_Day  , &
                                        sec_spec=Nudge_Next_Sec    )
     !!!!IRS.  Fixing restart logic issue.
     Nudge_Filep=interpret_filename_spec(Nudge_File_Template    , &
                                         yr_spec=Nudge_Curr_Year , &
                                         mon_spec=Nudge_Curr_Month , &
                                         day_spec=Nudge_Curr_Day , &
                                         sec_spec=Nudge_Curr_Sec )
     !!!!END IRS

     ! Set the specified tendency file to the current time
     Spec_File = interpret_filename_spec(Nudge_Spec_Template     , &
                                         yr_spec=Nudge_Curr_Year , &
                                        mon_spec=Nudge_Curr_Month, &
                                        day_spec=Nudge_Curr_Day  , &
                                        sec_spec=Nudge_Curr_Sec    )




      if (masterproc) then 
        if ((LNudge_Q).or.(LNudge_T).or.(LNudge_U).or.(LNudge_V).or.(LNudge_PS)) then 
         write(iulog,*) 'NUDGING: Reading analyses:',trim(Nudge_Path)//trim(Nudge_File)
         write(iulog,*) 'NUDGING: Reading past analyses:',trim(Nudge_Path)//trim(Nudge_Filep)
        endif
        if ((LTend_Q).or.(LTend_T).or.(LTend_U).or.(LTend_V).or.(LTend_PS)) then 
         write(iulog,*) 'NUDGING: Reading Specified Tendencies:',trim(Nudge_Spec_Path )//trim(Spec_File)
        endif
      endif


      if ((LNudge_Q).or.(LNudge_T).or.(LNudge_U).or.(LNudge_V).or.(LNudge_PS)) then
        if (dycore_is('LR')) then 
          call nudging_update_analyses_fv (trim(Nudge_Path)//trim(Nudge_File))
        endif
      endif

      if ((LTend_Q).or.(LTend_T).or.(LTend_U).or.(LTend_V).or.(LTend_PS)) then  
        if (dycore_is('LR')) then
          call nudging_update_analyses_fv_spec(trim(Nudge_Spec_Path)&
         //trim(Spec_File))
       endif
     endif

      !****IRS
      ! Reading in target data at initial time.  Not needed after first time step
      if (masterproc) then
        write(iulog,*),'IRS before reading initial file'
        write(iulog,*),'Nobs_T=',Nobs_T(1,1,begchunk,Nudge_ObsInd(2))
      endif
      if (Nobs_T(1,1,begchunk,Nudge_ObsInd(2)).eq.0) then
       if (masterproc) then
         write(iulog,*),'IRS in update_analysis_fv_init if statement'
       endif
       call nudging_update_analyses_fv_init(trim(Nudge_Path)//trim(Nudge_Filep))
      endif

      if (masterproc) then 
        write(iulog,*),'IRS after reading initial file T=',Nobs_T(1,1,begchunk,Nudge_ObsInd(2))
      endif

      if (Nudge_ZMLin) then
         if (LNudge_U) then 
           call zmcalc(Nobs_U(:pcols,:pver,begchunk:endchunk,Nudge_ObsInd(1)),Nobs_U_zm_1)
           call zmcalc(Nobs_U(:pcols,:pver,begchunk:endchunk,Nudge_ObsInd(2)),Nobs_U_zm_2)
         endif
         if (LNudge_V) then 
           call zmcalc(Nobs_V(:pcols,:pver,begchunk:endchunk,Nudge_ObsInd(1)),Nobs_V_zm_1)
           call zmcalc(Nobs_V(:pcols,:pver,begchunk:endchunk,Nudge_ObsInd(2)),Nobs_V_zm_2)
         endif
         if (LNudge_T) then 
           call zmcalc(Nobs_T(:pcols,:pver,begchunk:endchunk,Nudge_ObsInd(1)),Nobs_T_zm_1)
           call zmcalc(Nobs_T(:pcols,:pver,begchunk:endchunk,Nudge_ObsInd(2)),Nobs_T_zm_2)
         endif
         if (LNudge_Q) then 
           call zmcalc(Nobs_Q(:pcols,:pver,begchunk:endchunk,Nudge_ObsInd(1)),Nobs_T_zm_1)
           call zmcalc(Nobs_Q(:pcols,:pver,begchunk:endchunk,Nudge_ObsInd(2)),Nobs_T_zm_2)
         endif
      endif

     endif ! end if (Update_Nudge) so that it updates the actual target every timestep
     ! ****END IRS 





     ! Now Load the Target values for nudging tendencies
     !---------------------------------------------------

     ! Linearly interpolat between CURR and NEXT times
     if ((LNudge_Q).or.(LNudge_T).or.(LNudge_U).or.(LNudge_V).or.(LNudge_PS)) then

!       call ESMF_TimeSet(Date1,YY=Year,MM=Month,DD=Day,S=Sec)
!       call ESMF_TimeSet(Date2,YY=Nudge_Curr_Year,MM=Nudge_Curr_Month, &
!                               DD=Nudge_Curr_Day , S=Nudge_Curr_Sec    )
!       DateDiff =Date1-Date2
!       call ESMF_TimeIntervalGet(DateDiff,S=DeltaT,rc=rc)
!       Tfrac=float(DeltaT)/float(Nudge_Step)
         Tfrac = ((real(Model_Curr_Sec)-real(Nudge_Curr_Sec))/(real(Nudge_Next_Sec)-real(Nudge_Curr_Sec)))
         if (Nudge_Next_Sec.eq.0) then
          Tfrac = ((real(Model_Curr_Sec)-real(Nudge_Curr_Sec))/(86400.-real(Nudge_Curr_Sec)))
         endif

!       if (masterproc) then 
!         write(iulog,*),'IRS YMDSNOW=',YMDSNOW
!         write(iulog,*),'IRS YMDSPAST=',YMDSPAST
!        write(iulog,*),'IRS Tfrac l1167=',Tfrac
!        write(iulog,*),'IRS Nudge_Step l1167=',Nudge_Step
!       endif

        if (masterproc) then
          write(iulog,*),'IRS Nobs_Q_zm_2=',Nobs_T_zm_2(1,1,begchunk)
          write(iulog,*),'IRS Nobs_Q_zm_1=',Nobs_T_zm_1(1,1,begchunk)
          write(iulog,*),'IRS Tfrac=',Tfrac
        endif


       do lchnk=begchunk,endchunk
         ncol=phys_state(lchnk)%ncol

         if (Nudge_ZMLin) then 
           
           if (LNudge_Q) then
              Target_Q(:ncol,:pver,lchnk)=(1._r8-Tfrac)*Nobs_Q_zm_2(:ncol,:pver,lchnk) &
                                        +      Tfrac *Nobs_Q_zm_1(:ncol,:pver,lchnk)
            endif
            if (LNudge_T) then
              Target_T(:ncol,:pver,lchnk)=(1._r8-Tfrac)*Nobs_T_zm_2(:ncol,:pver,lchnk) &
                                        +      Tfrac *Nobs_T_zm_1(:ncol,:pver,lchnk)
            endif
            if (LNudge_U) then
              Target_U(:ncol,:pver,lchnk)=(1._r8-Tfrac)*Nobs_U_zm_2(:ncol,:pver,lchnk) &
                                        +      Tfrac *Nobs_U_zm_1(:ncol,:pver,lchnk)
            endif
            if (LNudge_V) then
              Target_V(:ncol,:pver,lchnk)=(1._r8-Tfrac)*Nobs_V_zm_2(:ncol,:pver,lchnk) &
                                        +      Tfrac *Nobs_V_zm_1(:ncol,:pver,lchnk)
            endif

         else

            if (LNudge_Q) then 
              Target_Q(:ncol,:pver,lchnk)=(1._r8-Tfrac)*Nobs_Q(:ncol,:pver,lchnk,Nudge_ObsInd(2)) &
                                        +      Tfrac *Nobs_Q(:ncol,:pver,lchnk,Nudge_ObsInd(1))
            endif
            if (LNudge_T) then 
              Target_T(:ncol,:pver,lchnk)=(1._r8-Tfrac)*Nobs_T(:ncol,:pver,lchnk,Nudge_ObsInd(2)) &
                                        +      Tfrac *Nobs_T(:ncol,:pver,lchnk,Nudge_ObsInd(1))
            endif
            if (LNudge_U) then 
              Target_U(:ncol,:pver,lchnk)=(1._r8-Tfrac)*Nobs_U(:ncol,:pver,lchnk,Nudge_ObsInd(2)) &
                                        +      Tfrac *Nobs_U(:ncol,:pver,lchnk,Nudge_ObsInd(1))
            endif
            if (LNudge_V) then 
              Target_V(:ncol,:pver,lchnk)=(1._r8-Tfrac)*Nobs_V(:ncol,:pver,lchnk,Nudge_ObsInd(2)) &
                                        +      Tfrac *Nobs_V(:ncol,:pver,lchnk,Nudge_ObsInd(1))
            endif
            if (LNudge_PS) then 
              Target_PS(:ncol     ,lchnk)=(1._r8-Tfrac)*Nobs_PS(:ncol     ,lchnk,Nudge_ObsInd(2)) &
                                        +      Tfrac *Nobs_PS(:ncol     ,lchnk,Nudge_ObsInd(1))
            endif

         end if
       enddo
      endif

      if (masterproc) then 
       write(iulog,*),'IRS Target_T=',Target_T(1,1,begchunk)
      endif

      !if (masterproc) then 
      !  write(iulog,*),'?????Nobs_T_obsind2=',Nobs_T(5,5,begchunk,Nudge_ObsInd(2))
      !  write(iulog,*),'?????Nobs_T_obsind1=',Nobs_T(5,5,begchunk,Nudge_ObsInd(1))
      !endif


     !Isla 14 08 15
        !DSE tendencies---------------------------------------
       if (LNudge_T) then
        do lchnk=begchunk,endchunk
          ncol=phys_state(lchnk)%ncol
          Target_S(:ncol,:pver,lchnk)=cpair*Target_T(:ncol,:pver,lchnk)
        end do
       endif


       ! IRS
       if (Nudge_ZMLin) then

         if (LNudge_T) then 
 !          call zmcalc(Target_S,Target_Szm)
           call zmcalc(Model_S,Model_Szm)
         endif

         if (LNudge_U) then 
 !         call zmcalc(Target_U,Target_Uzm)
          call zmcalc(Model_U,Model_Uzm)
         endif

         if (LNudge_V) then
 !         call zmcalc(Target_V,Target_Vzm)
          call zmcalc(Model_V,Model_Vzm)
         endif

         if (LNudge_Q) then 
 !         call zmcalc(Target_Q,Target_Qzm)
          call zmcalc(Model_Q,Model_Qzm)
         endif
       endif
       ! END IRS



!   endif ! (Update_Nudge) then

    if (Update_Model) then 

      !Nudge_tscal = nudging timescale in hours
      Tscale=1./(Nudge_tscale*3600.)

      if (Nudge_ZMLin) then  ! IRS
      
       do lchnk=begchunk,endchunk
         ncol=phys_state(lchnk)%ncol

         if (LNudge_U) then
         Nudge_Ustep(:ncol,:pver,lchnk) = ( Target_U(:ncol,:pver,lchnk) &
                                        - Model_Uzm(:ncol,:pver,lchnk) ) &
                                        *Tscale*Nudge_Utau(:ncol,:pver,lchnk) !&
                                        !*(1./dimh1d)
         endif

         if (LNudge_V) then 
         Nudge_Vstep(:ncol,:pver,lchnk) = ( Target_V(:ncol,:pver,lchnk) &
                                        - Model_Vzm(:ncol,:pver,lchnk) ) &
                                        *Tscale*Nudge_Vtau(:ncol,:pver,lchnk) !& 
                                        !*(1./dimh1d)
         endif

         if (LNudge_T) then 
         Nudge_Sstep(:ncol,:pver,lchnk) = ( Target_S(:ncol,:pver,lchnk) &
                                        - Model_Szm(:ncol,:pver,lchnk) ) &
                                       *Tscale*Nudge_Stau(:ncol,:pver,lchnk) !&
                                       !*(1./dimh1d)
         endif

         if (LNudge_Q) then 
         Nudge_Qstep(:ncol,:pver,lchnk) = ( Target_Q(:ncol,:pver,lchnk) &
                                        - Model_Qzm(:ncol,:pver,lchnk) ) &
                                        *Tscale*Nudge_Qtau(:ncol,:pver,lchnk)! &
                                        !*(1./dimh1d)
         endif
        end do

      else

      do lchnk=begchunk,endchunk
        Nudge_Ustep(:pcols,:pver,lchnk)=0._r8
        Nudge_Vstep(:pcols,:pver,lchnk)=0._r8
        Nudge_Sstep(:pcols,:pver,lchnk)=0._r8
        Nudge_Qstep(:pcols,:pver,lchnk)=0._r8
        Nudge_PSstep(:pcols,lchnk)=0._r8

        ncol=phys_state(lchnk)%ncol
        !---U
        if (LNudge_U) then 
          Nudge_Ustep(:ncol,:pver,lchnk)=(  Target_U(:ncol,:pver,lchnk)      &
                                           -Model_U(:ncol,:pver,lchnk))     &
                                        *Tscale*Nudge_Utau(:ncol,:pver,lchnk)
        endif 
        if (LTend_U) then 
          Nudge_Ustep(:ncol,:pver,lchnk)=Nudge_Ustep(:ncol,:pver,lchnk) & 
                                         +Sndg_U(:ncol,:pver,lchnk,Nudge_ObsInd(1))
        endif     
        !---
        !---V
        if (LNudge_V) then 
          Nudge_Vstep(:ncol,:pver,lchnk)=(  Target_V(:ncol,:pver,lchnk)      &
                                           -Model_V(:ncol,:pver,lchnk))     &
                                        *Tscale*Nudge_Vtau(:ncol,:pver,lchnk)
        endif
        if (LTend_V) then 
           Nudge_Vstep(:ncol,:pver,lchnk)=Nudge_Vstep(:ncol,:pver,lchnk) & 
                                         +Sndg_V(:ncol,:pver,lchnk,Nudge_ObsInd(1))
        endif  
        !---
        !---T
        if (LNudge_T) then 
          Nudge_Sstep(:ncol,:pver,lchnk)=(  Target_S(:ncol,:pver,lchnk)      &
                                           -Model_S(:ncol,:pver,lchnk))     &
                                        *Tscale*Nudge_Stau(:ncol,:pver,lchnk)
        endif
        if (LTend_T) then 
          Nudge_Sstep(:ncol,:pver,lchnk)=Nudge_Sstep(:ncol,:pver,lchnk) & 
                                         +Sndg_S(:ncol,:pver,lchnk,Nudge_ObsInd(1))
        endif 
        !----
        !----Q
        if (LNudge_Q) then 
          Nudge_Qstep(:ncol,:pver,lchnk)=(  Target_Q(:ncol,:pver,lchnk)      &
                                           -Model_Q(:ncol,:pver,lchnk))     &
                                        *Tscale*Nudge_Qtau(:ncol,:pver,lchnk)
        endif
        if (LTend_Q) then 
          Nudge_Qstep(:ncol,:pver,lchnk)=Nudge_Qstep(:ncol,:pver,lchnk) & 
                                         +Sndg_Q(:ncol,:pver,lchnk,Nudge_ObsInd(1))
        endif 
        !----
        !----PS 
        if (LNudge_PS) then 
          Nudge_PSstep(:ncol,     lchnk)=(  Target_PS(:ncol,lchnk)      &
                                           -Model_PS(:ncol,lchnk))     &
                                        *Tscale
        endif
        !---- 
   end do

   endif ! Nudge_ZMLin IRS

!   if (masterproc) then 
!      write(iulog,*),'IRS Nudge_Sstep after tendency update=',Nudge_Sstep(5,5,begchunk)
!!      write(iulog,*),'YY=',YY,' MM=',MM,' DD=',DD,' SS=',SS
!!      write(iulog,*),'IRS Date1=',Date1
!!      write(iulog,*),'IRS Date2=',Date2
!      write(iulog,*),'IRS Tfrac=',Tfrac
!      write(iulog,*),'IRS Target=',Target_S(1,1,begchunk)
!      write(iulog,*),'IRS Model=',Model_S(1,1,begchunk)
!   endif

   endif ! ((Before_End).and.((Update_Nudge).or.(Update_Model))) then

   ! End Routine
   !------------
   return
  end subroutine ! nudging_timestep_init
  !================================================================


  !================================================================
  subroutine nudging_timestep_tend(phys_state,phys_tend)
   ! 
   ! NUDGING_TIMESTEP_TEND: 
   !                If Nudging is ON, return the Nudging contributions 
   !                to forcing using the current contents of the Nudge 
   !                arrays. Send output to the cam history module as well.
   !===============================================================
   use physconst    ,only: cpair
   use physics_types,only: physics_state,physics_ptend,physics_ptend_init
   use constituents ,only: cnst_get_ind,pcnst
   use ppgrid       ,only: pver,pcols,begchunk,endchunk
   use cam_history  ,only: outfld

   ! Arguments
   !-------------
   type(physics_state), intent(in) :: phys_state
   type(physics_ptend), intent(out):: phys_tend

   ! Local values
   !--------------------
   integer indw,ncol,lchnk
   logical lq(pcnst)

   call cnst_get_ind('Q',indw)
   lq(:)   =.false.
   lq(indw)=.true.
   call physics_ptend_init(phys_tend,phys_state%psetcols,'nudging',lu=.true.,lv=.true.,ls=.true.,lq=lq)

     lchnk=phys_state%lchnk
     ncol =phys_state%ncol
     phys_tend%u(:ncol,:pver)     =Nudge_Ustep(:ncol,:pver,lchnk)
     phys_tend%v(:ncol,:pver)     =Nudge_Vstep(:ncol,:pver,lchnk)
     phys_tend%s(:ncol,:pver)     =Nudge_Sstep(:ncol,:pver,lchnk)
     phys_tend%q(:ncol,:pver,indw)=Nudge_Qstep(:ncol,:pver,lchnk)

!     if (masterproc) then 
!     write(iulog,*) 'cccccc Before Outfld'
!     write(iulog,*) 'Nudge_Sstep at phys_tend=',Nudge_Sstep(5,5,lchnk)
!     endif

     call outfld('Nudge_U',phys_tend%u          ,pcols,lchnk)
     call outfld('Nudge_V',phys_tend%v          ,pcols,lchnk)
     call outfld('Nudge_T',phys_tend%s          ,pcols,lchnk)
     call outfld('Nudge_Q',phys_tend%q(1,1,indw),pcols,lchnk)
!      write(iulog,*) 'ADDIN ON THE NUDGING TENDENCY '

   ! End Routine
   !------------
   return
  end subroutine ! nudging_timestep_tend
  !================================================================

  !================================================================
  subroutine nudging_update_analyses_fv(anal_file)
   ! 
   ! NUDGING_UPDATE_ANALYSES_FV: 
   !                 Open the given analyses data file, read in 
   !                 U,V,T,Q, and PS values and then distribute
   !                 the values to all of the chunks.
   ! Modified Isla 14 08 15 to read in specified nudging tendency
   !   as in the equivalent subroutine for the se core.
   !===============================================================
   use ppgrid ,only: pver,begchunk
   use netcdf

   ! Arguments
   !-------------
   character(len=*),intent(in):: anal_file

   ! Local values
   !-------------
   integer lev
   integer nlon,nlat,plev,istat
   integer ncid,varid
   integer ilat,ilon,ilev
   real(r8) Xanal(Nudge_nlon,Nudge_nlat,Nudge_nlev)
   real(r8) PSanal(Nudge_nlon,Nudge_nlat)
   real(r8) Lat_anal(Nudge_nlat)
   real(r8) Lon_anal(Nudge_nlon)
   real(r8) Xtrans(Nudge_nlon,Nudge_nlev,Nudge_nlat)
   integer  nn,Nindex

   ! Rotate Nudge_ObsInd() indices, then check the existence of the analyses 
   ! file; broadcast the updated indices and file status to all the other MPI nodes. 
   ! If the file is not there, then just return.
   !------------------------------------------------------------------------
   if(masterproc) then
     Nindex=Nudge_ObsInd(Nudge_NumObs)
     do nn=Nudge_NumObs,2,-1
       Nudge_ObsInd(nn)=Nudge_ObsInd(nn-1)
     end do
     Nudge_ObsInd(1)=Nindex
     inquire(FILE=trim(anal_file),EXIST=Nudge_File_Present(Nudge_ObsInd(1)))
   endif
#ifdef SPMD
   call mpibcast(Nudge_File_Present, Nudge_NumObs, mpilog, 0, mpicom)
   call mpibcast(Nudge_ObsInd      , Nudge_NumObs, mpiint, 0, mpicom)
#endif
   if(.not.Nudge_File_Present(Nudge_ObsInd(1))) return

   ! masterporc does all of the work here
   !-----------------------------------------
   if(masterproc) then
   
     ! Open the given file
     !-----------------------
     istat=nf90_open(trim(anal_file),NF90_NOWRITE,ncid)
     if(istat.ne.NF90_NOERR) then
       write(iulog,*)'NF90_OPEN: failed for file ',trim(anal_file)
       write(iulog,*) nf90_strerror(istat)
       call endrun ('UPDATE_ANALYSES_FV')
     endif

     ! Read in Dimensions
     !--------------------
     istat=nf90_inq_dimid(ncid,'lon',varid)
     if(istat.ne.NF90_NOERR) then
       write(iulog,*) nf90_strerror(istat)
       call endrun ('UPDATE_ANALYSES_FV')
     endif
     istat=nf90_inquire_dimension(ncid,varid,len=nlon)
     if(istat.ne.NF90_NOERR) then
       write(iulog,*) nf90_strerror(istat)
       call endrun ('UPDATE_ANALYSES_FV')
     endif

     istat=nf90_inq_dimid(ncid,'lat',varid)
     if(istat.ne.NF90_NOERR) then
       write(iulog,*) nf90_strerror(istat)
       call endrun ('UPDATE_ANALYSES_FV')
     endif
     istat=nf90_inquire_dimension(ncid,varid,len=nlat)
     if(istat.ne.NF90_NOERR) then
       write(iulog,*) nf90_strerror(istat)
       call endrun ('UPDATE_ANALYSES_FV')
     endif

     istat=nf90_inq_dimid(ncid,'lev',varid)
     if(istat.ne.NF90_NOERR) then
       write(iulog,*) nf90_strerror(istat)
       call endrun ('UPDATE_ANALYSES_FV')
     endif
     istat=nf90_inquire_dimension(ncid,varid,len=plev)
     if(istat.ne.NF90_NOERR) then
       write(iulog,*) nf90_strerror(istat)
       call endrun ('UPDATE_ANALYSES_FV')
     endif

     istat=nf90_inq_varid(ncid,'lon',varid)
     if(istat.ne.NF90_NOERR) then
       write(iulog,*) nf90_strerror(istat)
       call endrun ('UPDATE_ANALYSES_FV')
     endif
     istat=nf90_get_var(ncid,varid,Lon_anal)
     if(istat.ne.NF90_NOERR) then
       write(iulog,*) nf90_strerror(istat)
       call endrun ('UPDATE_ANALYSES_FV')
     endif

     istat=nf90_inq_varid(ncid,'lat',varid)
     if(istat.ne.NF90_NOERR) then
       write(iulog,*) nf90_strerror(istat)
       call endrun ('UPDATE_ANALYSES_FV')
     endif
     istat=nf90_get_var(ncid,varid,Lat_anal)
     if(istat.ne.NF90_NOERR) then
       write(iulog,*) nf90_strerror(istat)
       call endrun ('UPDATE_ANALYSES_FV')
     endif

     if((Nudge_nlon.ne.nlon).or.(Nudge_nlat.ne.nlat).or.(plev.ne.pver)) then
      write(iulog,*) 'ERROR: nudging_update_analyses_fv: nlon=',nlon,' Nudge_nlon=',Nudge_nlon
      write(iulog,*) 'ERROR: nudging_update_analyses_fv: nlat=',nlat,' Nudge_nlat=',Nudge_nlat
      write(iulog,*) 'ERROR: nudging_update_analyses_fv: plev=',plev,' pver=',pver
      call endrun('nudging_update_analyses_fv: analyses dimension mismatch')
     endif

     ! Read in, transpose lat/lev indices, 
     ! and scatter data arrays
     !----------------------------------
     istat=nf90_inq_varid(ncid,'U',varid)
     if(istat.ne.NF90_NOERR) then
       write(iulog,*) nf90_strerror(istat)
       call endrun ('UPDATE_ANALYSES_FV')
     endif
     istat=nf90_get_var(ncid,varid,Xanal)
     if(istat.ne.NF90_NOERR) then
       write(iulog,*) nf90_strerror(istat)
       call endrun ('UPDATE_ANALYSES_FV')
     endif
     do ilat=1,nlat
     do ilev=1,plev
     do ilon=1,nlon
       Xtrans(ilon,ilev,ilat)=Xanal(ilon,ilat,ilev)
     end do
     end do
     end do
   endif ! (masterproc) then
   call scatter_field_to_chunk(1,Nudge_nlev,1,Nudge_nlon,Xtrans,   &
                               Nobs_U(1,1,begchunk,Nudge_ObsInd(1)))

   if(masterproc) then
     istat=nf90_inq_varid(ncid,'V',varid)
     if(istat.ne.NF90_NOERR) then
       write(iulog,*) nf90_strerror(istat)
       call endrun ('UPDATE_ANALYSES_FV')
     endif
     istat=nf90_get_var(ncid,varid,Xanal)
     if(istat.ne.NF90_NOERR) then
       write(iulog,*) nf90_strerror(istat)
       call endrun ('UPDATE_ANALYSES_FV')
     endif
     do ilat=1,nlat
     do ilev=1,plev
     do ilon=1,nlon
       Xtrans(ilon,ilev,ilat)=Xanal(ilon,ilat,ilev)
     end do
     end do
     end do
   endif ! (masterproc) then
   call scatter_field_to_chunk(1,Nudge_nlev,1,Nudge_nlon,Xtrans,   &
                               Nobs_V(1,1,begchunk,Nudge_ObsInd(1)))

   if(masterproc) then
     istat=nf90_inq_varid(ncid,'T',varid)
     if(istat.ne.NF90_NOERR) then
       write(iulog,*) nf90_strerror(istat)
       call endrun ('UPDATE_ANALYSES_FV')
     endif
     istat=nf90_get_var(ncid,varid,Xanal)
     if(istat.ne.NF90_NOERR) then
       write(iulog,*) nf90_strerror(istat)
       call endrun ('UPDATE_ANALYSES_FV')
     endif
     do ilat=1,nlat
     do ilev=1,plev
     do ilon=1,nlon
       Xtrans(ilon,ilev,ilat)=Xanal(ilon,ilat,ilev)
     end do
     end do
     end do
   endif ! (masterproc) then
   call scatter_field_to_chunk(1,Nudge_nlev,1,Nudge_nlon,Xtrans,   &
                               Nobs_T(1,1,begchunk,Nudge_ObsInd(1)))

   if(masterproc) then
     istat=nf90_inq_varid(ncid,'Q',varid)
     if(istat.ne.NF90_NOERR) then
       write(iulog,*) nf90_strerror(istat)
       call endrun ('UPDATE_ANALYSES_FV')
     endif
     istat=nf90_get_var(ncid,varid,Xanal)
     if(istat.ne.NF90_NOERR) then
       write(iulog,*) nf90_strerror(istat)
       call endrun ('UPDATE_ANALYSES_FV')
     endif
     do ilat=1,nlat
     do ilev=1,plev
     do ilon=1,nlon
       Xtrans(ilon,ilev,ilat)=Xanal(ilon,ilat,ilev)
     end do
     end do
     end do
   endif ! (masterproc) then
   call scatter_field_to_chunk(1,Nudge_nlev,1,Nudge_nlon,Xtrans,   &
                               Nobs_Q(1,1,begchunk,Nudge_ObsInd(1)))

   if(masterproc) then
    istat=nf90_inq_varid(ncid,'PS',varid)
    if(istat.ne.NF90_NOERR) then
      write(iulog,*) nf90_strerror(istat)
      call endrun ('UPDATE_ANALYSES_SE')
    endif
    istat=nf90_get_var(ncid,varid,PSanal)
    if(istat.ne.NF90_NOERR) then
      write(iulog,*) nf90_strerror(istat)
      call endrun ('UPDATE_ANALYSES_SE')
    endif

     ! Close the analyses file
     !-----------------------
     istat=nf90_close(ncid)
     if(istat.ne.NF90_NOERR) then
       write(iulog,*) nf90_strerror(istat)
       call endrun ('UPDATE_ANALYSES_EUL')
     endif
   endif ! (masterproc) then
   call scatter_field_to_chunk(1,1,1,Nudge_nlon,PSanal,           &
                               Nobs_PS(1,begchunk,Nudge_ObsInd(1)))

  ! End Routine
   !------------
   return
  end subroutine ! nudging_update_analyses_fv

  !================================================================
  subroutine nudging_update_analyses_fv_init(anal_filep)
   ! ****IRS 02 17 16
   ! 
   ! NUDGING_UPDATE_ANALYSES_FV_INIT: 
   !                 Open the given analyses data file, read in 
   !                 U,V,T,Q, and PS values and then distribute
   !                 the values to all of the chunks.
   ! Modification of NUDGING_UPDATE_ANALYSES_FV to read in 
   ! initial analyses data.  No toggling of Nudge_ObsInd.
   ! and reading in to Nudge_Obs_Ind(2) which is where the value
   ! at the previou time is rewuired
   !===============================================================
   use ppgrid ,only: pver,begchunk
   use netcdf

   ! Arguments
   !-------------
   character(len=*),intent(in):: anal_filep

   ! Local values
   !-------------
   integer lev
   integer nlon,nlat,plev,istat
   integer ncid,varid
   integer ilat,ilon,ilev
   real(r8) Xanal(Nudge_nlon,Nudge_nlat,Nudge_nlev)
   real(r8) PSanal(Nudge_nlon,Nudge_nlat)
   real(r8) Lat_anal(Nudge_nlat)
   real(r8) Lon_anal(Nudge_nlon)
   real(r8) Xtrans(Nudge_nlon,Nudge_nlev,Nudge_nlat)
   integer  nn,Nindex

   ! Rotate Nudge_ObsInd() indices, then check the existence of the analyses 
   ! file; broadcast the updated indices and file status to all the other MPI nodes. 
   ! If the file is not there, then just return.
   !------------------------------------------------------------------------

   ! masterporc does all of the work here
   !-----------------------------------------
   if(masterproc) then

     ! Open the given file
     !-----------------------
     istat=nf90_open(trim(anal_filep),NF90_NOWRITE,ncid)
     if(istat.ne.NF90_NOERR) then
       write(iulog,*)'NF90_OPEN: failed for file ',trim(anal_filep)
       write(iulog,*) nf90_strerror(istat)
       call endrun ('UPDATE_ANALYSES_FV')
     endif

     ! Read in Dimensions
     !--------------------
     istat=nf90_inq_dimid(ncid,'lon',varid)
     if(istat.ne.NF90_NOERR) then
       write(iulog,*) nf90_strerror(istat)
       call endrun ('UPDATE_ANALYSES_FV ??lon')
     endif
     istat=nf90_inquire_dimension(ncid,varid,len=nlon)
     if(istat.ne.NF90_NOERR) then
       write(iulog,*) nf90_strerror(istat)
       call endrun ('UPDATE_ANALYSES_FV ??lon2')
     endif

     istat=nf90_inq_dimid(ncid,'lat',varid)
     if(istat.ne.NF90_NOERR) then
       write(iulog,*) nf90_strerror(istat)
       call endrun ('UPDATE_ANALYSES_FV')
     endif
     istat=nf90_inquire_dimension(ncid,varid,len=nlat)
     if(istat.ne.NF90_NOERR) then
       write(iulog,*) nf90_strerror(istat)
       call endrun ('UPDATE_ANALYSES_FV')
     endif

     istat=nf90_inq_dimid(ncid,'lev',varid)
     if(istat.ne.NF90_NOERR) then
       write(iulog,*) nf90_strerror(istat)
       call endrun ('UPDATE_ANALYSES_FV')
     endif
     istat=nf90_inquire_dimension(ncid,varid,len=plev)
     if(istat.ne.NF90_NOERR) then
       write(iulog,*) nf90_strerror(istat)
       call endrun ('UPDATE_ANALYSES_FV')
     endif

     istat=nf90_inq_varid(ncid,'lon',varid)
     if(istat.ne.NF90_NOERR) then
       write(iulog,*) nf90_strerror(istat)
       call endrun ('UPDATE_ANALYSES_FV')
     endif
     istat=nf90_get_var(ncid,varid,Lon_anal)
     if(istat.ne.NF90_NOERR) then
       write(iulog,*) nf90_strerror(istat)
       call endrun ('UPDATE_ANALYSES_FV')
     endif

     istat=nf90_inq_varid(ncid,'lat',varid)
     if(istat.ne.NF90_NOERR) then
       write(iulog,*) nf90_strerror(istat)
       call endrun ('UPDATE_ANALYSES_FV')
     endif
     istat=nf90_get_var(ncid,varid,Lat_anal)
     if(istat.ne.NF90_NOERR) then
       write(iulog,*) nf90_strerror(istat)
       call endrun ('UPDATE_ANALYSES_FV')
     endif

     if((Nudge_nlon.ne.nlon).or.(Nudge_nlat.ne.nlat).or.(plev.ne.pver)) then
      write(iulog,*) 'ERROR: nudging_update_analyses_fv: nlon=',nlon,' Nudge_nlon=',Nudge_nlon
      write(iulog,*) 'ERROR: nudging_update_analyses_fv: nlat=',nlat,' Nudge_nlat=',Nudge_nlat
      write(iulog,*) 'ERROR: nudging_update_analyses_fv: plev=',plev,' pver=',pver
      call endrun('nudging_update_analyses_fv: analyses dimension mismatch')
     endif

     ! Read in, transpose lat/lev indices, 
     ! and scatter data arrays
     !----------------------------------
     istat=nf90_inq_varid(ncid,'U',varid)
     if(istat.ne.NF90_NOERR) then
       write(iulog,*) nf90_strerror(istat)
       call endrun ('UPDATE_ANALYSES_FV')
     endif
     istat=nf90_get_var(ncid,varid,Xanal)
     if(istat.ne.NF90_NOERR) then
       write(iulog,*) nf90_strerror(istat)
       call endrun ('UPDATE_ANALYSES_FV')
     endif
     do ilat=1,nlat
     do ilev=1,plev
     do ilon=1,nlon
       Xtrans(ilon,ilev,ilat)=Xanal(ilon,ilat,ilev)
     end do
     end do
     end do
   endif ! (masterproc) then
   call scatter_field_to_chunk(1,Nudge_nlev,1,Nudge_nlon,Xtrans,   &
                               Nobs_U(1,1,begchunk,Nudge_ObsInd(2)))

!   if (masterproc) then 
!     write(iulog,*) '????Nobs_U(5,5,1,1)=',Nobs_U(5,5,1,1)
!     write(iulog,*) '????Nobs_U(5,5,1,2)=',Nobs_U(5,5,1,2)
!   endif

   if(masterproc) then
     istat=nf90_inq_varid(ncid,'V',varid)
     if(istat.ne.NF90_NOERR) then
       write(iulog,*) nf90_strerror(istat)
       call endrun ('UPDATE_ANALYSES_FV')
     endif
     istat=nf90_get_var(ncid,varid,Xanal)
     if(istat.ne.NF90_NOERR) then
       write(iulog,*) nf90_strerror(istat)
       call endrun ('UPDATE_ANALYSES_FV')
     endif
     do ilat=1,nlat
     do ilev=1,plev
     do ilon=1,nlon
       Xtrans(ilon,ilev,ilat)=Xanal(ilon,ilat,ilev)
     end do
     end do
     end do
   endif ! (masterproc) then
   call scatter_field_to_chunk(1,Nudge_nlev,1,Nudge_nlon,Xtrans,   &
                               Nobs_V(1,1,begchunk,Nudge_ObsInd(2)))

   if(masterproc) then
     istat=nf90_inq_varid(ncid,'T',varid)
     if(istat.ne.NF90_NOERR) then
       write(iulog,*) nf90_strerror(istat)
       call endrun ('UPDATE_ANALYSES_FV')
     endif
     istat=nf90_get_var(ncid,varid,Xanal)
     if(istat.ne.NF90_NOERR) then
       write(iulog,*) nf90_strerror(istat)
       call endrun ('UPDATE_ANALYSES_FV')
     endif
     do ilat=1,nlat
     do ilev=1,plev
     do ilon=1,nlon
       Xtrans(ilon,ilev,ilat)=Xanal(ilon,ilat,ilev)
     end do
     end do
     end do
   endif ! (masterproc) then
   call scatter_field_to_chunk(1,Nudge_nlev,1,Nudge_nlon,Xtrans,   &
                               Nobs_T(1,1,begchunk,Nudge_ObsInd(2)))

   if(masterproc) then
     istat=nf90_inq_varid(ncid,'Q',varid)
     if(istat.ne.NF90_NOERR) then
       write(iulog,*) nf90_strerror(istat)
       call endrun ('UPDATE_ANALYSES_FV')
     endif
     istat=nf90_get_var(ncid,varid,Xanal)
     if(istat.ne.NF90_NOERR) then
       write(iulog,*) nf90_strerror(istat)
       call endrun ('UPDATE_ANALYSES_FV')
     endif
     do ilat=1,nlat
     do ilev=1,plev
     do ilon=1,nlon
       Xtrans(ilon,ilev,ilat)=Xanal(ilon,ilat,ilev)
     end do
     end do
     end do
   endif ! (masterproc) then
   call scatter_field_to_chunk(1,Nudge_nlev,1,Nudge_nlon,Xtrans,   &
                               Nobs_Q(1,1,begchunk,Nudge_ObsInd(2)))

   if(masterproc) then
    istat=nf90_inq_varid(ncid,'PS',varid)
    if(istat.ne.NF90_NOERR) then
      write(iulog,*) nf90_strerror(istat)
      call endrun ('UPDATE_ANALYSES_SE')
    endif
    istat=nf90_get_var(ncid,varid,PSanal)
    if(istat.ne.NF90_NOERR) then
      write(iulog,*) nf90_strerror(istat)
      call endrun ('UPDATE_ANALYSES_SE')
    endif

     ! Close the analyses file
     !-----------------------
     istat=nf90_close(ncid)
     if(istat.ne.NF90_NOERR) then
       write(iulog,*) nf90_strerror(istat)
       call endrun ('UPDATE_ANALYSES_EUL')
     endif
   endif ! (masterproc) then
   call scatter_field_to_chunk(1,1,1,Nudge_nlon,PSanal,           &
                               Nobs_PS(1,begchunk,Nudge_ObsInd(2)))

   ! End Routine
   !------------
   return
  end subroutine ! nudging_update_analyses_fv_init
  !================================================================




  ! ================================================================
  subroutine nudging_update_analyses_fv_spec(nudge_file)
   ! 
   ! NUDGING_UPDATE_ANALYSES_FV: 
   !                 Open the given specified tendency file, read in 
   !                 U,V,T,Q, and PS values and then distribute
   !                 the values to all of the chunks.
   ! Isla 14 08 15
   !===============================================================
   use ppgrid ,only: pver,begchunk
   use netcdf

   ! Arguments
   !-------------
   character(len=*),intent(in):: nudge_file

   ! Local values
   !-------------
   integer lev
   integer nlon,nlat,plev,istat
   integer ncid,varid
   integer ilat,ilon,ilev
   real(r8) Xanal(Nudge_nlon,Nudge_nlat,Nudge_nlev)
   real(r8) PSanal(Nudge_nlon,Nudge_nlat)
   real(r8) Lat_anal(Nudge_nlat)
   real(r8) Lon_anal(Nudge_nlon)
   real(r8) Xtrans(Nudge_nlon,Nudge_nlev,Nudge_nlat)
   integer  nn,Nindex

   !-------------------------------------------------------------------------
   ! The specified tendency file is only needed for certain forcing options.
   ! Check paramters and return if the file is not used.
   !-------------------------------------------------------------------------

   ! Rotate Nudge_ObsInd() indices, then check the existence of the analyses 
   ! file; broadcast the updated indices and file status to all the other MPI
   ! nodes. 
   !------------------------------------------------------------------------
   if(masterproc) then
     Nindex=Nudge_ObsInd(Nudge_NumObs)
     do nn=Nudge_NumObs,2,-1
       Nudge_ObsInd(nn)=Nudge_ObsInd(nn-1)
     end do
     Nudge_ObsInd(1)=Nindex
     inquire(FILE=trim(nudge_file),EXIST=Nudge_File_Present(Nudge_ObsInd(1)))
     write(iulog,*)'NUDGING: Nudge_ObsInd=',Nudge_ObsInd
     write(iulog,*)'NUDGING: Specified Nudg_File_Present=',Nudge_File_Present
   endif
#ifdef SPMD
   call mpibcast(Nudge_File_Present, Nudge_NumObs, mpilog, 0, mpicom)
   call mpibcast(Nudge_ObsInd      , Nudge_NumObs, mpiint, 0, mpicom)
#endif
   if (.not.Nudge_File_Present(Nudge_ObsInd(1))) then 
     call endrun('UPDATE_ANALYSIS_FV')
     write(iulog,*)'Specified tendency file not present'
   endif


   ! Open the Specified Tendency file
   !--------------------------------------------------------
   if(masterproc) then
!     inquire(FILE=trim(nudge_file),EXIST=Nudge_File_Present(Nudge_ObsInd(1)))
!     write(iulog,*)'NUDGING: Nudge_ObsInd=',Nudge_ObsInd
!     write(iulog,*)'NUDGING: Spec_File_Present=',Nudge_File_Present

     ! Open the given file
     !-----------------------
     istat=nf90_open(trim(nudge_file),NF90_NOWRITE,ncid)
     if(istat.ne.NF90_NOERR) then
       write(iulog,*)'NF90_OPEN: failed for file ',trim(nudge_file)
       write(iulog,*) nf90_strerror(istat)
       call endrun ('UPDATE_ANALYSES_FV')
     endif
 
 ! Read in Dimensions
     !--------------------
     istat=nf90_inq_dimid(ncid,'lon',varid)
     if(istat.ne.NF90_NOERR) then
       write(iulog,*) nf90_strerror(istat)
       call endrun ('UPDATE_ANALYSES_FV')
     endif
     istat=nf90_inquire_dimension(ncid,varid,len=nlon)
     if(istat.ne.NF90_NOERR) then
       write(iulog,*) nf90_strerror(istat)
       call endrun ('UPDATE_ANALYSES_FV')
     endif

     istat=nf90_inq_dimid(ncid,'lat',varid)
     if(istat.ne.NF90_NOERR) then
       write(iulog,*) nf90_strerror(istat)
       call endrun ('UPDATE_ANALYSES_FV')
     endif
     istat=nf90_inquire_dimension(ncid,varid,len=nlat)
     if(istat.ne.NF90_NOERR) then
       write(iulog,*) nf90_strerror(istat)
       call endrun ('UPDATE_ANALYSES_FV')
     endif

     istat=nf90_inq_dimid(ncid,'lev',varid)
     if(istat.ne.NF90_NOERR) then
       write(iulog,*) nf90_strerror(istat)
       call endrun ('UPDATE_ANALYSES_FV')
     endif
     istat=nf90_inquire_dimension(ncid,varid,len=plev)
     if(istat.ne.NF90_NOERR) then
       write(iulog,*) nf90_strerror(istat)
       call endrun ('UPDATE_ANALYSES_FV')
     endif

     if((Nudge_nlon.ne.nlon).or.(Nudge_nlat.ne.nlat).or.(plev.ne.pver)) then
      write(iulog,*) 'ERROR: nudging_update_analyses_fv: nlon=',nlon,'Nudge_nlon=',Nudge_nlon
      write(iulog,*) 'ERROR: nudging_update_analyses_fv: nlat=',nlat,'Nudge_nlat=',Nudge_nlat
      write(iulog,*) 'ERROR: nudging_update_analyses_fv: plev=',plev,'pver=',pver
      call endrun('nudging_update_analyses_fv: analyses dimension mismatch')
     endif
    endif

    if (masterproc) then
      write(iulog,*) 'BEFORE SCATTER'
    endif

    call scatter_field_to_chunk(1,Nudge_nlev,1,Nudge_nlon,Xtrans,  & 
      Sndg_U(1,1,begchunk,Nudge_ObsInd(1))) 


    if (masterproc) then 
      write(iulog,*) 'AFTER SCATTER'
    endif

     if (masterproc) then
       istat=nf90_inq_varid(ncid,'Nudge_V',varid)
       if(istat.ne.NF90_NOERR) then
         write(iulog,*) 'Nudge_V NF90_ERROR',nf90_strerror(istat)
         call endrun ('UPDATE_ANALYSES_FV')
       endif
       istat=nf90_get_var(ncid,varid,Xanal)
       if(istat.ne.NF90_NOERR) then
         write(iulog,*) 'XANAL Nudge_V',nf90_strerror(istat)
         call endrun ('UPDATE_ANALYSES_FV')
       endif
      write(iulog,*) 'Nudge_V XANAL=',Xanal(5,5,5)
     do ilat=1,nlat
     do ilev=1,plev
     do ilon=1,nlon
       Xtrans(ilon,ilev,ilat)=Xanal(ilon,ilat,ilev)
     end do
     end do
     end do

       write(iulog,*) 'Nudge_V values=',Xtrans(5,5,5)

     endif !(masterproc) then
     call scatter_field_to_chunk(1,Nudge_nlev,1,Nudge_nlon,Xtrans,   & 
        Sndg_V(1,1,begchunk,Nudge_ObsInd(1)))

      


     if(masterproc) then
       istat=nf90_inq_varid(ncid,'Nudge_T',varid)
       if(istat.ne.NF90_NOERR) then
         write(iulog,*) nf90_strerror(istat)
         call endrun ('UPDATE_ANALYSES_FV')
       endif
       istat=nf90_get_var(ncid,varid,Xanal)
       if(istat.ne.NF90_NOERR) then
         write(iulog,*) nf90_strerror(istat)
         call endrun ('UPDATE_ANALYSES_FV')
       endif
     do ilat=1,nlat
     do ilev=1,plev
     do ilon=1,nlon
       Xtrans(ilon,ilev,ilat)=Xanal(ilon,ilat,ilev)
     end do
     end do
     end do

     write(iulog,*) 'Nudge_T values=',Xtrans(5,5,5)
     endif !(masterproc) then
     call scatter_field_to_chunk(1,Nudge_nlev,1,Nudge_nlon,Xtrans,   & 
        Sndg_S(1,1,begchunk,Nudge_ObsInd(1)))

     if(masterproc) then
       istat=nf90_inq_varid(ncid,'Nudge_Q',varid)
       if(istat.ne.NF90_NOERR) then
         write(iulog,*) nf90_strerror(istat)
         call endrun ('UPDATE_ANALYSES_FV')
       endif
       istat=nf90_get_var(ncid,varid,Xanal)
       if(istat.ne.NF90_NOERR) then
         write(iulog,*) nf90_strerror(istat)
         call endrun ('UPDATE_ANALYSES_FV')
       endif
     do ilat=1,nlat
     do ilev=1,plev
     do ilon=1,nlon
       Xtrans(ilon,ilev,ilat)=Xanal(ilon,ilat,ilev)
     end do
     end do
     end do
     write(iulog,*) 'Nudge_Q values=',Xtrans(5,5,5)

     ! Close the analyses file
     !-----------------------
     istat=nf90_close(ncid)
     if(istat.ne.NF90_NOERR) then
       write(iulog,*) nf90_strerror(istat)
       call endrun ('UPDATE_ANALYSES_FV')
     endif

     endif ! (masterproc) then
     call scatter_field_to_chunk(1,Nudge_nlev,1,Nudge_nlon,Xtrans,   &
        Sndg_Q(1,1,begchunk,Nudge_ObsInd(1)))
!   endif ! (Nudge_NDG_Refopt.ne.0) then

   ! Could be modified further to read in DYN tendencies as in the SE routine



   ! End Routine
   !------------
   return
  end subroutine ! nudging_update_analyses_fv
  !================================================================

  !================================================================
  subroutine nudging_set_profile(rlat,rlon,ltaper,ltaperlat,Wprof,nlev)
  !
  ! Adapted from Patricks code
  !
  !=================================================================

  use hycoef,          only: hyam, hybm
  use cam_logfile ,only:iulog
  real(r8) pvalues(nlev)
  integer  nlev,ilev
  real(r8) rlat,rlon
  real(r8) Wprof(nlev)
  logical ltaper
  logical ltaperlat

  Wprof(:)=1.0 ! uniform nudging

  if (ltaper) then 
     if (Nudge_p1bot.lt.Nudge_p2bot) then
       call endrun('Nudge_p1bot must be greater than or equal to Nudge_p2bot')
     endif

     if (Nudge_p1top.lt.Nudge_p2top) then
       write(iulog,*) '!!!IRS p1top=',Nudge_p1top,' p2top=',Nudge_p2top
       call endrun('Nudge_p1top must be greater than or equal to Nudge_p2top')
     endif

     pvalues(:)=(1.0e5*hyam(:)+1.0e5*hybm(:))/100. ! Pressure in hPa

     do ilev=1,nlev
       if (Nudge_p1bot.eq.Nudge_p2bot) then 
         if (pvalues(ilev).gt.Nudge_p1bot) then 
          Wprof(ilev)=0.
         endif
       else   
         if (pvalues(ilev).ge.Nudge_p1bot) then
           Wprof(ilev)=0.
         else
           Wprof(ilev)=1. - ( (pvalues(ilev) - Nudge_p2bot) / (Nudge_p1bot - Nudge_p2bot) )
!            Wprof(ilev) = ( (Nudge_p1bot - pvalues(ilev))/(Nudge_p1bot - Nudge_p2bot))**3.
         endif
       endif

       if (Nudge_p1top.eq.Nudge_p2top) then 
         if (pvalues(ilev).lt.Nudge_p2top) then 
          Wprof(ilev)=0.
         endif
       else
         if (pvalues(ilev).le.Nudge_p2top) then 
          Wprof(ilev)=0.
         else if (pvalues(ilev).le.Nudge_p1top) then 
          Wprof(ilev)=1. - (Nudge_p1top - pvalues(ilev)) / (Nudge_p1top-Nudge_p2top)
         endif
       endif

       if ( (pvalues(ilev).le.Nudge_p2bot).and.(pvalues(ilev).ge.Nudge_p1top)) then 
         Wprof(ilev)=1.
       endif

       if (masterproc) then 
         write(iulog,*),'pre=',pvalues(ilev),' Wprof=',Wprof(ilev)
       end if
     enddo
   endif

   if (ltaperlat) then 
     if ((rlat.lt.(Nudge_lat1-Nudge_latdelta)).or.(rlat.gt.(Nudge_lat2+Nudge_latdelta))) then
        Wprof(:)=0.
     else
        Wprof(:)=Wprof(:)*1.
     end if
 
     if (Nudge_latdelta.gt.0) then 
       if ((rlat.ge.(Nudge_lat1-Nudge_latdelta)).and.(rlat.lt.Nudge_lat1)) then 
         Wprof(:)=Wprof(:)*(1./Nudge_latdelta)*(rlat-(Nudge_lat1-Nudge_latdelta))
       end if
       if ((rlat.gt.Nudge_lat2).and.(rlat.le.(Nudge_lat2+Nudge_latdelta))) then
         Wprof(:)=Wprof(:)*(1./Nudge_latdelta)*( (Nudge_lat2+Nudge_latdelta) - rlat)
       end if 
     end if

!     write(iulog,*),'???rlat, Wprof=',rlat,' ',Wprof(5)
     write(iulog,*),'?????? WPROF=',Wprof

   end if



      ! End Routine
   !------------
   return
  end subroutine ! nudging_set_profile
  !================================================================

  ! ****************IRS****************
  ! ===============================================================
  subroutine zmcalc(arrin,arrout)
  ! Calculate the zonal mean of 3D Target or Model arrays
  ! Input: arrin(pcols,pver,begchunk:endchunk) = chunked up data array
  ! Gather's chunked fields to global array
  ! Calculate the zonal mean.  
  ! Place the zonal mean in the global array 
  ! Scatter this to the chunks to give arrout
  ! Output:arrout(pcols,pver,begchunk:endchunk)
  ! 
  ! Isla Simpson 02 19 16
  ! 
  !===============================================================
   use shr_kind_mod, only: r8 => shr_kind_r8
   use phys_grid, only: gather_chunk_to_field,scatter_field_to_chunk
   use ppgrid, only: pver,pcols,begchunk,endchunk
   use dyn_grid, only: get_horiz_grid_dim_d

   real(r8), intent(in) :: arrin(pcols,pver,begchunk:endchunk)
   real(r8), intent(out) :: arrout(pcols,pver,begchunk:endchunk)
   real(r8), allocatable :: arrglob(:,:,:),arrglobzm(:,:)

   integer :: hdim1, hdim2 ! Dimensions of horizontal grid

   integer :: ilon,ilat,ip,ncol

  ! Get longitude dimension of dynamics grid (hdim1)
  call get_horiz_grid_dim_d(hdim1,hdim2)
  ncol=hdim1*hdim2

!  if (masterproc) then
!  write(iulog,*) "!!!!!!ISLA, hdim1=",hdim1
!  write(iulog,*) "!!!!!!ISLA, hdim2=",hdim2
!  write(iulog,*) "arrin=",arrin(5,5,begchunk)
!  endif

  allocate(arrglob(hdim1,pver,hdim2))
  arrglob(:,:,:)=0.0_r8
  call gather_chunk_to_field(1,pver,1,hdim1,arrin,arrglob)

  ! Calculate zonal mean
  allocate(arrglobzm(pver,hdim2))
  arrglobzm(:,:)=0.0_r8
  do ilon=1,hdim1
    arrglobzm(:,:)=arrglobzm(:,:) + arrglob(ilon,:,:)/real(hdim1)
  end do
  do ilon=1,hdim1
   arrglob(ilon,:,:)=arrglobzm(:,:)
  end do

  call scatter_field_to_chunk(1,pver,1,hdim1,arrglob,arrout)

!  if (masterproc) then
!    write(iulog,*) "arrout=",arrout(5,5,begchunk)
!  endif

  return
  end subroutine zmcalc
  ! ===============================================================





end module nudging
