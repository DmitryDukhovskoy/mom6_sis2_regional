#!/bin/bash 
# 
# Code that can be modified for any output files
#
# This script to process ocean/ sis output only 
# for specific experiment
#
# Rename output files dumped from NEP MOM6-SIS2
# from gaea to PPAN archive
#
# Untar output file, separate ocean and ice files, groupd by months
# to zip: run postprcs_zip.sh  
#
# Assumed file naming is YYYYMMDD.oceanm_YYYY_DDD.nc
# File structure should follow a pattern 
#
# Usage:
set -u

export REG=NEP
export EXPT=NEP_physics_202404_nudging-15d
export PLTF="gfdl.ncrc5-intel22-repro"
export DARCH=/archive/Dmitry.Dukhovskoy/fre/NEP/2024/${EXPT}/${PLTF}
export oprfx=oceanm
export iprfx=icem
export DAWK=/home/Dmitry.Dukhovskoy/scripts/awk_utils

if [[ $# < 1 ]]; then
  echo "ERROR: specify year to start/end"
  echo "usage: [sbatch] postprcs_arch.sh YR1 [YR2]"
  exit 1
fi

function get_month_mday {
  local FL=$1
  local bname=$( echo ${FL} | cut -d"." -f 1 )
  local year=$( echo ${bname} | cut -d "_" -f 2 )
  local jday=$( echo ${bname} | cut -d "_" -f 3 )
# Assign values to global variables:
  YY=$year
  MM=`echo "YRDAY2MDAY" | awk -f ${DAWK}/dates.awk y01=$YY d01=$jday | awk '{printf("%02d",$2)}'`
  mday=`echo "YRDAY2MDAY" | awk -f ${DAWK}/dates.awk y01=$YY d01=$jday | awk '{printf("%02d",$3)}'`
}
 
YR1=$1
if [[ $# == 1 ]]; then
  YR2=$YR1
else
  YR2=$2
fi

echo "Processing outputs for $YR1-$YR2"

/bin/cp $DAWK/dates.awk .

#expt_name=NEPphys_frcst_dailyOB-expt${expt_nmb}
HSTDIR=$DARCH/history
for (( yr=$YR1; yr<=$YR2; yr+=1 )); do
  cd $DARCH/history

  for MM in 1 4 7 10; do
    mstart=$(echo $MM | awk '{printf("%02d",$1)}')
#    HSTDIR=$DARCH/$dens/$PLTF/history
    cd $DARCH/history
    echo "Processing run $yr/$mstart" 
    pwd

# Check if tar file  exists:
    ntar=$( ls -l ${yr}${mstart}??.nc.tar | wc -l )
    dir_targ=$DARCH/history/${yr}-${mstart}

#    if ! [ -s $farch_tar ]; then
#      nftar=0
    if [[ $ntar -eq 0 ]]; then
      echo "tar file does not exist, check untarred files ..."
#      continue
# check if files have been untarred:
      nftar=$( ls ${yr}${mstart}??.{${oprfx},${iprfx}}_*.nc | wc -l )     
      echo "Found $nftar untarred files"
# Check renamed files but not yet grouped:
      nrenm=$( ls {${oprfx},${iprfx}}_*.nc | wc -l )
      echo "Found ${nrenm} renamed files for processing"
      if [[ $nftar -gt 0 ]]; then
        date_start=$( ls -1 ${yr}${mstart}??.{${oprfx},${iprfx}}_*.nc | head -1 | cut -d"." -f 1 )
        farch_tar=${date_start}.nc.tar
      elif [[ $nrenm -gt 0 ]]; then
# Guess start date:
        date_start=${yr}${mstart}01
        farch_tar=${date_start}.nc.tar 
      else
        date_start=99999999
        echo "No files found for processing, skipping ..."
        continue
      fi
    else
# Start date of the run from tar name:
      date_start=$( ls ${yr}${mstart}??.nc.tar | cut -d"." -f1 )
      farch_tar=${date_start}.nc.tar

      /bin/mkdir -pv ${dir_targ}

# Check # of files in the tar: 
      nftar=$( tar tvf $farch_tar |  grep '\.nc' | wc -l )
      tar -xvf $farch_tar -C ${dir_targ}
      wait
    fi
    
# Get rid of the leading time stamp in the file names:
    cd ${dir_targ}
    for FL in $( ls ${date_start}.*.nc ); do
      fldname=$( echo ${FL} | cut -d"." -f 2)
      echo "$FL ---> ${fldname}.nc"
      /bin/mv $FL ${fldname}.nc
    done

    nfls=$( ls -l *.nc | wc -l )
#    nfls=$( ls -l {${oprfx},${iprfx}}*.nc | wc -l )
#
#    if [[ $nfls -eq 0 ]]; then
#      echo "No output files found, $nfls, skipping ${dens} ..."
#      pwd
#      continue
#    fi
#
    if [[ $nfls -ne $nftar ]]; then
      echo "Some files were not untarred, N untarred=${nfls}, N in the tar=${nftar} ?"
##     exit 1
    else
      echo "Removing $farch_tar"
      /bin/rm -f $DARCH/history/$farch_tar
    fi

  done
done

echo "All done"

exit 0
