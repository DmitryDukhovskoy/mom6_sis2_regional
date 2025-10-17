OLD wont work on ursa
see my script
comp_fort.sh
#! /bin/csh

#module load impi/2018.4
#module load intel/2018.4

#module load netcdf/4.6.1
#module load hdf5/1.10.6

module purge
module load gnu/13.2.0 intel/2023.2.0 netcdf/4.7.0 hdf5/1.10.6 wgrib2/3.1.2_ncep

#ln -sf /apps/netcdf/4.6.1/intel/16.1.150/include/netcdf.inc . 
ln -sf /apps/netcdf/4.7.0/intel/18.0.5.274/include/netcdf.inc . 

set name = conv_gfs2datm_long_beta5_hCk

#ifort -132 ${name}.f -o ${name} -mcmodel=medium -L/apps/contrib/NCEPLIBS/orion/external/netcdf-4.5.0/lib -lnetcdff -lnetcdf
#ifort -132 ${name}.f -o ${name} 
#ifort -132 ${name}.f -o ${name} -mcmodel=medium -L/apps/netcdf/4.6.1/intel/16.1.150/lib/ -lnetcdff -lnetcdf
ifort -132 ${name}.f -o ${name} -mcmodel=medium -L/apps/netcdf/4.7.0/intel/18.0.5.274/lib/ -lnetcdff -lnetcdf
