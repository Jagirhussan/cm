# -*- makefile -*-
#
# For use with GNU make.
#
# $Id: Makefile 27 2007-07-24 16:52:51Z cpb $
#
#----------------------------------------------------------------------------------------------------------------------------------
# Makefile for compiling OpenCMISS library
#
# Original by Chris Bradley adapted from the CMISS Makefile by Karl Tomlinson 
# Changes:
#
#----------------------------------------------------------------------------------------------------------------------------------
#
# LICENSE
#
# Version: MPL 1.1/GPL 2.0/LGPL 2.1
#
# The contents of this file are subject to the Mozilla Public License
# Version 1.1 (the "License"); you may not use this file except in
# compliance with the License. You may obtain a copy of the License at
# http://www.mozilla.org/MPL/
#
# Software distributed under the License is distributed on an "AS IS"
# basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
# License for the specific language governing rights and limitations
# under the License.
#
# The Original Code is OpenCMISS
#
# The Initial Developer of the Original Code is University of Auckland,
# Auckland, New Zealand and University of Oxford, Oxford, United
# Kingdom. Portions created by the University of Auckland and University
# of Oxford are Copyright (C) 2007 by the University of Auckland and
# the University of Oxford. All Rights Reserved.
#
# Contributor(s):
#
# Alternatively, the contents of this file may be used under the terms of
# either the GNU General Public License Version 2 or later (the "GPL"), or
# the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
# in which case the provisions of the GPL or the LGPL are applicable instead
# of those above. If you wish to allow use of your version of this file only
# under the terms of either the GPL or the LGPL, and not to allow others to
# use your version of this file under the terms of the MPL, indicate your
# decision by deleting the provisions above and replace them with the notice
# and other provisions required by the GPL or the LGPL. If you do not delete
# the provisions above, a recipient may use your version of this file under
# the terms of any one of the MPL, the GPL or the LGPL.
#	
#----------------------------------------------------------------------------------------------------------------------------------

MAKEFLAGS = --no-builtin-rules --warn-undefined-variables

#----------------------------------------------------------------------------------------------------------------------------------

ifndef OPENCMISS_ROOT
  OPENCMISS_ROOT := ../../..
  GLOBAL_CM_ROOT := $(CURDIR)/../../..
  GLOBAL_CELLML_ROOT := $(CURDIR)/../../..
else
  GLOBAL_CM_ROOT := ${OPENCMISS_ROOT}/cm
  GLOBAL_CELLML_ROOT := ${OPENCMISS_ROOT}/cellml
endif

#----------------------------------------------------------------------------------------------------------------------------------

ifndef OPENCMISSEXTRAS_ROOT
  OPENCMISSEXTRAS_ROOT := ../../opencmissextras
  EXTERNAL_CM_ROOT := $(CURDIR)/../../opencmissextras/cm/external
else
  EXTERNAL_CM_ROOT := ${OPENCMISSEXTRAS_ROOT}/cm/external
endif

include $(GLOBAL_CM_ROOT)/utils/Makefile.inc

#----------------------------------------------------------------------------------------------------------------------------------

ifndef MPI
  MPI := mpich2
endif

ifndef USECELLMLL
  USECELLML := false
endif

ifeq ($(MPI),mpich2)
  MPI := mpich2
else
  ifeq ($(MPI),intel)
    ifeq ($(OPERATING_SYSTEM),linux)
      ifdef I_MPI_ROOT
        MPI := intel
      else
        $(error Intel MPI libraries not setup)
      endif
    else
      $(error can only use intel mpi with Linux)
    endif
  else
    ifeq ($(MPI),openmpi)
      MPI := openmpi
    else
      ifeq ($(MPI),mvapich2)
        MPI := mvapich2
      else
        ifeq ($(MPI),cray)
          MPI := cray
        else
          $(error unknown MPI type - $(MPI))
        endif
      endif
    endif
  endif
endif

ifeq ($(MPIPROF),true)
  ifeq ($(MPI),intel)
    ifndef VT_ROOT
      $(error intel trace collector not setup)
    endif
    ifndef VT_ADD_LIBS
      $(error intel trace collector not setup)
    endif
  endif
endif

#----------------------------------------------------------------------------------------------------------------------------------

BASE_LIB_NAME = OpenCMISS
SOURCE_DIR = $(GLOBAL_CM_ROOT)/src
OBJECT_DIR := $(GLOBAL_CM_ROOT)/object/$(LIB_ARCH_DIR)$(MT_SUFFIX)$(DEBUG_SUFFIX)$(PROF_SUFFIX)/$(MPI)/$(COMPILER)
MODULE_DIR := $(OBJECT_DIR)
INC_DIR := $(GLOBAL_CM_ROOT)/include/$(BIN_ARCH_DIR)/$(MPI)/$(COMPILER)
MOD_INC_NAME := opencmiss.mod
MOD_INCLUDE := $(INC_DIR)/$(MOD_INC_NAME)
MOD_SOURCE_INC := $(OBJECT_DIR)/$(MOD_INC_NAME)
HEADER_INC_NAME := opencmiss.h
HEADER_INCLUDE := $(INC_DIR)/$(HEADER_INC_NAME)
HEADER_SOURCE_INC := $(SOURCE_DIR)/$(HEADER_INC_NAME)
LIB_DIR := $(GLOBAL_CM_ROOT)/lib/$(BIN_ARCH_DIR)/$(MPI)/$(COMPILER)
LIB_NAME := lib$(BASE_LIB_NAME)$(EXE_ABI_SUFFIX)$(MT_SUFFIX)$(DEBUG_SUFFIX)$(PROF_SUFFIX).a
LIBRARY := $(LIB_DIR)/$(LIB_NAME)
ifeq ($(OPERATING_SYSTEM),linux)# Linux
  EXTERNAL_CM_DIR := $(EXTERNAL_CM_ROOT)/$(LIB_ARCH_DIR)$(DEBUG_SUFFIX)$(PROF_SUFFIX)/$(MPI)/$(COMPILER)
else
  ifeq ($(OPERATING_SYSTEM),aix)# AIX
    EXTERNAL_CM_DIR := $(EXTERNAL_CM_ROOT)/$(LIB_ARCH_DIR)$(DEBUG_SUFFIX)$(PROF_SUFFIX)
  else# windows
    EXTERNAL_CM_DIR := $(EXTERNAL_CM_ROOT)/$(LIB_ARCH_DIR)$(DEBUG_SUFFIX)$(PROF_SUFFIX)
  endif
endif

C_INCLUDE_DIRS := $(SOURCE_DIR) 
F_INCLUDE_DIRS := $(MODULE_DIR)

#----------------------------------------------------------------------------------------------------------------------------------
# compiling commands

ifeq ($(MPI),mpich2)
  MPIFC = mpif90
  MPICC = mpicc
else
  MPIFC = mpiifort
  MPICC = mpiicc
endif
FC = $(MPIFC)
CC = $(MPICC)
AR = ar
EXE_LINK = $(FC)
DSO_LINK = ld

DBGCF_FLGS = -g #OPT=false flags for C and fortran
# Option lists
# (suboption lists become more specific so that later ones overrule previous)
CFLAGS = $(strip $(CFL_FLGS) $(CFE_FLGS) $(CF_FLGS) $(C_FLGS))
FFLAGS = $(strip $(CFL_FLGS) $(CFE_FLGS) $(CF_FLGS) $(F_FLGS))
CPPFLAGS := $(addprefix -I, $(C_INCLUDE_DIRS) )
FPPFLAGS := $(addprefix -I, $(F_INCLUDE_DIRS) )
ELFLAGS = $(strip $(CFL_FLGS) $(L_FLGS) $(CFE_FLGS))
DLFLAGS = $(strip $(CFL_FLGS) $(L_FLGS) $(D_FLGS))
ifneq ($(DEBUG),false)
  CFLAGS += $(strip $(DBGCF_FLGS) $(DBGC_FLGS))
  FFLAGS += $(strip $(DBGCF_FLGS) $(DBGF_FLGS))
  CPPFLAGS += -DDEBUG
else
  ifneq ($(MPIPROF),false)
    CFLAGS += $(strip $(DBGCF_FLGS) $(DBGC_FLGS))
    FFLAGS += $(strip $(DBGCF_FLGS) $(DBGF_FLGS))
    CPPFLAGS += -DDEBUG
  else
    CFLAGS += $(strip $(OPTCFE_FLGS) $(OPTCF_FLGS) $(OPTC_FLGS))
    FFLAGS += $(strip $(OPTCFE_FLGS) $(OPTCF_FLGS) $(OPTF_FLGS))
    ELFLAGS += $(OPTCFE_FLGS)
  endif
endif
ifneq ($(MP),false)
  CFLAGS += $(MP_FLGS)
  FFLAGS += $(MP_FLGS)
endif
ARFLAGS = -crsv
# suboption lists
CFL_FLGS =#	flags for C fortran and linking
L_FLGS =#	flags for linking only
CFE_FLGS =#	flags for C fortran and linking executables only
CF_FLGS = -c#	flags for C and fortran only
C_FLGS =#       flags for C only
F_FLGS =#       flags for fortran only
D_FLGS = -shared#     for linking dynamic shared objects only
DBGC_FLGS =#	OPT=false flags for C only
DBGF_FLGS =#	OPT=false flags for fortran only
OPTCFE_FLGS =#	OPT=true flags for C and fortran and linking executables
OPTCF_FLGS = -O#OPT=true flags for C and fortran only
OPTC_FLGS =#	OPT=true flags for C only
OPTF_FLGS =#	OPT=true flags for fortran only

