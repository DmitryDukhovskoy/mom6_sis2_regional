#!/bin/bash 
#
# Careful when modifying this file, it is called from atmos2gaea.sh !!!
#
# Can run atmos2gaea.sh, it will call this script if tar bundles are not found
#
# Prepare tar files bundled by year and forecast start month 
# with perturbations to run ensemles
# Next, transfer atmos fields for N ensembles prepared from SPEAR
# for seasonal ensemble forecasts - use atmos2gaea.sh
# 
# Atmos subsets prepared in python:
# /home/Dmitry.Dukhovskoy/python/setup_seasonal_NEP/write_spear_atmos.py
# 
# Usage: sbatch atmos_tar.sh  YR1 [YR2] 
set -u

if module list | grep "gcp"; then
  echo "gcp loaded"
else
  module load gcp/2.3
fi

export DATM=/home/Dmitry.Dukhovskoy/work1/NEP_input/fcst_forcing/atmos
export DGAEA=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/NEP_data/forecast_input_data/atmos

if [[ $# < 1 ]]; then
  echo "usage: ./atmos2gaea.sh YR1 [YR2 ]"
  echo " Start/end years are missing"
  exit 1
fi

MONTHS=(1 4 7 10)   # init months
nensmb=10   # number of ensembles 
YR1=$1
if [[ $# == 1 ]]; then
  YR2=$YR1
else
  YR2=$2
fi 

cd $DATM
pwd
ls -l

yr=$YR1
#while [ $yr -le $YR2 ]; do
#  for (( mo=1; mo<=12; mo+=3 )); do
for (( yr=$YR1; yr<=$YR2; yr+=1 )); do
  ndirs=$( ls -d ${yr}-??-e?? 2> /dev/null | wc -l )
  if [[ $ndirs -eq 0 ]]; then
    echo "No SPEAR fields for ${yr} found ..."
    continue
  fi
#  for adirs in $( ls -d ${yr}-??-e?? ); do
#    mo0=$( echo $adirs | cut -d"-" -f2 )
  for mo in ${MONTHS[@]}; do
    mo0=`echo ${mo} | awk '{printf("%02d", $1)}'`
    flist=list_tar${yr}${mo0}.txt
    ndir=`ls -1 | grep "${yr}-${mo0}-e" | wc -l`
    if [[ $ndir -eq 0 ]]; then
      echo "No $yr-$mo0 found in $DATM"
      continue
    fi
#    if [[ $ndir -lt $nensmb ]]; then
#      echo "only $ndir ens found for  $yr-$mo0 in $DATM, expected $NENS, skipping ..."
#      continue
#    fi

    ls -1 | grep "${yr}-${mo0}-e" > $flist
# Check if all ensembles have been created:
#    cat $flist
    ndirens=$( cat $flist | wc -l )
    if [[ $ndirens -ne $nensmb ]]; then
      echo "N of ensemble directories $ndirens, expected $nensmb"
      echo "Need to run write_spear_atmos.py to finish atmos fields for $yr-$mo0"
      echo "skipping ..."
      continue
    else
      echo "${yr}-${mo0}  $ndirens atmos ensembles found:   ok"
    fi

    ftar=spear_atmos_${yr}${mo0}.tar.gz
    if [ -s $ftar ]; then
      echo "${ftar} exists, skipping"
    else
      echo "Tarring $flist --> ${ftar}"
      /bin/tar -czvf ${ftar} -T ${flist}
      wait
    fi
  done
#  yr=$((yr + 1))
#  echo "yr=$yr"
done

echo "atmos_tar.sh: All done "

exit 0 

