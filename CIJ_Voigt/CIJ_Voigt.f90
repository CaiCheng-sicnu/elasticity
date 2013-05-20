!===============================================================================
program CIJ_Voigt
!===============================================================================
! Accepts a number of lines of 21 or 36 elastic constants + density on stdin and
! writes out the Voigt average.

   use anisotropy_ajn, only: CIJ_Voigt_av, CIJ_symm, CIJ_disp
   use get_args

   implicit none
   
   integer, parameter :: rs = 8   ! DP
   integer, parameter :: nmax = 10000    ! Maximum number of lines to average
   integer :: nlines, iostatus, i, j
   integer :: necs = 36  ! Default to 36 ecs + density
   integer :: necs_out = 36
   real(rs), dimension(nmax) :: VF, rh
   real(rs), dimension(nmax,6,6) :: C
   real(rs) :: Cave(6,6), rhave
   logical :: supplied
   
   ! Check any command line arguments
   if (command_argument_count() /= 0) then
      ! Specfiy number of ECs fed in
      call get_arg("-n",necs,supplied=supplied)
      if (supplied) then
         if (necs /= 21 .and. necs /= 36) call usage
         necs_out = necs
      endif
      
      ! Specify number of ECs to write out (default to same)
      call get_arg("-o",necs_out,supplied=supplied)
      if (supplied) then
         if (necs_out /= 21 .and. necs_out /= 36) call usage
      endif
   endif
   
   ! Loop over lines on stdin
   nlines = 0
   iostatus = 0
   in_loop: do while (iostatus == 0)
      nlines = nlines + 1
      if (necs == 21) then
         read(*,*,iostat=iostatus) ((C(nlines,i,j),j=i,6),i=1,6),rh(nlines)
         call CIJ_symm(C(nlines,:,:))
      else
         read(*,*,iostat=iostatus) ((C(nlines,i,j),j=1,6),i=1,6),rh(nlines)
      endif
      
      ! Read error
      if (iostatus > 0) then
         write(0,'(a,i0.0,a)') 'CIJ_Voigt: Problem reading ',necs,' + density from stdin'
         stop
      
      ! End-of-line
      else if (iostatus < 0) then
         nlines = nlines - 1
         exit in_loop
      endif
      
      ! Check we haven't averaged too many constants
      if (nlines >= nmax) then
         write(0,'(a,i0.0,a)') 'CIJ_Voigt: number of input constants exceeds precompiled maximum (',nmax,')'
         write(0,'(a)') 'Recompile with larger limits if this is a problem'
         stop
      endif

   enddo in_loop
      
   ! Check we have at least two lines
   if (nlines < 2) then
      write(0,'(a)') 'CIJ_Voigt: more than one set of ECs must be provided on stdin.'
      stop
   endif
   
   ! Calculate Voigt average
   VF = 1.
   call CIJ_Voigt_av(VF(1:nlines),C(1:nlines,:,:),rh(1:nlines),Cave,rhave)
   
   ! Write out answer with same number
   if (necs_out == 21) then
      write(*,*) ((Cave(i,j),j=i,6),i=1,6),rhave
   else
      write(*,*) ((Cave(i,j),j=1,6),i=1,6),rhave
   endif
   
end program CIJ_Voigt
!-------------------------------------------------------------------------------

!===============================================================================
subroutine usage()
!===============================================================================
! Writes out a usage statement

   implicit none
   
   write(0,'(a)') &
      'CIJ_Voigt: Compute the Voigt average of two or more elastic tensors and densities.',&
      '           Each tensor is assumed to be summed with equal weight.',&
      'Usage: CIJ_Voigt (options) < [(36) ecs + rho on stdin]',&
      'Options:',&
      '   -n [necs]   : Set number of ecs on stdin (21 or 36) [36]',&
      '   -o [necs]   : Set number of ecs sent to stdout (21 or 36) [same as in]'
   
   stop
end subroutine usage
!-------------------------------------------------------------------------------