# The list of objects may be too long for the operating system limit on
# argument length so the list of objects is stored in a file.  This linker
# arguments for this file depend on the linker.  If the linker cannot
# interpret such a file then try to use the shell and hope the list isn't too
# long.
olist_args = `cat $1`

#----------------------------------------------------------------------------------------------------------------------------------
ifeq ($(OPERATING_SYSTEM),linux)
  OPTCF_FLGS =# Use separate flags for fortran and c
  olist_args = $1

  CC = gcc
  FC = gfortran

  ifeq ($(COMPILER),intel)

    #Use Intel compilers if available (icc -V sends output to STDERR and exits with error).
    ifneq (,$(shell icc -V 2>&1 | grep -i intel))
      CC = icc
    endif
    ifneq (,$(shell ifort -V 2>&1 | grep -i intel))
      FC = ifort
    endif

  endif	

  # Set the flags for the various different CC compilers
  ifeq ($(CC),gcc)# gcc
    C_FLGS += -pipe
    # Position independent code is actually only required for objects
    # in shared libraries but debug version may be built as shared libraries.
    DBGC_FLGS += -fPIC
    ifeq ($(filter $(INSTRUCTION),i686 ia64),)# not i686 nor ia64
      C_FLGS += -m$(ABI)
    endif
    ifeq ($(MACHNAME),x86_64)
      ifneq ($(shell grep Intel /proc/cpuinfo 2>/dev/null),)
        C_FLGS += -march=nocona
      endif
    endif
    DBGC_FLGS += -O0 -fbounds-check
    OPTC_FLGS = -O3 -funroll-all-loops
    ifeq ($(PROF),false)
      ifneq ($(filter $(INSTRUCTION),i686 x86_64),)# i686 or x86_64
        OPTC_FLGS += -momit-leaf-frame-pointer
      endif
    else
      C_FLGS += -g -pg# -fprofile-arcs -ftest-coverage
    endif
  endif
  ifeq ($(CC),icc)
    # Turn on all warnings
    C_FLGS += -Wall
    ifeq ($(MACHNAME),x86_64)
      ifneq ($(shell grep Intel /proc/cpuinfo 2>/dev/null),)
        ifneq ($(shell grep Duo /proc/cpuinfo 2>/dev/null),)
          ifneq ($(shell grep "Core(TM)2" /proc/cpuinfo 2>/dev/null),)
            C_FLGS += -xT# Core2 Duo	
          else
            C_FLGS += -x0# Core Duo
          endif        
        else
          C_FLGS += -xP# for sse3 (90nm Pentium 4 series)
        endif
      else
        C_FLGS += -xW# Pentium4 compatible (?sse2)
      endif
    endif
    ifeq ($(filter-out i%86,$(MACHNAME)),)
      ifneq ($(shell grep sse2 /proc/cpuinfo 2>/dev/null),)
        C_FLGS += -xN# for Pentium 4
      endif
    endif
    DBGC_FLGS += -O0
    OPTC_FLGS = -O3 -ansi_alias
    ifneq ($(PROF),false)
      C_FLGS += -g -pg
      ELFLAGS += -pg
    endif
    ifeq ($(MPIPROF),true)
      ifeq ($(MPI),mpich2)
        C_FLGS += -Wl,--export-dyanmic
        DBGC_FLGS += -Wl,--export-dyanmic
      else
        C_FLGS += -tcollect
      endif
    endif
  endif
  ifeq ($(filter-out xlc%,$(CC)),)# xlc* C compiler
    CFLAGS += -qinfo=gen:ini:por:pro:trd:tru:use
    C_FLGS += -q$(ABI) -qarch=auto -qhalt=e
    # -qinitauto for C is bytewise: 7F gives large integers.
    DBGC_FLGS += -qfullpath -C -qflttrap=inv:en -qinitauto=7F
    OPTC_FLGS += -O3
    # for trailing _ on fortran symbols
    CPPFLAGS += -Dunix
  endif
  ifeq ($(CC),cc)# cray cc
    DBGC_FLGS += -O0 -g
    OPTC_FLGS = -O3 
    ifeq ($(PROF),true)
      C_FLGS += -g -pg
    endif
  endif

  # Set the flags for the various different Fortran compilers
  ifeq ($(FC),gfortran)
    #FC = /home/users/local/packages/gfortran/irun/bin/gfortran
    # -fstatck-check
    F_FLGS += -pipe -fno-second-underscore -Wall -x f95-cpp-input
    # Restrict line length to 132
    F_FLGS += -ffree-line-length-132
    # for now change max identifier length. Should restrict to 63 (F2003) in future
    F_FLGS += -fmax-identifier-length=63
    # Position independent code is actually only required for objects
    # in shared libraries but debug version may be built as shared libraries.
    DBGF_FLGS += -fPIC
    ifeq ($(filter $(INSTRUCTION),i686 ia64),)# i686 nor ia64
      F_FLGS += -m$(ABI)
      ELFLAGS += -m$(ABI)
    endif
    ifeq ($(MACHNAME),x86_64)
      ifneq ($(shell grep Intel /proc/cpuinfo 2>/dev/null),)
        F_FLGS += -march=nocona
      endif
    endif
    DBGF_FLGS += -O0 -fbounds-check
    OPTF_FLGS = -O3 -Wuninitialized -funroll-all-loops
    ifeq ($(PROF),false)
      ifneq ($(filter $(INSTRUCTION),i686 x86_64),)# i686 or x86_64
        OPTF_FLGS += -momit-leaf-frame-pointer
      endif
    else
      F_FLGS += -g -pg# -fprofile-arcs -ftest-coverage
      ELFLAGS += -pg
    endif
  endif
  ifeq ($(FC),g95)
    F_FLAGS += -fno-second-underscore -Wall -std=f2003
    DBGF_FLGS += -fPIC
    ifeq ($(filter $(INSTRUCTION),i686 ia64),)# i686 nor ia64
      F_FLGS += -m$(ABI)
      ELFLAGS += -m$(ABI)
    endif
    DBGF_FLGS += -O0 -fbounds-check
    OPTF_FLGS = -O3 -Wuninitialized -funroll-all-loops
    #$(error g95 not implemented)
  endif
  ifeq ($(FC),ifort)
    # turn on preprocessing,
    # turn on warnings,
    # warn about non-standard Fortran 95
    F_FLGS += -cpp -warn all 
    ifeq ($(MACHNAME),x86_64)
      ifneq ($(shell grep Intel /proc/cpuinfo 2>/dev/null),)
        ifneq ($(shell grep Duo /proc/cpuinfo 2>/dev/null),)
          ifneq ($(shell grep "Core(TM)2" /proc/cpuinfo 2>/dev/null),)
            F_FLGS += -xT# Core2 Duo	
          else
            F_FLGS += -x0# Core Duo
          endif        
        else
          F_FLGS += -xP# for sse3 (90nm Pentium 4 series)
        endif
      else
        F_FLGS += -xW# Pentium4 compatible (?sse2)
      endif
    endif
    ifeq ($(filter-out i%86,$(MACHNAME)),)
      ifneq ($(shell grep sse2 /proc/cpuinfo 2>/dev/null),)
        F_FLGS += -xN# for Pentium 4
      endif
    endif
    DBGF_FLGS += -O0 -check all -traceback -debug all
    OPTF_FLGS = -O3
    ifneq ($(PROF),false)
      F_FLGS += -g -pg
      ELFLAGS += -pg
    endif
    ifeq ($(MPIPROF),true)
      ifeq ($(MPI),mpich2)
        F_FLAS += -Wl,--export-dyanmic
        DBGF_FLGS += -Wl,--export-dyanmic
      else
        F_FLGS += -tcollect
      endif
    endif
#    MP_FLGS = -openmp
    ELFLAGS += -nofor_main -traceback
  endif
  ifeq ($(filter-out xlf%,$(FC)),)# xlf* fortran compiler
    F_FLGS += -q$(ABI) -qarch=auto -qhalt=e -qextname -qsuffix=cpp=f90
    ELFLAGS += -q$(ABI)
    ifeq ($(ABI),64)
      F_FLGS += -qwarn64
    endif
    ifeq ($(DEBUG),false)
      MP_FLGS = -qsmp=omp
    else
      MP_FLGS = -qsmp=omp:noopt
    endif
    # -qinitauto for Fortran 7FF7FFFF is a large integer or NaNQ real*4 or NaNS real*8
    DBGF_FLGS += -qfullpath -C -qflttrap=inv:en -qextchk -qinitauto=7FF7FFFF
    OPTF_FLGS += -O3
  endif
  ifeq ($(FC),ftn)
    DBGF_FLGS += -O0 -g
    OPTF_FLGS = -O3 
    ifeq ($(PROF),true)
      F_FLGS += -g -pg
      ELFLAGS += -pg
    endif
  endif

  # Avoid versioning problems with libgcc_s by linking statically.

  # libgcc2.c from gcc 3.4.4 says:
  # In addition to the permissions in the GNU General Public License, the
  # Free Software Foundation gives you unlimited permission to link the
  # compiled version of this file into combinations with other programs,
  # and to distribute those combinations without any restriction coming
  # from the use of this file.

  # (With dynamic version, should copy libgcc_s.so.N if copying libstdc++.so.N)
  ELFLAGS += -static-libgcc

  # Use the BSD timers
  CPPFLAGS += -DBSD_TIMERS
endif
ifeq ($(OPERATING_SYSTEM),win32)
  FC = gfortran
  F_FLGS += -fno-second-underscore
  OPTCF_FLGS = -O2
  ELFLAGS += -Wl,-static
  # Use the ANSI C timers
  CPPFLAGS += -DANSI_C_TIMERS
  olist_args = $1
