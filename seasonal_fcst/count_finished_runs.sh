#!/bin/bash 
#
# Check all finished runs for dailyOB expt=01 or 02 (multi-ens OBs)
# ./check_finished_runs.sh [YR1] [expt_nmb] 
set -u

export REG=NEP
export EXPT=seasonal_daily
export PLTF="gfdl.ncrc5-intel23-repro"
export oprfx=oceanm
export iprfx=icem
export DAWK=/home/Dmitry.Dukhovskoy/scripts/awk_utils


expt_nmb=02
export EXPT_NAME=NEPphys_frcst_dailyOB-expt${expt_nmb}
export DARCH=/archive/Dmitry.Dukhovskoy/fre/${REG}/${EXPT}/${EXPT_NAME}

echo $DARCH

MONTHS=(1 4 7 10)

YR1=1993
YR2=2020
mold=0
yrold=0
cd $DARCH
for (( ystart=$YR1; ystart<=$YR2; ystart+=1 )); do
  echo " "
  for mo in ${MONTHS[@]}; do
    MM=$( echo $mo | awk '{printf("%02d",$1)}' )
    ndir=$( ls -d ${ystart}-${MM}-e?? 2> /dev/null | wc -l )

    echo "$ystart-$MM  N ens runs= ${ndir}"
  done
done

exit 0

    


