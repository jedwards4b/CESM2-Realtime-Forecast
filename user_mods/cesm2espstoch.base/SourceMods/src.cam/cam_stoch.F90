module cam_stoch
!----------------------------------------------------------------------- 
! 
! Purpose: 
! Stochastic parameterization suite 
!
! Author: Judith Berner 2020 
! Previous version:  Judith Berner, Dani Coleman  
!-----------------------------------------------------------------------

use shr_kind_mod,    only: r8 => shr_kind_r8
use ppgrid,          only: pcols, pver
use physics_types,   only: physics_state, physics_ptend, physics_tend
use cam_logfile,     only: iulog
!use buffer,          only: stoch_seed

implicit none
private
save

! Routines
public :: &
      cam_stoch_readnl,cam_stoch_register, & 
      generate_randomfield,generate_spatio_temporal_randomfield,ptend_update_sppt, & 
      cam_stoch_skebs_init, cam_stoch_sppt_init, cam_stoch_conv_init

! Parameters 
public :: &
      cam_stoch_skebs, cam_stoch_tot_backscat_psi, cam_stoch_tot_backscat_t, cam_stoch_skebs_seed, & 
      cam_stoch_sppt,cam_stoch_sppt_sigma,cam_stoch_sppt_tau,cam_stoch_sppt_lengthscale,cam_stoch_sppt_cutoff,cam_stoch_sppt_seed, & 
      cam_stoch_conv,cam_stoch_conv_sigma,cam_stoch_conv_tau,cam_stoch_conv_cutoff,cam_stoch_conv_seed, & 
      cam_stoch_conv_selectnoise, cam_stoch_conv_lengthscale, & 
      cam_stoch_conv_lognormal_sigma, cam_stoch_conv_lognormal_mu

! Indeces
public :: &
      stoch_conv_idx,stoch_conv_seedarr_idx,nu_conv,eta_conv,thresh_stoch_conv, & 
      stoch_sppt_idx, stoch_sppt_seedarr_idx, & 
      how_many


!drbc Namelist variables
      integer      :: cam_stoch_skebs
      real(r8)     :: cam_stoch_tot_backscat_psi
      real(r8)     :: cam_stoch_tot_backscat_t
      integer      :: cam_stoch_skebs_seed

      integer      :: cam_stoch_sppt 
      real(r8)     :: cam_stoch_sppt_sigma
      real(r8)     :: cam_stoch_sppt_tau 
      real(r8)     :: cam_stoch_sppt_cutoff 
      real(r8)     :: cam_stoch_sppt_lengthscale
      integer      :: cam_stoch_sppt_seed

      integer      ::  cam_stoch_conv 
      integer      :: cam_stoch_conv_seed
      integer      :: cam_stoch_conv_selectnoise
      real(r8)     :: cam_stoch_conv_sigma
      real(r8)     :: cam_stoch_conv_tau 
      real(r8)     :: cam_stoch_conv_cutoff 
      real(r8)     :: cam_stoch_conv_lengthscale
      real(r8)     :: cam_stoch_conv_lognormal_sigma
      real(r8)     :: cam_stoch_conv_lognormal_mu

      INTEGER  :: stoch_skebs       ! set from namelist var cam_stoch_skebs
      REAL(r8)     :: tot_backscat_psi  ! set from namelist var cam_stoch_tot_backscat_psi
      REAL(r8)     :: tot_backscat_t    ! set from namelist var cam_stoch_tot_backscat_t
      integer  :: stoch_skebs_seed  ! set from namelistvar cam_stoch_conv_seed, sent to setup routines

!     Module variables: Spherical harmonics space 

      REAL, ALLOCATABLE :: wshses(:)
      !integer, parameter::   nlon=288, nlat=129, nmax=288 , mmax=288 
      real, allocatable  :: spamp(:) ! should be passed but within the module only
      real, allocatable :: spforcc(:,:),spforcs(:,:)

!     Module variables: gridpoint  space 

      INTEGER :: lshses
      INTEGER :: how_many 
      REAL    :: alpha_sppt  
      integer :: nlon, nlat ,nmax,mmax

      real :: eta_conv, nu_conv, thresh_stoch_conv

!     Random number streams 
      real, allocatable :: rstoch_glob(:,:)