endif
ifeq ($(OPERATING_SYSTEM),aix)
  ifeq ($(MP),false)
    FC = mpxlf95
    CC = xlc
  else
    FC = mpxlf95_r
    CC = xlc_r
  endif
  F_FLGS += -qsuffix=cpp=f90 -qnoextname
  CFLAGS += -qinfo=gen:ini:por:pro:trd:tru:use
  ELFLAGS += -q$(ABI) 
  CFE_FLGS += -q$(ABI) -qarch=auto -qhalt=e
  L_FLGS += -b$(ABI)
  D_FLGS = -G -bexpall -bnoentry
  ifeq ($(ABI),32)
    # Without -bmaxdata, the only one 256M virtual segment is available for
    # data.
    # In AIX 5.3, 0xAFFFFFFF is the largest value we can use here and still
    # use global shared libraries. (see aixprggd/genprogc/lrg_prg_support.htm)
    # However, 0xAFFFFFFF/dsa causes the system to crash on loading of perl
    # modules (File::Find and Time::HiRes atleast).  0x80000000 seems to work.
    # dsa allows segments to be allocated dynamically for shmat/mmap or data
    # as required.
    ELFLAGS += -bmaxdata:0x80000000/dsa
  else
    CF_FLGS += -qwarn64 
    # It seems that somewhere between AIX 5.1 and 5.3 the kernel loader
    # started modifying a process's soft data resource limit to match to match
    # its maxdata value (if non-zero).  As 32-bit applications need a non-zero
    # maxdata value to access more than 256M of data many applications
    # (including perl) will cause the data limit to be lowered to a 32-bit
    # addressable value.  As cmiss is likely to be a child of such 32-bit
    # processes, to access more than 32-bit addressable memory, it either
    # needs to raise its data limit or use its own maxdata value.
    # max heap size is 0x06FFFFFFFFFFFFF8
    # Arbitrary.  0x0000100000000000 should provide ~16TB.
    ELFLAGS += -bmaxdata:0x0000100000000000
  endif
  ifeq ($(DEBUG),false)
    MP_FLGS = -qsmp=omp
  else
    MP_FLGS = -qsmp=omp:noopt
  endif
  # Should -qflttrap=nans be used as well or instead of -qflttrap=inv:en?
  DBGCF_FLGS += -qfullpath -C -qflttrap=inv:en -qextchk
  # -qinitauto for Fortran: 7FF7FFFF is a large integer or NaNQ real*4 or NaNS real*8
  # -qinitauto for C is bytewise: 7F gives large integers.
  DBGF_FLGS += -qinitauto=7FF7FFFF
  DBGC_FLGS += -qinitauto=7F
  OPTCF_FLGS = -O3 
  OPTC_FLGS += -qnoignerrno
  olist_args = -f $1
  # Use the BSD timers
  CPPFLAGS += -DBSD_TIMERS
endif

# This returns an empty string if not found
searchdirs = $(firstword $(wildcard $(addsuffix /$(strip $2),$1)))
# This still returns the name of the desired file if not found and so is useful for error checking and reporting.
searchdirsforce = $(firstword $(wildcard $(addsuffix /$(strip $2),$1)) $2)

# Check that call function works (for searchdirs, olist_args, etc.)
ifeq ($(call olist_args,test),)
  $(error call function not available.  Use GNU make version 3.78 or newer)
endif

#TAO
TAO_INCLUDE_PATH =#
ifeq ($(OPERATING_SYSTEM),linux)# Linux
  TAO_INCLUDE_PATH += $(addprefix -I, $(EXTERNAL_CM_DIR)/ )
  TAO_INCLUDE_PATH += $(addprefix -I, $(EXTERNAL_CM_DIR)/include/ )
  TAO_INCLUDE_PATH += $(addprefix -I, $(EXTERNAL_CM_DIR)/include/finclude )
else
  ifeq ($(OPERATING_SYSTEM),aix)# AIX
    TAO_INCLUDE_PATH += $(addprefix -I, $(EXTERNAL_CM_DIR)/ )
    TAO_INCLUDE_PATH += $(addprefix -I, $(EXTERNAL_CM_DIR)/include/ )
    TAO_INCLUDE_PATH += $(addprefix -I, $(EXTERNAL_CM_DIR)/include/finclude )
  else# windows
    TAO_INCLUDE_PATH = $(addprefix -I, /home/users/local/ )
  endif
endif

#PETSc
PETSC_INCLUDE_PATH =#
ifeq ($(OPERATING_SYSTEM),linux)# Linux
  PETSC_INCLUDE_PATH += $(addprefix -I, $(EXTERNAL_CM_DIR)/ )
  PETSC_INCLUDE_PATH += $(addprefix -I, $(EXTERNAL_CM_DIR)/include/ )
  PETSC_INCLUDE_PATH += $(addprefix -I, $(EXTERNAL_CM_DIR)/conf )
else
  ifeq ($(OPERATING_SYSTEM),aix)# AIX
    PETSC_INCLUDE_PATH += $(addprefix -I, $(EXTERNAL_CM_DIR)/ )
    PETSC_INCLUDE_PATH += $(addprefix -I, $(EXTERNAL_CM_DIR)/include/ )
    PETSC_INCLUDE_PATH += $(addprefix -I, $(EXTERNAL_CM_DIR)/conf/ )
  else# windows
    PETSC_LIB_PATH += $(addprefix -L, /home/users/local/lib/ )
    PETSC_INCLUDE_PATH = $(addprefix -I, /home/users/local/ )
  endif
endif

#SUNDIALS
SUNDIALS_INCLUDE_PATH =#
ifeq ($(OPERATING_SYSTEM),linux)# Linux
  SUNDIALS_INCLUDE_PATH += $(addprefix -I, $(EXTERNAL_CM_DIR)/ )
  SUNDIALS_INCLUDE_PATH += $(addprefix -I, $(EXTERNAL_CM_DIR)/include/ )
else
  ifeq ($(OPERATING_SYSTEM),aix)# AIX
    SUNDIALS_INCLUDE_PATH += $(addprefix -I, $(EXTERNAL_CM_DIR)/ )
    SUNDIALS_INCLUDE_PATH += $(addprefix -I, $(EXTERNAL_CM_DIR)/include/ )
  else# windows
    SUNDIALS_INCLUDE_PATH = $(addprefix -I, /home/users/local/ )
  endif
endif

#HYPRE
HYPRE_INCLUDE_PATH =#
ifeq ($(OPERATING_SYSTEM),linux)# Linux
  HYPRE_INCLUDE_PATH += $(addprefix -I, $(EXTERNAL_CM_DIR)/ )
  HYPRE_INCLUDE_PATH += $(addprefix -I, $(EXTERNAL_CM_DIR)/include/ )
else
  ifeq ($(OPERATING_SYSTEM),aix)# AIX
    HYPRE_INCLUDE_PATH += $(addprefix -I, $(EXTERNAL_CM_DIR)/ )
    HYPRE_INCLUDE_PATH += $(addprefix -I, $(EXTERNAL_CM_DIR)/include/ )
  else# windows
    HYPRE_INCLUDE_PATH = $(addprefix -I, /home/users/local/ )
  endif
endif

#MUMPS
MUMPS_INCLUDE_PATH =#
ifeq ($(OPERATING_SYSTEM),linux)# Linux
  MUMPS_INCLUDE_PATH += $(addprefix -I, $(EXTERNAL_CM_DIR)/ )
  MUMPS_INCLUDE_PATH += $(addprefix -I, $(EXTERNAL_CM_DIR)/include/ )
else
  ifeq ($(OPERATING_SYSTEM),aix)# AIX
    MUMPS_INCLUDE_PATH += $(addprefix -I, $(EXTERNAL_CM_DIR)/ )
    MUMPS_INCLUDE_PATH += $(addprefix -I, $(EXTERNAL_CM_DIR)/include/ )
  else# windows
    MUMPS_INCLUDE_PATH = $(addprefix -I, /home/users/local/ )
  endif
endif

#ScaLAPACK
SCALAPACK_INCLUDE_PATH =#
ifeq ($(OPERATING_SYSTEM),linux)# Linux
  SCALAPACK_INCLUDE_PATH += $(addprefix -I, $(EXTERNAL_CM_DIR)/ )
  SCALAPACK_INCLUDE_PATH += $(addprefix -I, $(EXTERNAL_CM_DIR)/include/ )
else
  ifeq ($(OPERATING_SYSTEM),aix)# AIX
    SCALAPACK_INCLUDE_PATH += $(addprefix -I, $(EXTERNAL_CM_DIR)/ )
    SCALAPACK_INCLUDE_PATH += $(addprefix -I, $(EXTERNAL_CM_DIR)/include/ )
  else# windows
    SCALAPACK_INCLUDE_PATH = $(addprefix -I, /home/users/local/ )
  endif
endif

#BLACS
BLACS_INCLUDE_PATH =#
ifeq ($(OPERATING_SYSTEM),linux)# Linux
  BLACS_INCLUDE_PATH += $(addprefix -I, $(EXTERNAL_CM_DIR)/ )
  BLACS_INCLUDE_PATH += $(addprefix -I, $(EXTERNAL_CM_DIR)/include/ )
else
  ifeq ($(OPERATING_SYSTEM),aix)# AIX
    BLACS_INCLUDE_PATH += $(addprefix -I, $(EXTERNAL_CM_DIR)/ )
    BLACS_INCLUDE_PATH += $(addprefix -I, $(EXTERNAL_CM_DIR)/include/ )
  else# windows
    BLACS_INCLUDE_PATH = $(addprefix -I, /home/users/local/ )
  endif
