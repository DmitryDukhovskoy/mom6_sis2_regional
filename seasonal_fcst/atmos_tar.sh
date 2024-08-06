#!/bin/bash -x
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
while [ $yr -le $YR2 ]; do
  for (( mo=1; mo<=12; mo+=3 )); do
    mo0=`echo ${mo} | awk '{printf("%02d", $1)}'`
    flist=list_tar${yr}${mo0}.txt
    ndir=`ls -1 | grep "${yr}-${mo0}-e" | wc -l`
    if (( $ndir == 0 )); then
      echo "No $yr-$mo0 found in $DATM"
      continue
    fi

    ls -1 | grep "${yr}-${mo0}-e" > $flist
# Check if all ensembles have been created:
#    cat $flist
    ndirens=$( cat $flist | wc -l )
    if (( $ndirens != $nensmb )); then
      echo "# of ensemble directories $ndirens, expected $nensmb"
      echo "Need to run write_spear_atmos.py to finish atmos fields for $yr"
      echo "STOPPING ..."
      exit 1
    fi

    ftar=spear_atmos_${yr}${mo0}.tar.gz
    if [ -s $ftar ]; then
      echo "${ftar} exists, skipping"
    else
      echo "Tarring $flist --> ${ftar}"
      /bin/tar -czvf ${ftar} -T ${flist}
      wait
    fi
    
#    chck_file=spear_atmos_${yr}${mo0}_sent
#    if [ -s $chck_file ]; then
#      echo "$ftar was already sent"
#    else
#      /bin/rm -f $chck_file
#      gcp $ftar gaea:$DGAEA/
#      status=$?
#      if [[ $status == 0 ]]; then
#        `echo $ftar > $chck_file`
#      fi
#    fi

  done
  yr=$((yr + 1))
  echo "yr=$yr"

done

exit 0 