!     Others
      REAL, PARAMETER:: RPI= 3.141592653589793 !4.0*atan(1.0) 
      REAL, PARAMETER:: RA = 6.371229E06  ! Earth's radius in metres
      real, parameter :: dtime=0.5*3600   ! model timestep (should come in through use statement) 
      logical, parameter:: debug = .false.  
      integer, parameter::  stoch_sppt_end=1
      integer :: stoch_skebs_idx,stoch_skebs_seedarr_idx
      integer :: stoch_conv_idx, stoch_conv_seedarr_idx 
      integer :: stoch_sppt_idx, stoch_sppt_seedarr_idx



!<!-- Stochasticially perturbed parameterization scheme SPPT -->
!<cam_stoch_sppt                >0 </cam_stoch_sppt>
!<cam_stoch_sppt_tau            >21600.0D0</cam_stoch_sppt_tau>
!<cam_stoch_sppt_sigma          >0.3D0</cam_stoch_sppt_sigma>
!<cam_stoch_sppt_cutoff         >3.0D0</cam_stoch_sppt_cutoff>
!<cam_stoch_sppt_seed           >17</cam_stoch_sppt_seed>
!======================================================================= 
contains

!======================================================================= 
subroutine cam_stoch_readnl(nlfile)

   use namelist_utils,  only: find_group_name
   use units,           only: getunit, freeunit
   use mpishorthand
   use spmd_utils,   only: masterproc
   use cam_abortutils,  only: endrun


   character(len=*), intent(in) :: nlfile  ! filepath for file containing namelist input

   ! Local variables
   integer :: unitn, ierr
   character(len=*), parameter :: subname = 'cam_stoch_readnl'

   namelist /cam_stoch_nl/cam_stoch_skebs, cam_stoch_tot_backscat_psi, cam_stoch_tot_backscat_t, cam_stoch_skebs_seed, & 
                          cam_stoch_sppt,  cam_stoch_sppt_sigma, cam_stoch_sppt_tau, cam_stoch_sppt_cutoff, cam_stoch_sppt_seed, & 
                          cam_stoch_sppt_lengthscale,  &
                          cam_stoch_conv,  cam_stoch_conv_sigma, cam_stoch_conv_tau, cam_stoch_conv_cutoff, cam_stoch_conv_seed, & 
                          cam_stoch_conv_selectnoise, cam_stoch_conv_lengthscale,  & 
                          cam_stoch_conv_lognormal_sigma, cam_stoch_conv_lognormal_mu

