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

YR1=0
expt_nmb=02
if [[ $# -eq 1 ]]; then
  if [[ $# -gt 100 ]]; then
    YR1=$1
    echo "Finished runs for ${YR1}:"
  else
    expt_nmb=$1
  fi
fi
if [[ $# -eq 2 ]]; then
  YR1=$1
  expt_nmb=$2
  echo "Finished runs for ${YR1}:"
fi

export EXPT_NAME=NEPphys_frcst_dailyOB-expt${expt_nmb}
export DARCH=/archive/Dmitry.Dukhovskoy/fre/${REG}/${EXPT}/${EXPT_NAME}

MONTHS=(1 4 7 10)

yrold=0
cd $DARCH
for dens in $( ls -d ????-??-e?? ); do
#  echo "$dens"
  yrstart=$( echo $dens | cut -d"-" -f1 )
  if [[ $YR1 -gt 0 ]] && [[ ! $yrstart -eq $YR1 ]]; then
    continue
  fi
  if [[ $yrstart -ne $yrold ]]; then
    echo "Finished runs ${EXPT_NAME} ${yrstart}:"
    yrold=$yrstart
  fi
  mstart=$( echo $dens | cut -d"-" -f2 )
  ens=$( echo $dens | cut -d"-" -f3 )
#
  nfiles=$( ls -1 ${dens}/history/{ice,ocean}* | grep '\.nc' | wc -l )
  aa=$( du -h --max-depth=1 ${dens}/history/ | tail -1 ) 
  nsize=$( echo $aa | cut -d' ' -f1 )

  echo "Post-processed $dens: N files=${nfiles} Storage=${nsize}"
done

# Not post-processed tar files dumped from gaea:
DDUMP=/archive/Dmitry.Dukhovskoy/fre/${REG}/${EXPT}

cd $DDUMP
yrold=0
nnp=$( ls -d1 NEPphys_frcst_dailyOB${expt_nmb}_????-??-e?? 2> /dev/null | wc -l )
echo "Not pos-processed tar files: $nnp"
if [[ $nnp -gt 0 ]]; then
  for dens in $( ls -d NEPphys_frcst_dailyOB${expt_nmb}_????-??-e?? ); do
    dmm=$( echo $dens | cut -d"_" -f4 )
    yrstart=$( echo $dmm | cut -d"-" -f1 )
    mostart=$( echo $dmm | cut -d"-" -f2 )
    if [[ $YR1 -gt 0 ]] && [[ ! $yrstart -eq $YR1 ]]; then
      continue
    fi
    fltar=${yrstart}${mostart}01.nc.tar

    if [ -s ./$dens/${PLTF}/history/$fltar ]; then
      echo "$dmm: ---> $fltar"
    else
      echo "$dmm: $fltar is missing"
    fi
  done
fi
#echo "All Done"

exit 0

    


