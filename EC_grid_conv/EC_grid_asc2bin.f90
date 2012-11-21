!===============================================================================
program EC_grid_asc2bin
!===============================================================================
!  Convert an ASCII EC_grid file to a binary one.  Reads name as first argument
!  or provide a list on stdin.  Adds .bin to end of file name.

   use EC_grid
   
   implicit none
   
   character(len=250) :: infile,outfile
   type(ECgrid) :: grid
   integer :: necs
   logical :: quiet=.false.
   
!  Command line parameters
   if (iargc() /= 1 .and. iargc() /= 2 .and. iargc() /= 3) then
      write(0,'(a)') 'Usage: EC_grid_asc2bin (-quiet) [infile] (outfile)'
      stop
   endif
   
   call getarg(1,infile)
   if (infile(1:2) == '-q') then
      quiet = .true.
      call getarg(2,infile)
   endif
   
   if (quiet .and. iargc() == 3) then   ! Have specified -q, infile and outfile
      call getarg(3,outfile)
   else if (.not.quiet .and. iargc() == 2) then  !  Have specified infile and outfile
      call getarg(2,outfile)
   else                                 ! Haven't specified outfile
      outfile = trim(infile) // '.bin'
   endif
   
!  Work out number of ecs (21 or 36) in ASCII file
   necs = EC_grid_check_necs(infile)
   write(0,*) necs,' necs in input'
   
!  Load ecs into memory
   call EC_grid_load(infile,grid,necs,quiet=quiet)
   
!  Write binary grid file
   call EC_grid_write_bin(outfile,grid)
   
end program EC_grid_asc2bin