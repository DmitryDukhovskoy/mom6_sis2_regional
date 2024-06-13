#!/bin/bash -x
#
# Transfer atmos fields for N ensembles prepared from SPEAR
# for seasonal ensemble forecasts
#  
# Usage: atmos2gaea.sh YR1 [YR2] 
set -u

export DATM=/home/Dmitry.Dukhovskoy/work1/NEP_input/fcst_forcing/atmos
export DGAEA=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/NEP_data/forecast_input_data/atmos

if [[ $# < 1 ]]; then
  echo "usage: ./atmos2gaea.sh YR1 [YR2 ]"
  echo " Start/end years are missing"
  exit 1
fi

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
    ftar=spear_atmos_${yr}${mo0}.tar.gz
    if [ -s $ftar ]; then
      echo "${ftar} exists, skipping"
      continue
    fi

    echo "Tarring $flist --> ${ftar}"
    /bin/tar -czvf ${ftar} -T ${flist}
    wait
    
    chck_file=spear_atmos_${yr}${mo0}_sent
    /bin/rm -f $chck_file
    gcp $ftar gaea:$DGAEA/
    status=$?
    if [[ $status == 0 ]]; then
      `echo $ftar > $chck_file`
    fi
  done
  yr=$((yr + 1))
  echo "yr=$yr"

done

exit 0 