endif

#ParMETIS
PARMETIS_INCLUDE_PATH =#

#CELLML
CELLML_INCLUDE_PATH =#
ifeq ($(USECELLML),true)
  ifeq ($(OPERATING_SYSTEM),linux)# Linux
    CELLML_INCLUDE_PATH += $(addprefix -I, $(GLOBAL_CELLML_ROOT)/$(LIB_ARCH_DIR)$(MT_SUFFIX)$(DEBUG_SUFFIX)$(PROF_SUFFIX)/$(COMPILER)/include/ )
  else
    ifeq ($(OPERATING_SYSTEM),aix)# AIX
         CELLML_INCLUDE_PATH += $(addprefix -I, $(GLOBAL_CELLML_ROOT)/$(LIB_ARCH_DIR)$(MT_SUFFIX)$(DEBUG_SUFFIX)$(PROF_SUFFIX)/$(COMPILER)/include/ )
    else# windows
         CELLML_INCLUDE_PATH += $(addprefix -I, $(GLOBAL_CELLML_ROOT)/$(LIB_ARCH_DIR)$(MT_SUFFIX)$(DEBUG_SUFFIX)$(PROF_SUFFIX)/$(COMPILER)/include/ )
    endif
  endif
endif

#MPI
MPI_INCLUDE_PATH =#
ifeq ($(OPERATING_SYSTEM),linux)# Linux
  ifeq ($(MPI),mpich2)
  else
    ifeq ($(MPI),intel)
      ifeq ($(MPIPROF),true)
        MPI_INCLUDE_PATH += $(addprefix -I, $(VT_ROOT)/include/ )
      endif
      ifeq ($(ABI),64)
        MPI_INCLUDE_PATH += $(addprefix -I, $(I_MPI_ROOT)/include64/ )
      else
        MPI_INCLUDE_PATH += $(addprefix -I, $(I_MPI_ROOT)/include/ )
      endif
    else
      MPI_INCLUDE_PATH += $(addprefix -I, $(EXTERNAL_CM_DIR)/lib/ )
    endif
  endif
else
  ifeq ($(OPERATING_SYSTEM),aix)# AIX
  else# windows
  endif
endif

#BLAS/lapack
BLAS_INCLUDE_PATH =#

EXTERNAL_INCLUDE_PATH = $(strip $(TAO_INCLUDE_PATH) $(PETSC_INCLUDE_PATH) $(SUNDIALS_INCLUDE_PATH) $(HYPRE_INCLUDE_PATH) $(MUMPS_INCLUDE_PATH) $(SCALAPCK_INCLUDE_PATH) $(BLACS_INCLUDE_PATH) $(PARMETIS_INCLUDE_PATH) $(MPI_INCLUDE_PATH) $(BLAS_INCLUDE_PATH))

ifeq ($(USECELLML),true)
     EXTERNAL_INCLUDE_PATH += $(CELLML_INCLUDE_PATH)
endif

CPPFLAGS += $(EXTERNAL_INCLUDE_PATH)
FPPFLAGS += $(EXTERNAL_INCLUDE_PATH)

ELFLAGS += $(EXTERNAL_LIB_PATH)

.SUFFIXES:	.f90	.c

$(OBJECT_DIR)/%.o : $(SOURCE_DIR)/%.f90
	( cd $(OBJECT_DIR) ; $(FC) -o $@ $(FFLAGS) $(FPPFLAGS) -c $< )

$(OBJECT_DIR)/%.o : $(SOURCE_DIR)/%.c
	( cd $(OBJECT_DIR) ; $(CC) -o $@ $(CFLAGS) $(CPPFLAGS) -c $< )

ifeq ($(USECELLML),true)
     CELLML_OBJECT = $(OBJECT_DIR)/cmiss_cellml.o
else
     CELLML_OBJECT = $(OBJECT_DIR)/cmiss_cellml_dummy.o
endif

OBJECTS = $(OBJECT_DIR)/advection_diffusion_equation_routines.o \
        $(OBJECT_DIR)/analytic_analysis_routines.o \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/basis_routines.o \
	$(OBJECT_DIR)/bioelectric_routines.o \
	$(OBJECT_DIR)/biodomain_equation_routines.o \
	$(OBJECT_DIR)/boundary_condition_routines.o \
	$(OBJECT_DIR)/blas.o \
	$(OBJECT_DIR)/classical_field_routines.o \
	$(OBJECT_DIR)/cmiss.o \
	$(CELLML_OBJECT) \
	$(OBJECT_DIR)/cmiss_mpi.o \
	$(OBJECT_DIR)/cmiss_parmetis.o \
	$(OBJECT_DIR)/cmiss_petsc.o \
	$(OBJECT_DIR)/cmiss_petsc_types.o \
	$(OBJECT_DIR)/computational_environment.o \
	$(OBJECT_DIR)/constants.o \
	$(OBJECT_DIR)/control_loop_routines.o \
	$(OBJECT_DIR)/coordinate_routines.o \
	$(OBJECT_DIR)/Darcy_equations_routines.o \
	$(OBJECT_DIR)/diffusion_equation_routines.o \
	$(OBJECT_DIR)/distributed_matrix_vector.o \
	$(OBJECT_DIR)/distributed_matrix_vector_IO.o \
	$(OBJECT_DIR)/domain_mappings.o \
	$(OBJECT_DIR)/elasticity_routines.o \
	$(OBJECT_DIR)/electromechanics_routines.o \
	$(OBJECT_DIR)/equations_routines.o \
	$(OBJECT_DIR)/equations_mapping_routines.o \
	$(OBJECT_DIR)/equations_matrices_routines.o \
	$(OBJECT_DIR)/equations_set_constants.o \
	$(OBJECT_DIR)/equations_set_routines.o \
	$(OBJECT_DIR)/field_routines.o \
	$(OBJECT_DIR)/field_IO_routines.o \
	$(OBJECT_DIR)/finite_elasticity_routines.o \
	$(OBJECT_DIR)/fluid_mechanics_routines.o \
	$(OBJECT_DIR)/fluid_mechanics_IO_routines.o \
	$(OBJECT_DIR)/FieldExport.o \
	$(OBJECT_DIR)/Galerkin_projection_routines.o \
	$(OBJECT_DIR)/generated_mesh_routines.o \
	$(OBJECT_DIR)/Helmholtz_equations_routines.o \
	$(OBJECT_DIR)/history_routines.o \
	$(OBJECT_DIR)/input_output.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/Laplace_equations_routines.o \
	$(OBJECT_DIR)/linear_elasticity_routines.o \
	$(OBJECT_DIR)/lists.o \
	$(OBJECT_DIR)/maths.o \
	$(OBJECT_DIR)/matrix_vector.o \
	$(OBJECT_DIR)/mesh_routines.o \
	$(OBJECT_DIR)/Navier_Stokes_equations_routines.o \
	$(OBJECT_DIR)/node_routines.o \
	$(OBJECT_DIR)/opencmiss.o \
	$(OBJECT_DIR)/opencmiss_c.o \
	$(OBJECT_DIR)/Poisson_equations_routines.o \
	$(OBJECT_DIR)/problem_constants.o \
	$(OBJECT_DIR)/problem_routines.o \
	$(OBJECT_DIR)/region_routines.o \
	$(OBJECT_DIR)/Stokes_equations_routines.o \
	$(OBJECT_DIR)/solver_routines.o \
	$(OBJECT_DIR)/solver_mapping_routines.o \
	$(OBJECT_DIR)/solver_matrices_routines.o \
	$(OBJECT_DIR)/strings.o \
	$(OBJECT_DIR)/test_framework_routines.o \
	$(OBJECT_DIR)/timer_c.o \
	$(OBJECT_DIR)/timer_f.o \
	$(OBJECT_DIR)/trees.o \
	$(OBJECT_DIR)/types.o 

ifeq ($(OPERATING_SYSTEM),linux)# Linux
  MACHINE_OBJECTS = $(OBJECT_DIR)/machine_constants_linux.o
else
  ifeq ($(OPERATING_SYSTEM),aix)# AIX
    MACHINE_OBJECTS = $(OBJECT_DIR)/machine_constants_aix.o
  else# windows
    MACHINE_OBJECTS = $(OBJECT_DIR)/machine_constants_windows.o
  endif
endif

OBJECTS += $(MACHINE_OBJECTS)

main: preliminaries \
	$(LIBRARY) \
	$(MOD_INCLUDE) \
	$(HEADER_INCLUDE)

preliminaries: $(OBJECT_DIR) \
	$(INC_DIR) \
	$(LIB_DIR)

$(OBJECT_DIR) :
	mkdir -p $@

$(INC_DIR) :
	mkdir -p $@; 

$(LIB_DIR) :
	mkdir -p $@; 

$(LIBRARY) : $(OBJECTS) 
	$(AR) $(ARFLAGS) $@ $(OBJECTS)

$(MOD_INCLUDE) : $(MOD_SOURCE_INC)
	cp $(MOD_SOURCE_INC) $@ 

$(HEADER_INCLUDE) : $(HEADER_SOURCE_INC)
	cp $(HEADER_SOURCE_INC) $@ 

# Place the list of dependencies for the objects here.
#
# ----------------------------------------------------------------------------