! It seems that defaults are now set here and no longer in bld/namelist_files/namelist_defaults_cam.xml
! ???
! https://bb.cgd.ucar.edu/how-add-new-namelist-variables
    cam_stoch_conv=1
    cam_stoch_conv_sigma=1.0
    cam_stoch_conv_tau = 21600.0
    cam_stoch_conv_seed = 17
    cam_stoch_conv_selectnoise=3
    cam_stoch_conv_cutoff=3.
    cam_stoch_conv_lengthscale = 500000
    cam_stoch_conv_lognormal_sigma = 0.40  
    cam_stoch_conv_lognormal_mu = 8.34


    !cam_stoch_sppt_lengthscale = 500000 !m 
    !cam_stoch_sppt_tau =  3600*6 ! s
    !cam_stoch_sppt_sigma = 2.
  
    cam_stoch_skebs =0

   if (debug) write(*,*)' read cam_stoch_readnl '
   if (masterproc) then
      unitn = getunit()
      open( unitn, file=trim(nlfile), status='old' )
      call find_group_name(unitn, 'cam_stoch_nl', status=ierr)
      write(*,*)'DRBDBG found and read cam_stoch_nl with error code ',ierr
      if (ierr == 0) then
         read(unitn, cam_stoch_nl, iostat=ierr)
         if (ierr /= 0) then
            call endrun(subname // ':: ERROR reading namelist')
         end if
      end if
      close(unitn)
      call freeunit(unitn)


      write(*,*)'stoch namelist settings cam_stoch_skebs',cam_stoch_skebs
      write(*,*)'stoch namelist settings cam_stoch_tot_backscat_psi',cam_stoch_tot_backscat_psi
      write(*,*)'stoch namelist settings cam_stoch_tot_backscat_t',cam_stoch_tot_backscat_t
      write(*,*)'stoch namelist settings cam_stoch_skebs_seed',cam_stoch_skebs_seed

      write(*,*)'stoch namelist settings cam_stoch_sppt',cam_stoch_sppt
      write(*,*)'stoch namelist settings cam_stoch_sppt_sigma',cam_stoch_sppt_sigma 
      write(*,*)'stoch namelist settings cam_stoch_sppt_tau',cam_stoch_sppt_tau
      write(*,*)'stoch namelist settings cam_stoch_sppt_cutoff',cam_stoch_sppt_cutoff 
      write(*,*)'stoch namelist settings cam_stoch_sppt_seed',cam_stoch_sppt_seed
      write(*,*)'stoch namelist settings cam_stoch_sppt_lengthscale', cam_stoch_sppt_lengthscale

      write(*,*)'stoch namelist settings cam_stoch_conv',cam_stoch_conv
      write(*,*)'stoch namelist settings cam_stoch_conv_sigma',cam_stoch_conv_sigma 
      write(*,*)'stoch namelist settings cam_stoch_conv_lognormal_sigma',cam_stoch_conv_lognormal_sigma 
      write(*,*)'stoch namelist settings cam_stoch_conv_lognormal_mu',cam_stoch_conv_lognormal_mu 
      write(*,*)'stoch namelist settings cam_stoch_conv_tau',cam_stoch_conv_tau
      write(*,*)'stoch namelist settings cam_stoch_conv_cutoff',cam_stoch_conv_cutoff 
      write(*,*)'stoch namelist settings cam_stoch_conv_seed',cam_stoch_conv_seed
      write(*,*)'stoch namelist settings cam_stoch_conv_selectnoise',cam_stoch_conv_selectnoise
      write(*,*)'stoch namelist settings cam_stoch_conv_lengthscale', cam_stoch_conv_lengthscale



      ! set local variables
      stoch_skebs      = cam_stoch_skebs
      tot_backscat_psi = cam_stoch_tot_backscat_psi
      tot_backscat_t   = cam_stoch_tot_backscat_t
      stoch_skebs_seed = cam_stoch_skebs_seed

      write(*,*)'stoch namelist settings stoch_skebs', stoch_skebs
      write(*,*)'stoch namelist settings tot_backscat_psi', tot_backscat_psi
      write(*,*)'stoch namelist settings tot_backscat_t', tot_backscat_t
      write(*,*)'stoch namelist settings stoch_skebs_seed',stoch_skebs_seed

   end if ! masterproc

#ifdef SPMD
   ! Broadcast namelist variables
   call mpibcast(stoch_skebs, 1, mpilog, 0, mpicom)
   call mpibcast(tot_backscat_psi, 1, mpilog, 0, mpicom)
   call mpibcast(tot_backscat_t, 1, mpilog, 0, mpicom)
   call mpibcast(stoch_skebs_seed, 1, mpilog, 0, mpicom)

   call mpibcast(cam_stoch_skebs, 1, mpilog, 0, mpicom)
   call mpibcast(cam_stoch_tot_backscat_psi, 1, mpilog, 0, mpicom)
   call mpibcast(cam_stoch_tot_backscat_t, 1, mpilog, 0, mpicom)
   call mpibcast(cam_stoch_skebs_seed, 1, mpilog, 0, mpicom)

! Orig code
   !call mpibcast(cam_stoch_sppt, 1, mpilog, 0, mpicom)
   !call mpibcast(cam_stoch_sppt_sigma, 1, mpilog, 0, mpicom)
   !call mpibcast(cam_stoch_sppt_tau, 1, mpilog, 0, mpicom)
   !call mpibcast(cam_stoch_sppt_cutoff, 1, mpilog, 0, mpicom)
   !call mpibcast(cam_stoch_sppt_seed, 1, mpilog, 0, mpicom)
   !call mpibcast(cam_stoch_sppt_lengthscale, 1, mpir8, 0, mpicom)

! For a future change/test ABJ
   call mpibcast(cam_stoch_sppt, 1, mpiint, 0, mpicom)
   call mpibcast(cam_stoch_sppt_sigma, 1, mpir8, 0, mpicom)
   call mpibcast(cam_stoch_sppt_tau, 1, mpir8, 0, mpicom)
   call mpibcast(cam_stoch_sppt_cutoff, 1, mpir8, 0, mpicom)
   call mpibcast(cam_stoch_sppt_seed, 1, mpiint, 0, mpicom)
   call mpibcast(cam_stoch_sppt_lengthscale, 1, mpir8, 0, mpicom)

!   call mpibcast(cam_stoch_conv, 1, mpilog, 0, mpicom)
!   call mpibcast(cam_stoch_conv_sigma, 1, mpilog, 0, mpicom)
!   call mpibcast(cam_stoch_conv_tau, 1, mpilog, 0, mpicom)
!   call mpibcast(cam_stoch_conv_cutoff, 1, mpilog, 0, mpicom)
!   call mpibcast(cam_stoch_conv_seed, 1, mpilog, 0, mpicom)
!   call mpibcast(cam_stoch_conv_selectnoise, 1, mpilog, 0, mpicom)

   call mpibcast(cam_stoch_conv, 1, mpiint, 0, mpicom)
   call mpibcast(cam_stoch_conv_sigma, 1, mpir8, 0, mpicom)
   call mpibcast(cam_stoch_conv_lognormal_sigma, 1, mpir8, 0, mpicom)
   call mpibcast(cam_stoch_conv_lognormal_mu, 1, mpir8, 0, mpicom)
   call mpibcast(cam_stoch_conv_tau, 1, mpir8, 0, mpicom)
   call mpibcast(cam_stoch_conv_cutoff, 1, mpir8, 0, mpicom)
   call mpibcast(cam_stoch_conv_seed, 1, mpiint, 0, mpicom)
   call mpibcast(cam_stoch_conv_selectnoise, 1, mpiint, 0, mpicom)
   call mpibcast(cam_stoch_conv_lengthscale, 1, mpir8, 0, mpicom)
#endif
   

end subroutine cam_stoch_readnl
!=======================================================================
subroutine cam_stoch_register

use physics_buffer, only : pbuf_add_field, dtype_r8, dtype_i4

! Purpose : Register fields with the physics buffer 


   if ( cam_stoch_skebs .eq. 1 ) then 
!      old: call pbuf_add_field( 'stoch', 'global', dtype_r8, (/pcols,pver,pbuf_times/),   stoch_skebs_idx )
       if ( debug ) write(6,*)'cam_stoch_register adding stoch field ',stoch_skebs_idx,'for cam_stoch_skebs ',cam_stoch_skebs
   else
       if ( debug ) write(6,*)'cam_stoch_register NOT adding stoch field for cam_stoch_skebs ',cam_stoch_skebs
   endif

!   if ( cam_stoch_conv .eq. 1 ) then  ! always register to avoid ERROR: GET_PBUF1D_FIELD_BY_INDEX: index (0) out of range
        call pbuf_add_field( 'RSTOCH', 'physpkg', dtype_r8, (/pcols/), stoch_conv_idx)
        call pbuf_add_field( 'iseedarr_conv', 'physpkg', dtype_i4, (/pcols/), stoch_conv_seedarr_idx) 
!   endif

!   if ( cam_stoch_sppt .eq. 1 ) then  ! always register to avoid ERROR: GET_PBUF1D_FIELD_BY_INDEX: index (0) out of range
        call pbuf_add_field( 'RSTOCH_SPPT', 'physpkg', dtype_r8, (/pcols/), stoch_sppt_idx)
        call pbuf_add_field( 'iseedarr_sppt', 'physpkg', dtype_i4, (/pcols/), stoch_sppt_seedarr_idx) 
!   endif
    !print*,'rstoch_sppt registered'

end subroutine cam_stoch_register
!=======================================================================
subroutine cam_stoch_skebs_init(pbuf2d)
   use physics_buffer, only: pbuf_get_field, physics_buffer_desc, pbuf_old_tim_idx, pbuf_set_field
   use physics_buffer, only : pbuf_add_field, dtype_r8, dtype_i4, pbuf_get_chunk
   use cam_history,    only: addfld, add_default, horiz_only
   use ppgrid,         only: begchunk, endchunk, pcols, pver
   use dyn_grid,       only: get_dyn_grid_parm
   use phys_grid,      only: get_ncols_p
   use mpishorthand
   use spmd_utils,     only:  masterproc
   type(physics_buffer_desc), pointer       :: pbuf2d(:,:)
   type(physics_buffer_desc), pointer :: phys_buffer_chunk(:)
   integer, pointer :: iseedarr_skebs(:)  ! (pcols,lchunk)
 ! local 
   integer :: nlat, nlon

! Not yet working.

   nlon = get_dyn_grid_parm('plon')
   nlat = get_dyn_grid_parm('plat')

! The seeds sent to the random number generator for ensemble runs needs to be a function
! of the ensemble member

   if ( debug  ) write(*,*)'DRBDBG calling  cam_stoch_skebs_init'

end subroutine cam_stoch_skebs_init
!=======================================================================
subroutine cam_stoch_sppt_init(pbuf2d)
   use physics_buffer, only: pbuf_get_field, physics_buffer_desc, pbuf_old_tim_idx, pbuf_set_field
   use physics_buffer, only : pbuf_add_field, dtype_r8, dtype_i4, pbuf_get_chunk
   use cam_history,    only: addfld, add_default, horiz_only
   use ppgrid,         only: begchunk, endchunk, pcols, pver
   use dyn_grid,       only: get_dyn_grid_parm
   use phys_grid,      only: get_ncols_p
   use mpishorthand
   use spmd_utils,     only:  masterproc
   type(physics_buffer_desc), pointer       :: pbuf2d(:,:)
   type(physics_buffer_desc), pointer :: phys_buffer_chunk(:)
   integer, pointer :: iseedarr_sppt(:)  ! (pcols,lchunk)
 ! local 
   integer :: ierror,l1,l2,i,j,lchnk,ncol,lwork,ldwork
   integer :: how_many ! length of seed for chosen compiler
   integer, allocatable :: iseed(:)
   real, allocatable :: work(:)
   real(r8), allocatable :: dwork(:)
   real, allocatable :: zchi(:)
   real :: zgamman,zconst,kappa

   if ( debug  ) write(*,*)'JB cam_stoch_sppt_init'
! Purpose : Register fields with the outfld buffer 

    call addfld ('RSTOCH_SPPT',   horiz_only  ,  'A', 'none', 'random field') 
    call addfld ('ISEEDARR_SPPT',   horiz_only  ,  'A', 'none', 'iseedarr_sppt') 

   ! Get size of global grid (only valid for rectangular lat/lon grids)
     nlon = get_dyn_grid_parm('plon')
     nlat = get_dyn_grid_parm('plat')
     !write(*,*)' Lala Spatio-temporal pattern in cam_stoch_sppt uses nlon,nlat', nlon,nlat
     allocate(rstoch_glob(nlon,nlat))
     rstoch_glob=0.0

     if (mod(nlon,2) == 0 ) then 
     l1 = min0(nlat,(nlon+2)/2)
     else 
     l1 = min0(nlat,(nlon+1)/2) 
     endif 
     if (mod(nlat,2) == 0 ) then 
     l2 = nlat/2       
     else 
     l2 = (nlat+1)/2  
     endif 
     lshses = (l1*l2*(nlat+nlat-l1+1))/2+nlon+15
     lwork =  5*nlat*l2+3*((l1-2)*(nlat+nlat-l1-1))/2
     ldwork = nlat+1

! --- Initialize amplitude of spatio-temporal perturbations
     ALLOCATE(wshses(lshses))
     ALLOCATE(work(lwork))
     ALLOCATE(dwork(ldwork))
     ierror=99
     call shsesi(nlat,nlon,wshses,lshses,work,lwork,dwork,ldwork,ierror) !for lat-lon grid
     !  if(ierror .eq. 0) write (*,'(''no error in the specification '')')
     if(ierror .ne. 0) then
       if(ierror .eq. 1) write (*,'(''error in the specification of nlat'')')
       if(ierror .eq. 2) write (*,'(''error in the specification of nlon'')')
       if(ierror .eq. 3) write (*,'(''error in the specification of lshses'')')
       if(ierror .eq. 4) write (*,'(''error in the specification of lwork  '')')
       if(ierror .eq. 5) write (*,'(''error in the specification of ldwork  '')')
     endif
     DEALLOCATE(work)

     nmax=nlat
     mmax=nlat
     allocate(spamp(nmax),zchi(nmax))
     allocate(spforcc(0:mmax,0:nmax),spforcs(0:mmax,0:nmax)) 
     kappa= (cam_stoch_sppt_lengthscale/ra)**2 ! L^2= kappa*T,  where L is a length scale in m
     alpha_sppt = exp(-dtime/cam_stoch_sppt_tau)
     do i=1,nmax
         zchi(i)=exp(-kappa*i*(i+1)/2.0)
         zgamman= zgamman + (2*i+1.0)*exp(-kappa * i*(i+1.0))
     enddo
     zconst=    sqrt(cam_stoch_sppt_sigma*(1.-(1.-alpha_sppt)**2)/(2.*zgamman))
     spamp=0.0
     do i=1,nmax
         spamp(i) = zconst*zchi(i)
     enddo

! allocate and fill seed array
      call random_seed(size=how_many)
      if ( allocated(iseed)) deallocate(iseed)
      allocate(iseed(how_many))
       do j=1,how_many
           iseed(j)=cam_stoch_sppt_seed
       enddo
       call random_seed(put=iseed(1:how_many)) ! if commented, no seed is set

! --- Spin up random pattern 
     spforcc=0.0
     spforcs=0.0
    do lchnk=begchunk,endchunk
       phys_buffer_chunk => pbuf_get_chunk(pbuf2d,lchnk)
       ncol = get_ncols_p(lchnk)
       do i=1,12
           call generate_spatio_temporal_randomfield
       enddo 
    enddo 

end subroutine cam_stoch_sppt_init
!=======================================================================
subroutine cam_stoch_conv_init(pbuf2d)
   use physics_buffer, only: pbuf_get_field, physics_buffer_desc, pbuf_old_tim_idx, pbuf_set_field
   use physics_buffer, only : pbuf_add_field, dtype_r8, dtype_i4, pbuf_get_chunk
   use cam_history,    only: addfld, add_default, horiz_only
   use ppgrid,         only: begchunk, endchunk, pcols, pver
   use dyn_grid,       only: get_dyn_grid_parm
   use phys_grid,      only: get_ncols_p
   use mpishorthand
   use spmd_utils,     only:  masterproc
   use dyn_grid,       only: get_dyn_grid_parm
   type(physics_buffer_desc), pointer       :: pbuf2d(:,:)
   type(physics_buffer_desc), pointer :: phys_buffer_chunk(:)
   integer, pointer :: iseedarr_conv(:)  ! (pcols,lchunk)
   integer :: i,j,lchnk,ncol,ierror
 ! local 
   real, dimension(nmax)  :: zchi
   real :: zgamman,zconst,kappa


! Purpose : Register fields with the outfld buffer 
    call addfld ('RSTOCH',   horiz_only  ,  'A', 'none', 'random field') 
    call addfld ('ISEEDARR_CONV',   horiz_only  ,  'A', 'none', 'iseedarr_conv') 
   
    write(*,*)'CAM_stoch initializing random number stream with stoch_conv_seed'
    if ( debug  ) write(*,*)'JB cam_stoch_conv_init'
! set seed array for each processor
    do lchnk=begchunk,endchunk
       phys_buffer_chunk => pbuf_get_chunk(pbuf2d,lchnk)
       ncol = get_ncols_p(lchnk)
       do i=1,ncol 
!         Uncommenting the following line will lead to a runtime error 
!         iseedarr_conv(i)=cam_stoch_conv_seed+i*3912864+lchnk*1298479
       enddo
    enddo 
   
   !call pbuf_set_field(pbuf2d, stoch_conv_seedarr_idx,    0.0_r8)
   !call pbuf_set_field(pbuf2d, stoch_conv_seedarr_idx,   iseedarr_conv)

! ---  Compute  damping  parameter
     nu_conv=  1./cam_stoch_conv_tau! adjusto with model timestep 
! --- Compute cutoff threshold
!   thresh=cam_stoch_conv_cutoff*cam_stoch_conv_sigma
! --- Compute noise amplitude so that process has a standard deviation of cam_stoch_conv_sigma
     eta_conv  = sqrt(2*nu_conv)*cam_stoch_conv_sigma
! --- Compute noise amplitude so that process has a standard deviation of one
!     eta_conv  = sqrt(2*nu_conv)
! --- Make it run for cam_stoch_conv_tau=0.0; 
    if (cam_stoch_conv_tau==0.0) then
        nu_conv=0.0; 
        eta_conv=cam_stoch_conv_sigma; 
    endif
! --- set cutoff for lower tail only 
     thresh_stoch_conv=0.0

! --- Sping up random pattern 
    do lchnk=begchunk,endchunk
       phys_buffer_chunk => pbuf_get_chunk(pbuf2d,lchnk)
       ncol = get_ncols_p(lchnk)
       do i=1,100
         call generate_randomfield(phys_buffer_chunk,ncol,lchnk)
       enddo 
    enddo 

end subroutine cam_stoch_conv_init
!=======================================================================
subroutine generate_spatio_temporal_randomfield
! Has to be called e.g. in phys_timestepinit, before the chunking of the fields
   !use physics_buffer,    only : pbuf_get_field, pbuf_set_field,physics_buffer_desc
   !type(physics_buffer_desc), pointer       :: pbuf(:)
   !INTEGER                     :: NLAT,NLON
   !REAL, DIMENSION (NLON,NLAT) :: rstoch_glob

        call spatio_temporal_update(mmax,nmax,spamp,spforcc,spforcs)
        call sh2gp(spforcc,spforcs,rstoch_glob,mmax,nmax,nlat,nlon)

end subroutine generate_spatio_temporal_randomfield

!====================================================================
!=======================================================================
subroutine ptend_update_sppt(pbuf,ncol,lchnk)
!====================================================================
! This subroutines takes the domain-sized stochastic pattern and puts in on chunks
   use physics_buffer,    only : pbuf_get_field, pbuf_set_field,physics_buffer_desc, pbuf_old_tim_idx
   use ppgrid,            only: begchunk, endchunk, pcols, pver
   use mpishorthand
   use cam_history,       only: outfld
   use phys_grid,         only: get_lat_all_p, get_lon_all_p
   use spmd_utils,   only: masterproc
   use time_manager,    only: get_nstep
   type(physics_buffer_desc), pointer       :: pbuf(:)
   integer, pointer :: iseedarr_sppt(:)  ! (pcols,lchunk)
   real(r8), pointer :: rstoch_sppt(:)  ! (pcols) 
   !local 
   real :: r, dxdt, sqrtdt,dt
   integer :: i, j, ncol, lchnk, nstep 
   integer  :: glat_idx(pcols), glon_idx(pcols)
   integer :: how_many ! length of seed for chosen compiler
   integer, allocatable :: iseed(:)

   call pbuf_get_field(pbuf, stoch_sppt_idx,           rstoch_sppt)
   call pbuf_get_field(pbuf, stoch_sppt_seedarr_idx,   iseedarr_sppt)

! --- Transform from gridpoint to spectral space
! --- rstoch_glob is global domain-sized field

      call get_lat_all_p(lchnk, ncol, glat_idx)
      call get_lon_all_p(lchnk, ncol, glon_idx)

      rstoch_sppt=0.0
      do i = 1, ncol
          rstoch_sppt(i) = rstoch_glob(glon_idx(i),glat_idx(i))  
      end do

! --- cutoff the tails
   ! keep 1+stochfield > 0 since it is multiplying the tendency
      rstoch_sppt(:ncol) = max(-1._r8,rstoch_sppt(:ncol))
      rstoch_sppt(:ncol) = min(1._r8,rstoch_sppt(:ncol))

     end subroutine ptend_update_sppt

!====================================================================
subroutine generate_randomfield(pbuf,ncol,lchnk)
!====================================================================
   use physics_buffer,    only : pbuf_get_field, physics_buffer_desc, pbuf_old_tim_idx
   use ppgrid,            only: begchunk, endchunk, pcols, pver
   use mpishorthand
   use cam_history,       only: outfld
   use phys_grid,         only: get_lat_all_p, get_lon_all_p
   use spmd_utils,   only: masterproc
   type(physics_buffer_desc), pointer       :: pbuf(:)
   integer, pointer :: iseedarr_conv(:)  ! (pcols,lchunk)
   real(r8), pointer :: rstoch(:)  ! (pcols) 
   !local 
   real(r8)                :: x(ncol)
   !real :: r, dxdt, eta_conv, nu_conv, thresh_stoch_conv, sqrtdt,dt
   real :: r, dxdt, sqrtdt,dt
   integer :: i, j, ncol, noise_classfication,lchnk
   integer :: how_many ! length of seed for chosen compiler
   integer, allocatable :: iseed(:)
!   integer, parameter :: noise_classfication=3 ! should be namelist parameter 
        ! 1 - uniform, white 
        ! 2 - Gaussian, white
        ! 3 - Gaussian, red (temporal correlation)
    ! --- dt for noise 
   noise_classfication=cam_stoch_conv_selectnoise
   dt=dtime
   sqrtdt= sqrt(dt)

   call pbuf_get_field(pbuf, stoch_conv_idx,           rstoch)
   call pbuf_get_field(pbuf, stoch_conv_seedarr_idx,   iseedarr_conv)

   if (debug) write(*,*)'CAM_stoch in subroutine generate_randomfield' 

! allocate seed array
   call random_seed(size=how_many)
   if ( allocated(iseed)) deallocate(iseed)
   allocate(iseed(how_many))

! -- Generates the perturbation pattern rstoch
! -- Uniform 
     IF (noise_classfication==1) then
       do i=1,ncol
           do j=1,how_many
             iseed(j)=iseedarr_conv(i)+i*3912864+lchnk*1298479
           enddo 
           call random_seed(put=iseed(1:how_many)) ! if commented, no seed is set
           CALL RANDOM_NUMBER(r)
           rstoch(i)=r
           iseedarr_conv(i)=iseed(1)
       ENDDO
     ELSE IF (noise_classfication==2) then
! --- Gaussian noise, white in time;  now also a special case of noise_classfication==3
       do i=1,ncol
           do j=1,how_many
              iseed(j)=iseedarr_conv(i)+i*3912864+lchnk*1298479
           enddo 
           call random_seed(put=iseed(1:how_many)) ! if commented, no seed is set
           do
             call gauss_noise(r)
            if (abs(r).lt.5) exit ! bound Gaussian a little bit
           enddo
           rstoch(i)=r
           iseedarr_conv(i)=iseed(1)
       enddo
     else if ((noise_classfication==3).or.(noise_classfication==4).or.(noise_classfication==5)) then 
! --- Gaussian noise with temporal correlation
        do  i=1,ncol
           do j=1,how_many
              iseed(j)=iseedarr_conv(i)+i*3912864+lchnk*1298479
           enddo 
           call random_seed(put=iseed(1:how_many)) ! if commented, no seed is set
	   x(i)=rstoch(i)
           do
            call gauss_noise(r)
            if (abs(r).lt.5) exit ! bound Gaussian a little bit
           enddo
           dxdt=-nu_conv*x(i)*dt+eta_conv*r*sqrtdt
           rstoch(i)=x(i)+dxdt
           iseedarr_conv(i)=iseed(1)
       enddo
     endif 
     !call outfld('RSTOCH',rstoch, pcols, lchnk) ! output in ZM_CONV_INT
     !call outfld('iseedarr_conv',iseedarr_sppt, pcols, lchnk)

     end subroutine generate_randomfield
!====================================================================
     subroutine spatio_temporal_update(mmax,nmax,spamp,spforcc,spforcs)
     integer:: i,j,mmax,nmax
     real :: r
     real, dimension(nmax)  :: spamp ! should be passed but within the module only
     real, dimension(0:mmax,0:nmax) :: spforcc,spforcs


      do j=1,nmax ! n,m
        do i=1,j
           call gauss_noise(r)
           spforcc(i,j)  = alpha_sppt*spforcc(i,j)+  spamp(j)*r
           call gauss_noise(r)
           spforcs(i,j)  = alpha_sppt*spforcs(i,j) + spamp(j)*r
       enddo
      enddo 

     end subroutine spatio_temporal_update 
!====================================================================
     subroutine gauss_noise(z)
      real :: z                    ! output
      real :: x,y,r, coeff         ! INPUT
!  [2.1] Get two uniform variate random numbers IL range 0 to 1:
      do
      call random_number( x )
      call random_number( y )
!     [2.2] Transform to range -1 to 1 and calculate sum of squares:
      x = 2.0 * x - 1.0
      y = 2.0 * y - 1.0
      r = x * x + y * y
      if ( r > 0.0 .and. r < 1.0 ) exit
      end do
!
!  [2.3] Use Box-Muller transformation to get normal deviates:
      coeff = sqrt( -2.0 * log(r) / r )
      z = coeff * x
     end subroutine gauss_noise
!====================================================================
!! ---- TRANSFORM FROM SPHERICAL HARMONICS TO GRIDPOINT SPACE**
      subroutine sh2gp(RA,RB,rstoch_glob,MMAX,NMAX,NLAT,NLON)
      use spmd_utils,   only: masterproc

      IMPLICIT NONE 
      INTEGER :: ierror,NMAX,MMAX,NLAT,NLON,i,j,lwork
      REAL, DIMENSION (0:MMAX,0:NMAX) :: RA,RB 
      REAL, DIMENSION (NLAT,NLON) :: RGP 
      REAL, DIMENSION (NLON,NLAT) :: rstoch_glob
      REAL, allocatable :: work (:)



      ierror=99
      lwork=(1+1)*nlat*nlon
      ALLOCATE(work(lwork))
      call shses(nlat,nlon,0,1,RGP,NLAT,NLON,RA,RB,MMAX+1,NMAX+1,wshses,lshses,work,lwork,ierror)!lon/lat grid
      if(ierror .ne. 0) write(*,94) ierror 
      94 format('error in shses=  ',i5) 
      DEALLOCATE (work)


      do i=1,nlat
       do j=1,nlon
          !rstoch_glob(j,i)=1.0*i
          rstoch_glob(j,i)=RGP(i,j)
       enddo 
      enddo 

      end subroutine sh2gp
end module cam_stoch
