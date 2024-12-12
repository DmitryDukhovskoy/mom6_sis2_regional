#!/bin/bash 
#
# Remove directories with SPEAR ensemble atmospheric fields 
# if the tar files have been created and sent to gaea
#
# usage: clean_atmos.sh YR1 [YR2] 
#    clean_atmos.sh 1999        - delete atm files for all ensembles and init months 1999
#    clean_atmos.sh 1999 2000   - delete atm files for all ensembles and init months 1999-2000
#
set -u

export DATM=/home/Dmitry.Dukhovskoy/work1/NEP_input/fcst_forcing/atmos
export DGAEA=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/NEP_data/forecast_input_data/atmos

if [[ $# -lt 1 ]] || [[ $# -gt 2 ]]; then
  echo "usage: clean_atmos.sh YR1 [YR2] "
  echo " clean_atmos.sh 1999        - delete atm files for all ensembles and init months 1999"
  echo " clean_atmos.sh 1999 2000   - delete atm files for all ensembles and init months 1999-2000"
  exit 5
fi


if [[ $# -eq 1 ]]; then
  YR1=$1
  YR2=$YR1
else
  YR1=$1
  YR2=$2
fi 

echo " {YR1} - ${YR2}"

cd $DATM
pwd
/bin/ls -l *_sent

export prfx=spear_atmos
for fls in $( ls ${prfx}*_sent ); do
  dstmp=$(echo $fls | cut -d "_" -f3)
  YR=${dstmp:0:4}
  mo0=${dstmp:4:2}

  if [[ $YR -ge $YR1 ]] && [[ $YR -le $YR2 ]]; then
    echo "Checking SPEAR atmos fields $YR $mo0"
    for drs in $( ls -d1 ${YR}-${mo0}-e?? 2> /dev/null ); do
      echo "Removing $drs"
      /bin/rm -rf $drs
    done
#
# Remove tar.gz files as well
    for flgz in $( ls ${prfx}*${YR}*tar.gz 2> /dev/null); do
      echo "Removing $flgz"
      /bin/rm -f $flgz
    done
  fi
done

exit 0


