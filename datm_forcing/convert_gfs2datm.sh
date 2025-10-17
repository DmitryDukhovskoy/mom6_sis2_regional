#!/bin/bash -x
# 
# Prepare datm fields 
# After copying atm. data from HPSS
# 
set -euo pipefail

# Set the library path so CDO can find libeccodes.so
export LD_LIBRARY_PATH=/apps/spack-2024-12/linux-rocky9-x86_64/gcc-11.4.1/eccodes-2.34.0-lciziibkbggu6dlkcyi3c7aqqhgywxdj/lib64:$LD_LIBRARY_PATH


module load netcdf-fortran/4.6.1
module load intel-oneapi-compilers/2025.2.1
module load cdo/2.4.2
module load wgrib2/3.1.3_ncep
which wgrib2

usage() {
  echo "Usage: $0 --sdate YYYYMMDD [--edate YYYYMMDD]"
  echo "  --sdate    start date e.g. 20250103,  HR=0"
  echo "  --edate    end date, e.g. 20250118, defualt = sdate HR=last available on this date"
  exit 1
}

sdate=""
edate=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --sdate)
      sdate=$2
      shift 2
      ;;
    --edate)
      edate=$2
      shift 2
      ;;
    --help)
      usage
      ;;
    *)
    echo "ERR: Unrecognized option $1"
    usage
    ;;
  esac
done

if [[ $sdate -eq 0 ]]; then
  echo "ERR: missing sdate"
  usage
fi

[[ $edate -eq 0 ]] && edate=$sdate

if [[ -z "$sdate" ]]; then
  echo "ERR: missing --sdate"
  usage
fi

[[ -z "$edate" ]] && edate="$sdate"

echo "sdate: $sdate"
echo "edate: $edate"

# Check date formats:  
if [[ ! "$sdate" =~ ^[0-9]{8}$ ]]; then
  echo "ERR: sdate must be in format YYYYMMDD, input: $sdate"
  usage
fi

if [[ ! "$edate" =~ ^[0-9]{8}$ ]]; then
  echo "ERR: sdate must be in format YYYYMMDD, input: $edate"
  usage
fi

DSCR=/scratch4/NCEPDEV/stmp/Dmitry.Dukhovskoy/scripts_datm
HDIR=/scratch4/NCEPDEV/stmp/${USER}/datm_forcing/DATM
SDIR=${HDIR}/Reanal
TDIR=${HDIR}/GFS2DATM
WDIR=${HDIR}/Work
grb2=$( which wgrib2) 
#/apps/wgrib2/3.1.3/gnu_11.4.1/ncep/bin/wgrib2

if [[ -z "$grb2" ]]; then
  echo "ERR: wgrib2 not found in PATH"
  exit 1
fi

HEXE=conv_gfs2datm.x  # executable compiled for this machine, see comp_fort.sh

mkdir -pv $WDIR
mkdir -pv $TDIR

cd $WDIR
pwd

ymd="$sdate"
while [[ "$ymd" -le "$edate" ]]; do
  for hh in 00 06 12 18; do 
    ymdh=${ymd}${hh}
    echo "Processing date: $ymdh"

    rm -rf gfs_input*.nc

    ${grb2} ${SDIR}/gfs.${ymd}.t${hh}z.sfcanl.grib2 -netcdf gfs_input1.nc
    ${grb2} ${SDIR}/gfs.${ymd}.t${hh}z.puvflx.grib2 -netcdf gfs_input2.nc
    cp ${SDIR}/gfs.${ymd}.t${hh}z.atmf000.delz1.nc gfs_input3.nc

    cdo merge gfs_input1.nc gfs_input2.nc gfs_input3.nc gfs_input.nc
    status=$?
    if [[ $status -ne 0 ]]; then
      echo "ERR: cdo failed ${status}"    
      exit 1
    fi

    echo " Converting to DATM: ${ymdh}"
    pwd
    ./${HEXE}
    
    status=$?
    if [[ $status -ne 0 ]]; then
      echo "ERR: ${HEXE} failed ${status}"    
      exit 1
    fi


    ncdump gfs_output.nc | sed -e "5s#^.time = 1 ;#time = UNLIMITED ; // (1 currently)#" | ncgen -o gfs_output2.nc
#    mv -f gfs_output2.nc gfs_output.nc
    /bin/mv gfs_output2.nc ${TDIR}/gfs.${ymdh}.nc

    rm -f gfs_input.* gfs_output*
  done

  # Advance to next day
  ymd=$(date -d "${ymd} +1 day" +%Y%m%d)
done


echo "All Done"

exit 0

