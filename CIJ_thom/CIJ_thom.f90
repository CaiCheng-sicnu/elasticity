!===============================================================================
program thompson_parameter
!===============================================================================
!  Program form of the CIJ_thom routine in anisotropy_ajn module

   use anisotropy_ajn
   
   implicit none
   
   real(8) :: ecs(6,6)
   real(8) :: vp,vs,rho,del,eps,gam
   integer :: i
   character(len=250) :: arg
   
   if (command_argument_count() /= 6) then
      write(0,'(a)') 'Usage:  CIJ_thom [vp] [vs] [rho] [delta] [epsilon] [gamma]',&
                     '  Rotationally symmetric about 3-axis (vertical)'
      write(0,'(a)') '  Sends 36 elastic constants to stdout (density-normalised).'
      stop
   endif
   
   call get_command_argument(1,arg) ;  read(arg,*) vp
   call get_command_argument(2,arg) ;  read(arg,*) vs
   call get_command_argument(3,arg) ;  read(arg,*) rho
   call get_command_argument(4,arg) ;  read(arg,*) del
   call get_command_argument(5,arg) ;  read(arg,*) eps
   call get_command_argument(6,arg) ;  read(arg,*) gam
   
   ecs = CIJ_thom(vp,vs,rho,eps,gam,del)
   
   write(*,*) ecs/rho
   
end program thompson_parameter
!-------------------------------------------------------------------------------