ifeq ($(OPERATING_SYSTEM),aix)

   #Need to disable argument list checking for MPI calls which may have multiple types for the same parameters
   $(OBJECT_DIR)/computational_environment.o : DBGCF_FLGS = -qfullpath -C -qflttrap=inv:en
   $(OBJECT_DIR)/distributed_matrix_vector.o : DBGCF_FLGS = -qfullpath -C -qflttrap=inv:en
   $(OBJECT_DIR)/field_IO_routines.o : DBGCF_FLGS = -qfullpath -C -qflttrap=inv:en

   #Need to disable argument list checking for c interface modules to allow for the c->fortran char->integer string conversion
   $(OBJECT_DIR)/timer_c.o : DBGCF_FLGS = -qfullpath -C -qflttrap=inv:en

endif

$(OBJECT_DIR)/advection_diffusion_equation_routines.o	:	$(SOURCE_DIR)/advection_diffusion_equation_routines.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/basis_routines.o \
	$(OBJECT_DIR)/boundary_condition_routines.o \
	$(OBJECT_DIR)/constants.o \
	$(OBJECT_DIR)/control_loop_routines.o \
	$(OBJECT_DIR)/distributed_matrix_vector.o \
	$(OBJECT_DIR)/domain_mappings.o \
	$(OBJECT_DIR)/equations_routines.o \
	$(OBJECT_DIR)/equations_mapping_routines.o \
	$(OBJECT_DIR)/equations_matrices_routines.o \
	$(OBJECT_DIR)/equations_set_constants.o \
	$(OBJECT_DIR)/field_routines.o \
	$(OBJECT_DIR)/input_output.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/matrix_vector.o \
	$(OBJECT_DIR)/problem_constants.o \
	$(OBJECT_DIR)/strings.o \
	$(OBJECT_DIR)/solver_routines.o \
	$(OBJECT_DIR)/timer_f.o \
	$(OBJECT_DIR)/types.o

$(OBJECT_DIR)/analytic_analysis_routines.o  : $(SOURCE_DIR)/analytic_analysis_routines.f90 \
	$(OBJECT_DIR)/basis_routines.o \
	$(OBJECT_DIR)/cmiss_mpi.o \
	$(OBJECT_DIR)/constants.o \
	$(OBJECT_DIR)/field_routines.o \
	$(OBJECT_DIR)/input_output.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/matrix_vector.o \
	$(OBJECT_DIR)/strings.o \
	$(OBJECT_DIR)/timer_f.o \
	$(OBJECT_DIR)/types.o

$(OBJECT_DIR)/base_routines.o	:	$(SOURCE_DIR)/base_routines.f90 \
	$(OBJECT_DIR)/constants.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(MACHINE_OBJECTS)

$(OBJECT_DIR)/basis_routines.o	:	$(SOURCE_DIR)/basis_routines.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/constants.o \
	$(OBJECT_DIR)/input_output.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/strings.o \
	$(OBJECT_DIR)/types.o

$(OBJECT_DIR)/blas.o	:	$(SOURCE_DIR)/blas.f90 \
	$(OBJECT_DIR)/kinds.o

$(OBJECT_DIR)/bioelectric_routines.o	:	$(SOURCE_DIR)/bioelectric_routines.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/biodomain_equation_routines.o \
	$(OBJECT_DIR)/equations_set_constants.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/problem_constants.o \
	$(OBJECT_DIR)/strings.o \
	$(OBJECT_DIR)/types.o

$(OBJECT_DIR)/biodomain_equation_routines.o	:	$(SOURCE_DIR)/biodomain_equation_routines.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/basis_routines.o \
	$(OBJECT_DIR)/boundary_condition_routines.o \
	$(OBJECT_DIR)/constants.o \
	$(OBJECT_DIR)/control_loop_routines.o \
	$(OBJECT_DIR)/distributed_matrix_vector.o \
	$(OBJECT_DIR)/domain_mappings.o \
	$(OBJECT_DIR)/equations_routines.o \
	$(OBJECT_DIR)/equations_mapping_routines.o \
	$(OBJECT_DIR)/equations_matrices_routines.o \
	$(OBJECT_DIR)/equations_set_constants.o \
	$(OBJECT_DIR)/field_routines.o \
	$(OBJECT_DIR)/input_output.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/matrix_vector.o \
	$(OBJECT_DIR)/problem_constants.o \
	$(OBJECT_DIR)/strings.o \
	$(OBJECT_DIR)/solver_routines.o \
	$(OBJECT_DIR)/timer_f.o \
	$(OBJECT_DIR)/types.o

$(OBJECT_DIR)/boundary_condition_routines.o  : $(SOURCE_DIR)/boundary_condition_routines.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/constants.o \
	$(OBJECT_DIR)/distributed_matrix_vector.o \
	$(OBJECT_DIR)/equations_set_constants.o \
	$(OBJECT_DIR)/field_routines.o \
	$(OBJECT_DIR)/input_output.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/node_routines.o \
	$(OBJECT_DIR)/strings.o \
	$(OBJECT_DIR)/timer_f.o \
	$(OBJECT_DIR)/types.o

$(OBJECT_DIR)/classical_field_routines.o	:	$(SOURCE_DIR)/classical_field_routines.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/diffusion_equation_routines.o \
	$(OBJECT_DIR)/equations_set_constants.o \
	$(OBJECT_DIR)/Galerkin_projection_routines.o \
	$(OBJECT_DIR)/Helmholtz_equations_routines.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/Laplace_equations_routines.o \
	$(OBJECT_DIR)/Poisson_equations_routines.o \
	$(OBJECT_DIR)/problem_constants.o \
	$(OBJECT_DIR)/strings.o \
	$(OBJECT_DIR)/types.o \
	$(MACHINE_OBJECTS)

$(OBJECT_DIR)/cmiss.o	:	$(SOURCE_DIR)/cmiss.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/basis_routines.o \
	$(OBJECT_DIR)/computational_environment.o \
	$(OBJECT_DIR)/constants.o \
	$(OBJECT_DIR)/coordinate_routines.o \
	$(OBJECT_DIR)/generated_mesh_routines.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/problem_routines.o \
	$(OBJECT_DIR)/region_routines.o \
	$(OBJECT_DIR)/strings.o \
	$(OBJECT_DIR)/types.o \
	$(MACHINE_OBJECTS)

$(OBJECT_DIR)/cmiss_cellml.o	:	$(SOURCE_DIR)/cmiss_cellml.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/input_output.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/types.o

$(OBJECT_DIR)/cmiss_cellml_dummy.o	:	$(SOURCE_DIR)/cmiss_cellml_dummy.f90 

$(OBJECT_DIR)/cmiss_mpi.o	:	$(SOURCE_DIR)/cmiss_mpi.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/constants.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/strings.o

$(OBJECT_DIR)/cmiss_parmetis.o	:	$(SOURCE_DIR)/cmiss_parmetis.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/iso_varying_string.o

$(OBJECT_DIR)/cmiss_petsc.o	:	$(SOURCE_DIR)/cmiss_petsc.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/cmiss_petsc_types.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/types.o

$(OBJECT_DIR)/cmiss_petsc_types.o	:	$(SOURCE_DIR)/cmiss_petsc_types.f90 \
	$(OBJECT_DIR)/kinds.o 

$(OBJECT_DIR)/computational_environment.o	:	$(SOURCE_DIR)/computational_environment.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/cmiss_mpi.o \
	$(OBJECT_DIR)/cmiss_petsc.o \
	$(OBJECT_DIR)/constants.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/input_output.o \
	$(OBJECT_DIR)/iso_varying_string.o

$(OBJECT_DIR)/constants.o	:	$(SOURCE_DIR)/constants.f90 \
	$(OBJECT_DIR)/kinds.o

$(OBJECT_DIR)/control_loop_routines.o	:	$(SOURCE_DIR)/control_loop_routines.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/solver_routines.o \
	$(OBJECT_DIR)/strings.o \
	$(OBJECT_DIR)/types.o

$(OBJECT_DIR)/coordinate_routines.o	:	$(SOURCE_DIR)/coordinate_routines.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/constants.o \
	$(OBJECT_DIR)/input_output.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/maths.o \
	$(OBJECT_DIR)/strings.o \
	$(OBJECT_DIR)/types.o

$(OBJECT_DIR)/Darcy_equations_routines.o	:	$(SOURCE_DIR)/Darcy_equations_routines.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/basis_routines.o \
	$(OBJECT_DIR)/boundary_condition_routines.o \
	$(OBJECT_DIR)/constants.o \
	$(OBJECT_DIR)/control_loop_routines.o \
	$(OBJECT_DIR)/distributed_matrix_vector.o \
	$(OBJECT_DIR)/domain_mappings.o \
	$(OBJECT_DIR)/equations_routines.o \
	$(OBJECT_DIR)/equations_mapping_routines.o \
	$(OBJECT_DIR)/equations_matrices_routines.o \
	$(OBJECT_DIR)/equations_set_constants.o \
	$(OBJECT_DIR)/field_routines.o \
	$(OBJECT_DIR)/fluid_mechanics_IO_routines.o \
	$(OBJECT_DIR)/input_output.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/kinds.o	\
	$(OBJECT_DIR)/matrix_vector.o	\
	$(OBJECT_DIR)/problem_constants.o	\
	$(OBJECT_DIR)/strings.o	\
	$(OBJECT_DIR)/solver_routines.o	\
	$(OBJECT_DIR)/timer_f.o	\
	$(OBJECT_DIR)/types.o

