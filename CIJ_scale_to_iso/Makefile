FC = gfortran
FCOPTS = -g -fbounds-check
BINDIR = ~/Applications/bin
LIBDIR = ~/Applications/modules/lib
MODDIR = ~/Applications/modules/mods
LIBS = -lanisotropy_ajn -lspherical_geometry

all: CIJ_scale_to_iso

install: all
	/bin/cp CIJ_scale_to_iso $(BINDIR)/

CIJ_scale_to_iso: CIJ_scale_to_iso.o 
	$(FC) ${FCOPTS} -o CIJ_scale_to_iso -L $(LIBDIR) ${LIBS} CIJ_scale_to_iso.o

%.o: %.f90
	$(FC) ${FCOPTS} -c -J $(MODDIR) $*.f90

.PHONY: clean

clean:
	/bin/rm -f CIJ_scale_to_iso *.mod *.o
