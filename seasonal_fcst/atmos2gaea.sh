#!/bin/bash 
#
# Send tar.gz atmos fields to gaea
# if tar bundles do not exist - the script will call
# atmos_tar.sh to create tar.gz files
# 
# Transfer tar atmos fields for N ensembles prepared from SPEAR
# for seasonal ensemble forecasts
#
# Atmos subsets prepared in python:
# /home/Dmitry.Dukhovskoy/python/setup_seasonal_NEP/write_spear_atmos.py
# 
# Usage: atmos2gaea.sh YR1 [YR2] 
# or sbatch atmos2gaea.sh YR1 [YR2]
set -u

if module list | grep "gcp"; then
  echo "gcp loaded"
else
  module load gcp/2.3
fi

export DATM=/home/Dmitry.Dukhovskoy/work1/NEP_input/fcst_forcing/atmos
export DGAEA=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/NEP_data/forecast_input_data/atmos
export SRC=/home/Dmitry.Dukhovskoy/scripts/seasonal_fcst

if [[ $# -lt 1 ]]; then
  echo "usage: ./atmos2gaea.sh YR1 [YR2 ]"
  echo " Start/end years are missing"
  exit 1
fi

YR1=$1
if [[ $# -eq 1 ]]; then
  YR2=$YR1
else
  YR2=$2
fi 

cd $DATM
pwd
ls -l

for (( yr=$YR1; yr<=$YR2; yr+=1 )); do
  for (( mo=1; mo<=12; mo+=3 )); do
    mo0=`echo ${mo} | awk '{printf("%02d", $1)}'`
    ftar=spear_atmos_${yr}${mo0}.tar.gz
    if ! [ -s $ftar ]; then
      echo "${ftar} does not exist, checking if atmos fields exist for tarring"
      $SRC/atmos_tar.sh ${yr}  
      status=$?
      if [[ $status -ne 0 ]]; then
        echo "ERROR in SPEAR atmos tar/gzip step, exiting ..."
        exit 5
      fi
    fi
  
# Tar may still not exist, if not all ensembles were create, for instance:
    if ! [ -s $ftar ]; then
      echo "$ftar still not found, check tar/gzip step, not all ensembles ?? Skipping ..."
      continue
    fi
 
    echo "Sending $ftar to gaea:$DGAEA ..." 
    chck_file=spear_atmos_${yr}${mo0}_sent
    if [ -s $chck_file ]; then
      echo "$ftar was already sent"
      continue
    fi

    /bin/rm -f $chck_file
    gcp $ftar gaea:$DGAEA/
    status=$?
    if [[ $status == 0 ]]; then
      `echo $ftar > $chck_file`
    fi

  done
done

exit 0 