$(OBJECT_DIR)/diffusion_equation_routines.o	:	$(SOURCE_DIR)/diffusion_equation_routines.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/basis_routines.o \
	$(OBJECT_DIR)/boundary_condition_routines.o \
	$(OBJECT_DIR)/constants.o \
	$(OBJECT_DIR)/control_loop_routines.o \
	$(OBJECT_DIR)/distributed_matrix_vector.o \
	$(OBJECT_DIR)/domain_mappings.o \
	$(OBJECT_DIR)/equations_routines.o \
	$(OBJECT_DIR)/equations_mapping_routines.o \
	$(OBJECT_DIR)/equations_matrices_routines.o \
	$(OBJECT_DIR)/equations_set_constants.o \
	$(OBJECT_DIR)/field_routines.o \
	$(OBJECT_DIR)/input_output.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/matrix_vector.o \
	$(OBJECT_DIR)/problem_constants.o \
	$(OBJECT_DIR)/strings.o \
	$(OBJECT_DIR)/solver_routines.o \
	$(OBJECT_DIR)/timer_f.o \
	$(OBJECT_DIR)/types.o

$(OBJECT_DIR)/distributed_matrix_vector.o	:	$(SOURCE_DIR)/distributed_matrix_vector.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/cmiss_mpi.o \
	$(OBJECT_DIR)/cmiss_petsc.o \
	$(OBJECT_DIR)/computational_environment.o \
	$(OBJECT_DIR)/input_output.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/matrix_vector.o \
	$(OBJECT_DIR)/strings.o \
	$(OBJECT_DIR)/types.o

$(OBJECT_DIR)/distributed_matrix_vector_IO.o	:	$(SOURCE_DIR)/distributed_matrix_vector_IO.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/strings.o \
	$(OBJECT_DIR)/types.o

$(OBJECT_DIR)/domain_mappings.o	:	$(SOURCE_DIR)/domain_mappings.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/computational_environment.o \
	$(OBJECT_DIR)/input_output.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/lists.o \
	$(OBJECT_DIR)/strings.o \
	$(OBJECT_DIR)/types.o

$(OBJECT_DIR)/elasticity_routines.o	:	$(SOURCE_DIR)/elasticity_routines.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/equations_set_constants.o \
	$(OBJECT_DIR)/finite_elasticity_routines.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/linear_elasticity_routines.o \
	$(OBJECT_DIR)/problem_constants.o \
	$(OBJECT_DIR)/strings.o \
	$(OBJECT_DIR)/types.o

$(OBJECT_DIR)/electromechanics_routines.o	:	$(SOURCE_DIR)/electromechanics_routines.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/types.o

$(OBJECT_DIR)/equations_routines.o	:	$(SOURCE_DIR)/equations_routines.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/equations_mapping_routines.o \
	$(OBJECT_DIR)/equations_matrices_routines.o \
	$(OBJECT_DIR)/equations_set_constants.o \
	$(OBJECT_DIR)/field_routines.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/strings.o \
	$(OBJECT_DIR)/types.o

$(OBJECT_DIR)/equations_mapping_routines.o	:	$(SOURCE_DIR)/equations_mapping_routines.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/domain_mappings.o \
	$(OBJECT_DIR)/equations_set_constants.o \
	$(OBJECT_DIR)/field_routines.o \
	$(OBJECT_DIR)/input_output.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/strings.o \
	$(OBJECT_DIR)/types.o

$(OBJECT_DIR)/equations_matrices_routines.o	:	$(SOURCE_DIR)/equations_matrices_routines.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/distributed_matrix_vector.o \
	$(OBJECT_DIR)/equations_set_constants.o \
	$(OBJECT_DIR)/field_routines.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/lists.o \
	$(OBJECT_DIR)/matrix_vector.o \
	$(OBJECT_DIR)/strings.o \
	$(OBJECT_DIR)/types.o

$(OBJECT_DIR)/equations_set_constants.o	:	$(SOURCE_DIR)/equations_set_constants.f90 \
	$(OBJECT_DIR)/kinds.o

$(OBJECT_DIR)/equations_set_routines.o	:	$(SOURCE_DIR)/equations_set_routines.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/bioelectric_routines.o \
	$(OBJECT_DIR)/classical_field_routines.o \
	$(OBJECT_DIR)/cmiss_mpi.o \
	$(OBJECT_DIR)/computational_environment.o \
	$(OBJECT_DIR)/constants.o \
	$(OBJECT_DIR)/distributed_matrix_vector.o \
	$(OBJECT_DIR)/domain_mappings.o \
	$(OBJECT_DIR)/elasticity_routines.o \
	$(OBJECT_DIR)/equations_routines.o \
	$(OBJECT_DIR)/equations_set_constants.o \
	$(OBJECT_DIR)/equations_matrices_routines.o \
	$(OBJECT_DIR)/field_routines.o \
	$(OBJECT_DIR)/fluid_mechanics_routines.o \
	$(OBJECT_DIR)/input_output.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/lists.o \
	$(OBJECT_DIR)/matrix_vector.o \
	$(OBJECT_DIR)/node_routines.o \
	$(OBJECT_DIR)/strings.o \
	$(OBJECT_DIR)/timer_f.o \
	$(OBJECT_DIR)/types.o

$(OBJECT_DIR)/field_routines.o	:	$(SOURCE_DIR)/field_routines.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/basis_routines.o \
	$(OBJECT_DIR)/computational_environment.o \
	$(OBJECT_DIR)/coordinate_routines.o \
	$(OBJECT_DIR)/distributed_matrix_vector.o \
	$(OBJECT_DIR)/domain_mappings.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/input_output.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/lists.o \
	$(OBJECT_DIR)/matrix_vector.o \
	$(OBJECT_DIR)/mesh_routines.o \
	$(OBJECT_DIR)/node_routines.o \
	$(OBJECT_DIR)/strings.o \
	$(OBJECT_DIR)/types.o

$(OBJECT_DIR)/field_IO_routines.o	:	$(SOURCE_DIR)/field_IO_routines.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/basis_routines.o \
	$(OBJECT_DIR)/cmiss_mpi.o \
	$(OBJECT_DIR)/computational_environment.o \
	$(OBJECT_DIR)/constants.o \
	$(OBJECT_DIR)/coordinate_routines.o \
	$(OBJECT_DIR)/field_routines.o \
	$(SOURCE_DIR)/FieldExportConstants.h \
	$(OBJECT_DIR)/input_output.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/lists.o \
	$(MACHINE_OBJECTS) \
	$(OBJECT_DIR)/mesh_routines.o \
	$(OBJECT_DIR)/node_routines.o \
	$(OBJECT_DIR)/region_routines.o \
	$(OBJECT_DIR)/strings.o \
	$(OBJECT_DIR)/types.o

$(OBJECT_DIR)/finite_elasticity_routines.o	:	$(SOURCE_DIR)/finite_elasticity_routines.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/basis_routines.o \
	$(OBJECT_DIR)/boundary_condition_routines.o \
	$(OBJECT_DIR)/constants.o \
	$(OBJECT_DIR)/control_loop_routines.o \
	$(OBJECT_DIR)/distributed_matrix_vector.o \
	$(OBJECT_DIR)/domain_mappings.o \
	$(OBJECT_DIR)/equations_routines.o \
	$(OBJECT_DIR)/equations_mapping_routines.o \
	$(OBJECT_DIR)/equations_matrices_routines.o \
	$(OBJECT_DIR)/equations_set_constants.o \
	$(OBJECT_DIR)/field_routines.o \
	$(OBJECT_DIR)/input_output.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/maths.o \
	$(OBJECT_DIR)/matrix_vector.o \
	$(OBJECT_DIR)/problem_constants.o \
	$(OBJECT_DIR)/solver_routines.o \
	$(OBJECT_DIR)/strings.o \
	$(OBJECT_DIR)/timer_f.o \
	$(OBJECT_DIR)/types.o

$(OBJECT_DIR)/fluid_mechanics_routines.o	:	$(SOURCE_DIR)/fluid_mechanics_routines.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/Darcy_equations_routines.o \
	$(OBJECT_DIR)/equations_set_constants.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/Navier_Stokes_equations_routines.o \
	$(OBJECT_DIR)/Stokes_equations_routines.o \
	$(OBJECT_DIR)/problem_constants.o \
	$(OBJECT_DIR)/strings.o \
	$(OBJECT_DIR)/types.o

$(OBJECT_DIR)/fluid_mechanics_IO_routines.o	:	$(SOURCE_DIR)/fluid_mechanics_IO_routines.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/field_routines.o \
	$(OBJECT_DIR)/types.o

$(OBJECT_DIR)/FieldExport.o	:	$(SOURCE_DIR)/FieldExport.c \
	$(SOURCE_DIR)/FieldExportConstants.h

$(OBJECT_DIR)/input_output.o	:	$(SOURCE_DIR)/input_output.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/kinds.o	\
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/strings.o

$(OBJECT_DIR)/Galerkin_projection_routines.o	:	$(SOURCE_DIR)/Galerkin_projection_routines.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/basis_routines.o \
	$(OBJECT_DIR)/boundary_condition_routines.o \
	$(OBJECT_DIR)/constants.o \
	$(OBJECT_DIR)/control_loop_routines.o \
	$(OBJECT_DIR)/Darcy_equations_routines.o \
	$(OBJECT_DIR)/distributed_matrix_vector.o \
	$(OBJECT_DIR)/domain_mappings.o \
	$(OBJECT_DIR)/equations_routines.o \
	$(OBJECT_DIR)/equations_mapping_routines.o \
	$(OBJECT_DIR)/equations_matrices_routines.o \
	$(OBJECT_DIR)/equations_set_constants.o \
	$(OBJECT_DIR)/field_routines.o \
	$(OBJECT_DIR)/input_output.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/matrix_vector.o \
	$(OBJECT_DIR)/problem_constants.o \
	$(OBJECT_DIR)/strings.o \
	$(OBJECT_DIR)/solver_routines.o \
	$(OBJECT_DIR)/timer_f.o \
	$(OBJECT_DIR)/types.o

