#! /bin/csh -x
#-- hyun-chul.lee@noaa.gov

#module load gnu/13.2.0 intel/2023.2.0 netcdf/4.7.0 wgrib2/3.1.2_ncep cdo/2.3.0
#module list
module load netcdf-fortran/4.6.1
module load intel-oneapi-compilers/2025.2.1
module load cdo/2.4.2
module load wgrib2/3.1.3_ncep
which wgrib2

set echo
#set hperm = /scratch4/NCEPDEV/marine/Zulema.Garraffo/FV3_RT/forcing
#set hdir = /scratch4/NCEPDEV/marine/Zulema.Garraffo/FV3_RT/forcing/DATM

set DSCR = /scratch4/NCEPDEV/stmp/Dmitry.Dukhovskoy/scripts_datm 
set hdir = /scratch4/NCEPDEV/stmp/${USER}/datm_forcing/DATM
set sdir = ${hdir}/Reanal
set tdir = ${hdir}/GFS2DATM
set wdir = ${hdir}/Work
set grb2 = /apps/wgrib2/3.1.3/gnu_11.4.1/ncep/bin/wgrib2

#set tymd = 20210715

#set symd = $1
#set eymd = $2
set symd = 20250103
set eymd = 20250118

echo $symd $eymd

if (! -d $wdir) mkdir -pv $wdir
if (! -d $tdir) mkdir -pv $tdir

cd $wdir
pwd

set HEXE = conv_gfs2datm.x
/bin/cp -f ${DSCR}/${HEXE} .

set ymd = $symd
while ($ymd <= $eymd)
  foreach hh (00 06 12 18)
    set ymdh = ${ymd}${hh}
    echo ${ymdh}
    rm -f gfs_input*.nc
    ${grb2} ${sdir}/gfs.${ymd}.t${hh}z.sfcanl.grib2 -netcdf gfs_input1.nc
    ${grb2} ${sdir}/gfs.${ymd}.t${hh}z.puvflx.grib2 -netcdf gfs_input2.nc
    cp ${sdir}/gfs.${ymd}.t${hh}z.atmf000.delz1.nc gfs_input3.nc
    cdo merge gfs_input1.nc gfs_input2.nc gfs_input3.nc gfs_input.nc

    echo ${ymdh}
    pwd
    ./${HEXE}

    ncdump gfs_output.nc | sed -e "5s#^.time = 1 ;#time = UNLIMITED ; // (1 currently)#" | ncgen -o gfs_output2.nc
#    mv -f gfs_output2.nc gfs_output.nc
    /bin/mv gfs_output2.nc ${tdir}/gfs.${ymdh}.nc
 
    rm -f gfs_input.* gfs_output*
  end
  set ymd = `date -d "${ymd} 1 day" +%Y%m%d`
end

#
