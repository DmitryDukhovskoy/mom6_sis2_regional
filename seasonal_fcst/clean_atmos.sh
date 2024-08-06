#!/bin/bash 
#
# Remove directories with SPEAR ensemble atmospheric fields 
# if the tar files have been icreated and sent to gaea
#
#
set -u

export DATM=/home/Dmitry.Dukhovskoy/work1/NEP_input/fcst_forcing/atmos
export DGAEA=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/NEP_data/forecast_input_data/atmos


if [[ $# < 1 ]]; then
  YR1=1993
  YR2=2025
elif [[ $# == 1 ]]; then
  YR1=$1
  YR2=$YR1
else:
  YR1=$1
  YR2=$2
fi 

cd $DATM
pwd
ls -l *_sent

for fls in $( ls spear_atmos*_sent ); do
  dstmp=$(echo $fls | cut -d "_" -f3)
  YR=${dstmp:0:4}
  mo0=${dstmp:4:2}

  if [ $YR -ge $YR1 ] && [ $YR -le $YR2 ]; then
    echo "Removing $YR $mo0"
    for drs in $( ls -d1 ${YR}-${mo0}-e?? ); do
      echo "Removing $drs"
      /bin/rm -rf $drs
    done
  fi
done

exit 0