$(OBJECT_DIR)/generated_mesh_routines.o	:	$(SOURCE_DIR)/generated_mesh_routines.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/basis_routines.o \
	$(OBJECT_DIR)/coordinate_routines.o \
	$(OBJECT_DIR)/field_routines.o \
	$(OBJECT_DIR)/input_output.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/mesh_routines.o \
	$(OBJECT_DIR)/node_routines.o \
	$(OBJECT_DIR)/strings.o \
	$(OBJECT_DIR)/types.o

$(OBJECT_DIR)/Helmholtz_equations_routines.o	:	$(SOURCE_DIR)/Helmholtz_equations_routines.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/basis_routines.o \
	$(OBJECT_DIR)/boundary_condition_routines.o \
	$(OBJECT_DIR)/constants.o \
	$(OBJECT_DIR)/control_loop_routines.o \
	$(OBJECT_DIR)/distributed_matrix_vector.o \
	$(OBJECT_DIR)/domain_mappings.o \
	$(OBJECT_DIR)/equations_routines.o \
	$(OBJECT_DIR)/equations_mapping_routines.o \
	$(OBJECT_DIR)/equations_matrices_routines.o \
	$(OBJECT_DIR)/equations_set_constants.o \
	$(OBJECT_DIR)/field_routines.o \
	$(OBJECT_DIR)/input_output.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/matrix_vector.o \
	$(OBJECT_DIR)/problem_constants.o \
	$(OBJECT_DIR)/strings.o \
	$(OBJECT_DIR)/solver_routines.o \
	$(OBJECT_DIR)/timer_f.o \
	$(OBJECT_DIR)/types.o

$(OBJECT_DIR)/history_routines.o	:	$(SOURCE_DIR)/history_routines.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/problem_constants.o \
	$(OBJECT_DIR)/strings.o \
	$(OBJECT_DIR)/types.o

$(OBJECT_DIR)/iso_varying_string.o	:	$(SOURCE_DIR)/iso_varying_string.f90 

$(OBJECT_DIR)/kinds.o	:	$(SOURCE_DIR)/kinds.f90

$(OBJECT_DIR)/Laplace_equations_routines.o	:	$(SOURCE_DIR)/Laplace_equations_routines.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/basis_routines.o \
	$(OBJECT_DIR)/boundary_condition_routines.o \
	$(OBJECT_DIR)/constants.o \
	$(OBJECT_DIR)/control_loop_routines.o \
	$(OBJECT_DIR)/distributed_matrix_vector.o \
	$(OBJECT_DIR)/domain_mappings.o \
	$(OBJECT_DIR)/equations_routines.o \
	$(OBJECT_DIR)/equations_mapping_routines.o \
	$(OBJECT_DIR)/equations_matrices_routines.o \
	$(OBJECT_DIR)/equations_set_constants.o \
	$(OBJECT_DIR)/field_routines.o \
	$(OBJECT_DIR)/input_output.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/matrix_vector.o \
	$(OBJECT_DIR)/problem_constants.o \
	$(OBJECT_DIR)/strings.o \
	$(OBJECT_DIR)/solver_routines.o \
	$(OBJECT_DIR)/timer_f.o \
	$(OBJECT_DIR)/types.o

$(OBJECT_DIR)/linear_elasticity_routines.o	:	$(SOURCE_DIR)/linear_elasticity_routines.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/basis_routines.o \
	$(OBJECT_DIR)/boundary_condition_routines.o \
	$(OBJECT_DIR)/constants.o \
	$(OBJECT_DIR)/control_loop_routines.o \
	$(OBJECT_DIR)/distributed_matrix_vector.o \
	$(OBJECT_DIR)/domain_mappings.o \
	$(OBJECT_DIR)/equations_routines.o \
	$(OBJECT_DIR)/equations_mapping_routines.o \
	$(OBJECT_DIR)/equations_matrices_routines.o \
	$(OBJECT_DIR)/equations_set_constants.o \
	$(OBJECT_DIR)/field_routines.o \
	$(OBJECT_DIR)/input_output.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/matrix_vector.o \
	$(OBJECT_DIR)/problem_constants.o \
	$(OBJECT_DIR)/solver_routines.o \
	$(OBJECT_DIR)/strings.o \
	$(OBJECT_DIR)/timer_f.o \
	$(OBJECT_DIR)/types.o

$(OBJECT_DIR)/lists.o	:	$(SOURCE_DIR)/lists.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/constants.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/kinds.o	\
	$(OBJECT_DIR)/strings.o

$(OBJECT_DIR)/machine_constants_aix.o	:	$(SOURCE_DIR)/machine_constants_aix.f90 \
	$(OBJECT_DIR)/constants.o \
	$(OBJECT_DIR)/kinds.o

$(OBJECT_DIR)/machine_constants_linux.o	:	$(SOURCE_DIR)/machine_constants_linux.f90 \
	$(OBJECT_DIR)/constants.o \
	$(OBJECT_DIR)/kinds.o

$(OBJECT_DIR)/machine_constants_windows.o	:	$(SOURCE_DIR)/machine_constants_windows.f90 \
	$(OBJECT_DIR)/constants.o \
	$(OBJECT_DIR)/kinds.o

$(OBJECT_DIR)/maths.o	:	$(SOURCE_DIR)/maths.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/constants.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/iso_varying_string.o

$(OBJECT_DIR)/matrix_vector.o	:	$(SOURCE_DIR)/matrix_vector.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/constants.o \
	$(OBJECT_DIR)/input_output.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/lists.o \
	$(OBJECT_DIR)/strings.o \
	$(OBJECT_DIR)/types.o

$(OBJECT_DIR)/mesh_routines.o	:	$(SOURCE_DIR)/mesh_routines.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/basis_routines.o \
	$(OBJECT_DIR)/cmiss_mpi.o \
	$(OBJECT_DIR)/cmiss_parmetis.o \
	$(OBJECT_DIR)/computational_environment.o \
	$(OBJECT_DIR)/coordinate_routines.o \
	$(OBJECT_DIR)/domain_mappings.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/input_output.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/lists.o \
	$(OBJECT_DIR)/node_routines.o \
	$(OBJECT_DIR)/strings.o \
	$(OBJECT_DIR)/trees.o \
	$(OBJECT_DIR)/types.o

$(OBJECT_DIR)/Navier_Stokes_equations_routines.o	:	$(SOURCE_DIR)/Navier_Stokes_equations_routines.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/basis_routines.o \
	$(OBJECT_DIR)/boundary_condition_routines.o \
	$(OBJECT_DIR)/constants.o \
	$(OBJECT_DIR)/control_loop_routines.o \
	$(OBJECT_DIR)/distributed_matrix_vector.o \
	$(OBJECT_DIR)/domain_mappings.o \
	$(OBJECT_DIR)/equations_routines.o \
	$(OBJECT_DIR)/equations_mapping_routines.o \
	$(OBJECT_DIR)/equations_matrices_routines.o \
	$(OBJECT_DIR)/equations_set_constants.o \
	$(OBJECT_DIR)/field_routines.o \
	$(OBJECT_DIR)/input_output.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/matrix_vector.o \
	$(OBJECT_DIR)/problem_constants.o \
	$(OBJECT_DIR)/strings.o \
	$(OBJECT_DIR)/solver_routines.o \
	$(OBJECT_DIR)/timer_f.o \
	$(OBJECT_DIR)/types.o

$(OBJECT_DIR)/node_routines.o	:	$(SOURCE_DIR)/node_routines.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/input_output.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/strings.o \
	$(OBJECT_DIR)/trees.o \
	$(OBJECT_DIR)/types.o

$(OBJECT_DIR)/opencmiss.o	:	$(SOURCE_DIR)/opencmiss.f90 \
	$(OBJECT_DIR)/analytic_analysis_routines.o \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/basis_routines.o \
	$(OBJECT_DIR)/boundary_condition_routines.o \
	$(OBJECT_DIR)/cmiss.o \
	$(OBJECT_DIR)/cmiss_mpi.o \
	$(OBJECT_DIR)/computational_environment.o \
	$(OBJECT_DIR)/constants.o \
	$(OBJECT_DIR)/control_loop_routines.o \
	$(OBJECT_DIR)/coordinate_routines.o \
	$(OBJECT_DIR)/distributed_matrix_vector.o \
	$(OBJECT_DIR)/domain_mappings.o \
	$(OBJECT_DIR)/equations_routines.o \
	$(OBJECT_DIR)/equations_set_constants.o \
	$(OBJECT_DIR)/equations_set_routines.o \
	$(OBJECT_DIR)/field_routines.o \
	$(OBJECT_DIR)/field_IO_routines.o \
	$(OBJECT_DIR)/input_output.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/lists.o \
	$(OBJECT_DIR)/mesh_routines.o \
	$(OBJECT_DIR)/node_routines.o \
	$(OBJECT_DIR)/problem_constants.o \
	$(OBJECT_DIR)/problem_routines.o \
	$(OBJECT_DIR)/region_routines.o \
	$(OBJECT_DIR)/solver_routines.o \
	$(OBJECT_DIR)/test_framework_routines.o \
	$(OBJECT_DIR)/timer_f.o \
	$(OBJECT_DIR)/types.o 

$(OBJECT_DIR)/opencmiss_c.o	:	$(SOURCE_DIR)/opencmiss_c.f90 \
	$(OBJECT_DIR)/opencmiss.o 

