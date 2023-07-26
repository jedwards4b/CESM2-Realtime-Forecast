module MCB_mask
use netcdf
use shr_kind_mod,   only: r8=>shr_kind_r8
use ppgrid,         only: pcols
use phys_grid,      only: get_lon_all_p, get_lat_all_p
use pmgrid,     only : plon, plat

implicit none
private
save

public :: read_MCB_mask, get_MCB_mask

character(len=*), parameter :: mask_file = '/glade/work/jesswan/scripps/SMYLE-MCB/mask_CESM/sesp_mask_CESM2_0.9x1.25_v1.nc'
real(r8), save :: mask2D(plon, plat, 12)

contains

subroutine read_MCB_mask
       implicit none
  
       integer :: ncid, varid, status
       
       status = nf90_open(mask_file, nf90_nowrite, ncid)
       status = nf90_inq_varid(ncid, 'mask', varid)
       status = nf90_get_var(ncid, varid, mask2D)
       status = nf90_close(ncid)
end subroutine read_MCB_mask

subroutine get_MCB_mask(lchnk, ncol, mask)
       use time_manager,       only: get_curr_date
       use cam_history,        only: outfld

       integer, intent(in) :: lchnk
       integer, intent(in) :: ncol
       real(r8), intent(out) :: mask(pcols)

       integer :: yr, mon, day, ncsec, i
       integer :: lons(pcols), lats(pcols)

       mask = 0._r8
       call get_curr_date(yr, mon, day, ncsec)

       call get_lon_all_p(lchnk,ncol,lons)
       call get_lat_all_p(lchnk,ncol,lats)      

       if(yr==2019) then
          do i=1,ncol
             mask(i) = mask2D(lons(i), lats(i), mon)
          end do
       else
          do i=1,ncol
             mask(i) = 0._r8
          end do
       end if

      call outfld('MCB_mask', mask, pcols, lchnk) 

end subroutine get_MCB_mask

end module MCB_mask
