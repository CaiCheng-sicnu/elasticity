FC = gfortran
FCOPTS = -g -fbounds-check
BINDIR = ~/Applications/bin
LIBDIR = ~/Applications/modules/lib
MODDIR = ~/Applications/modules/mods
LIBS = -lEC_grid -lanisotropy_ajn

all: progs

progs: EC_grid_edit_bin

install: all
	/bin/cp EC_grid_edit_bin $(BINDIR)/

EC_grid_edit_bin: EC_grid_edit_bin.o 
	$(FC) ${FCOPTS} -o $@ -L $(LIBDIR) ${LIBS} $^

%.o: %.f90
	$(FC) ${FCOPTS} -c -I $(MODDIR) $*.f90

.PHONY: clean

clean:
	/bin/rm -f *.o EC_grid_edit_bin