$(OBJECT_DIR)/Poisson_equations_routines.o	:	$(SOURCE_DIR)/Poisson_equations_routines.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/basis_routines.o \
	$(OBJECT_DIR)/boundary_condition_routines.o \
	$(OBJECT_DIR)/constants.o \
	$(OBJECT_DIR)/control_loop_routines.o \
	$(OBJECT_DIR)/distributed_matrix_vector.o \
	$(OBJECT_DIR)/domain_mappings.o \
	$(OBJECT_DIR)/equations_routines.o \
	$(OBJECT_DIR)/equations_mapping_routines.o \
	$(OBJECT_DIR)/equations_matrices_routines.o \
	$(OBJECT_DIR)/equations_set_constants.o \
	$(OBJECT_DIR)/field_routines.o \
	$(OBJECT_DIR)/input_output.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/matrix_vector.o \
	$(OBJECT_DIR)/problem_constants.o \
	$(OBJECT_DIR)/strings.o \
	$(OBJECT_DIR)/solver_routines.o \
	$(OBJECT_DIR)/timer_f.o \
	$(OBJECT_DIR)/types.o

$(OBJECT_DIR)/problem_constants.o	:	$(SOURCE_DIR)/problem_constants.f90 \
	$(OBJECT_DIR)/kinds.o

$(OBJECT_DIR)/problem_routines.o	:	$(SOURCE_DIR)/problem_routines.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/classical_field_routines.o \
	$(OBJECT_DIR)/control_loop_routines.o \
	$(OBJECT_DIR)/distributed_matrix_vector.o \
	$(OBJECT_DIR)/elasticity_routines.o \
	$(OBJECT_DIR)/equations_set_constants.o \
	$(OBJECT_DIR)/equations_set_routines.o \
	$(OBJECT_DIR)/field_routines.o \
	$(OBJECT_DIR)/fluid_mechanics_routines.o \
	$(OBJECT_DIR)/input_output.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/problem_constants.o \
	$(OBJECT_DIR)/solver_routines.o \
	$(OBJECT_DIR)/solver_matrices_routines.o \
	$(OBJECT_DIR)/strings.o \
	$(OBJECT_DIR)/timer_f.o \
	$(OBJECT_DIR)/types.o

$(OBJECT_DIR)/region_routines.o	:	$(SOURCE_DIR)/region_routines.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/coordinate_routines.o \
	$(OBJECT_DIR)/equations_set_routines.o \
	$(OBJECT_DIR)/field_routines.o \
	$(OBJECT_DIR)/input_output.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/mesh_routines.o \
	$(OBJECT_DIR)/node_routines.o \
	$(OBJECT_DIR)/strings.o \
	$(OBJECT_DIR)/types.o

$(OBJECT_DIR)/solver_routines.o	:	$(SOURCE_DIR)/solver_routines.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/cmiss_petsc.o \
	$(OBJECT_DIR)/computational_environment.o \
	$(OBJECT_DIR)/constants.o \
	$(OBJECT_DIR)/distributed_matrix_vector.o \
	$(OBJECT_DIR)/equations_set_constants.o \
	$(OBJECT_DIR)/field_routines.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/input_output.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/solver_mapping_routines.o \
	$(OBJECT_DIR)/solver_matrices_routines.o \
	$(OBJECT_DIR)/strings.o \
	$(OBJECT_DIR)/timer_f.o \
	$(OBJECT_DIR)/types.o

$(OBJECT_DIR)/solver_mapping_routines.o	:	$(SOURCE_DIR)/solver_mapping_routines.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/boundary_condition_routines.o \
	$(OBJECT_DIR)/computational_environment.o \
	$(OBJECT_DIR)/distributed_matrix_vector.o \
	$(OBJECT_DIR)/domain_mappings.o \
	$(OBJECT_DIR)/equations_set_constants.o \
	$(OBJECT_DIR)/field_routines.o \
	$(OBJECT_DIR)/input_output.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/matrix_vector.o \
	$(OBJECT_DIR)/problem_constants.o \
	$(OBJECT_DIR)/strings.o \
	$(OBJECT_DIR)/types.o

$(OBJECT_DIR)/solver_matrices_routines.o	:	$(SOURCE_DIR)/solver_matrices_routines.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/distributed_matrix_vector.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/matrix_vector.o \
	$(OBJECT_DIR)/problem_constants.o \
	$(OBJECT_DIR)/strings.o \
	$(OBJECT_DIR)/types.o

$(OBJECT_DIR)/Stokes_equations_routines.o	:	$(SOURCE_DIR)/Stokes_equations_routines.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/basis_routines.o \
	$(OBJECT_DIR)/boundary_condition_routines.o \
	$(OBJECT_DIR)/constants.o \
	$(OBJECT_DIR)/control_loop_routines.o \
	$(OBJECT_DIR)/distributed_matrix_vector.o \
	$(OBJECT_DIR)/domain_mappings.o \
	$(OBJECT_DIR)/equations_routines.o \
	$(OBJECT_DIR)/equations_mapping_routines.o \
	$(OBJECT_DIR)/equations_matrices_routines.o \
	$(OBJECT_DIR)/equations_set_constants.o \
	$(OBJECT_DIR)/field_routines.o \
	$(OBJECT_DIR)/fluid_mechanics_IO_routines.o \
	$(OBJECT_DIR)/input_output.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/matrix_vector.o \
	$(OBJECT_DIR)/problem_constants.o \
	$(OBJECT_DIR)/strings.o \
	$(OBJECT_DIR)/solver_routines.o \
	$(OBJECT_DIR)/timer_f.o \
	$(OBJECT_DIR)/types.o

$(OBJECT_DIR)/strings.o	:	$(SOURCE_DIR)/strings.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/constants.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/iso_varying_string.o

$(OBJECT_DIR)/test_framework_routines.o	:	$(SOURCE_DIR)/test_framework_routines.f90 \
	$(OBJECT_DIR)/constants.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/matrix_vector.o \
	$(OBJECT_DIR)/strings.o

$(OBJECT_DIR)/timer_c.o		:	$(SOURCE_DIR)/timer_c.c 

$(OBJECT_DIR)/timer_f.o	:	$(SOURCE_DIR)/timer_f.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/constants.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/iso_varying_string.o

$(OBJECT_DIR)/trees.o	:	$(SOURCE_DIR)/trees.f90 \
	$(OBJECT_DIR)/base_routines.o \
	$(OBJECT_DIR)/input_output.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/strings.o

$(OBJECT_DIR)/types.o	:	$(SOURCE_DIR)/types.f90 \
	$(OBJECT_DIR)/cmiss_petsc_types.o \
	$(OBJECT_DIR)/constants.o \
	$(OBJECT_DIR)/kinds.o \
	$(OBJECT_DIR)/iso_varying_string.o \
	$(OBJECT_DIR)/trees.o

# ----------------------------------------------------------------------------
#
# clean and clobber for removing objects and executable.

clean:
	@echo "Cleaning house ..."
	rm -rf $(OBJECT_DIR) $(LIBRARY) $(MOD_INCLUDE) $(HEADER_INCLUDE)

allclean:
	@echo "Cleaning house ..."
	rm -rf object/* lib/*

clobber: clean
	rm -f $(LIBRARY)

externallibs:
	$(MAKE) --no-print-directory -f $(EXTERNAL_CM_ROOT)/packages/Makefile DEBUG=$(DEBUG) ABI=$(ABI) 

debug opt debug64 opt64:
	$(MAKE) --no-print-directory DEBUG=$(DEBUG) ABI=$(ABI)

debug debug64: DEBUG=true
opt opt64: DEBUG=false
ifneq (,$(filter $(MACHNAME),ia64 x86_64))# ia64 or x86_64
   debug opt: ABI=64
else
   debug opt: ABI=32
endif
debug64 opt64: ABI=64

all: debug opt
all64: debug64 opt64

#-----------------------------------------------------------------------------

help:
	@echo "           Compile a library version of OpenCMISS"
	@echo "           ======================================"
	@echo
	@echo "Examples of usage:   "
	@echo
	@echo "	gmake"
	@echo "	gmake OPT= ABI=32"
	@echo "	gmake PROF="
	@echo "	gmake debug64"
	@echo
	@echo "Options: (The former is the default unless specified.)"
	@echo
	@echo "	(DEBUG=|OPT=)"
	@echo "	MPI=(mpich2|intel|openmpi|mvapich2|cray)"
	@echo "	PROF=(true|)"
	@echo "	MPIPROF=(true|)"
	@echo "	ABI=(32|64)"
	@echo "	COMPILER=(intel|gnu|ibm|cray)"
	@echo "	USECELLML=(false|true)"
	@echo 
	@echo "Available targets:                            "
	@echo
	@echo "	clean"
	@echo "		Remove generated files associated with a single"
	@echo "		version."
	@echo
	@echo "	clobber"
	@echo "		Remove all files associated with a single version."
	@echo
	@echo "	help"
	@echo "		Display this message."
	@echo
	@echo "	debug opt debug64 opt64"
	@echo "		Compile the specified version with automatic setting"
	@echo "		of DEBUG, ABI, and MP."
	@echo
	@echo "	all"
	@echo "		Compile all versions."
	@echo
	@echo "	all64"
	@echo "		Compile all 64-bit versions."
	@echo
	@echo
	@echo "	externallibs"
	@echo "		Compile the external libraries."
	@echo
	@echo "	test"
	@echo "		Run the executables for test. Linux 64 bit and AnalyticLaplaceExample only for now."
	@echo
