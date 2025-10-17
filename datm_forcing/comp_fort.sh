#!/bin/bash -x
# 
# compile fortran 77 code conv_gfs2datm_long_beta5_hCk.f on ursa
set -u

module load netcdf-fortran/4.6.1
module load intel-oneapi-compilers/2025.2.1

DINC=/apps/spack-2024-12/linux-rocky9-x86_64/oneapi-2025.2.1/netcdf-fortran-4.6.1-gghxd3coafrzqmnuihlufdzntsl7udti/include
LIBSF=/apps/spack-2024-12/linux-rocky9-x86_64/oneapi-2025.2.1/netcdf-fortran-4.6.1-gghxd3coafrzqmnuihlufdzntsl7udti/lib
LIBSC=/apps/spack-2024-12/linux-rocky9-x86_64/oneapi-2025.2.1/netcdf-c-4.9.2-mycgojocl75g5xk6op3p4wtntdijpax6/lib
LIBHDF5=/apps/spack-2024-12/linux-rocky9-x86_64/oneapi-2025.2.1/hdf5-1.14.3-gjvk7sfo2nstop6ayjfekexzaglf5yme/lib

HEXE=conv_gfs2datm.x

ifx -fixed -extend-source 132 conv_gfs2datm_long_beta5_hCk.f -o ${HEXE} -I${DINC} -L${LIBSF} -L${LIBSC} -L${LIBHDF5} -mcmodel=medium -lnetcdff -lnetcdf -lhdf5

echo "All done"

exit 0

