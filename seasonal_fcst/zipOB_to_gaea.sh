#!/bin/bash
#SBATCH --output=logs/zipOB%j.out
# 
# gzip and 
# send zipped OB file to gaea: 
# specify at least 1 year to zip/send OBC files
# all months and ensembles will be zipped
# for specific month , ensembles specify optional YR2 MO and ENS
#  YR2 may be skipped if YR2=Y1 and MO and ENS specified
# meaning that files for YR1 MO and ENS will be zipped/sent to gaea
#
#  usage: [sbatch] zipOB_to_gaea.sh YR1 [[YR2]] [MO] [ENS] 
#
set -u

export obc_dir=/work/Dmitry.Dukhovskoy/NEP_input/spear_obc_daily
export gaea_dir=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/NEP_data/forecast_input_data/obcs_spear_daily

if module list | grep "gcp"; then
  echo "gcp loaded"
else
  module load gcp/2.3
fi

if [[ $# -lt 1 ]]; then
  echo "at least year should be given"
  echo "usage: [sbatch] zipOB_to_gaea.sh YR1 [YR2] [MO] [ENS]"
  exit 1
fi

date

YR1=$1
YR2=$YR1
MM=0
ens=0
if [[ $# -gt 1 ]]; then
  if [[ $2 -gt 100 ]]; then 
    YR2=$2

    if [[ $# -eq 3 ]]; then
      MM=$( echo $3 | awk '{printf("%02d",$1)}' )
    fi

    if [[ $# -eq 4 ]]; then
      ens=$( echo $4 | awk '{printf("%02d",$1)}' )
    fi
  else
    MM=$2
    if [[ $# -eq 3 ]]; then
      ens=$( echo $3 | awk '{printf("%02d",$1)}' )
    fi
  fi
fi

MM0=$( echo $MM | awk '{printf("%02d", $1)}' )      
mkdir -pv $obc_dir/sent_OBCs

prfx=OBCs_spear_daily_init
for (( ystart=$YR1; ystart<=$YR2; ystart+=1 )); do
  cd $obc_dir
  if [ $MM -eq 0 ]; then
    flnm=${prfx}${ystart}
  else
    flnm=${prfx}${ystart}${MM0}
  fi

  if [ $ens -ne 0 ]; then
    flnm=${prfx}${ystart}${MM0}01_e${ens}
  fi
  
  /bin/ls -l $flnm*

# send already zipped files that have not been sent yet
  nflz=$( ls -1 $flnm*nc.gz | wc -l )
#  echo "nflz=$nflz"
  if [[ $nflz -gt 0 ]]; then
    for flz in $( ls $flnm*nc.gz ); do
      icc=0
      for dflzsent in $( ls sent_OBCs/*-sent ); do
        flzsent=$( echo $dflzsent | cut -d"/" -f2 )
        if [[ ${flz}-sent == ${flzsent} ]]; then
           echo "${flz} already sent, no action ..."
           icc=$(( icc+1 ))
        fi
      done

      if [[ $icc -eq 0 ]]; then
        echo "Found already zipped file $flz"
        echo "sending ${flz} to gaea: ${gaea_dir} ..."

        gcp ${flz} gaea:${gaea_dir}/.
        status=$?
        if [[ $status == 0 ]]; then
          echo "${flz} sent to gaea "
          touch sent_OBCs/${flz}-sent
        fi
      fi
    done
  fi
# zip and send unzipped files
  date
  for fl in $( ls $flnm*nc ); do
    echo "zipping ${fl} "
    gzip ${fl}
    wait
    date

    echo "sending ${fl}.gz to gaea: ${gaea_dir} ..."

    gcp ${fl}.gz gaea:${gaea_dir}/.
    status=$?
    if [[ $status == 0 ]]; then
      echo "${fl}.gz sent to gaea "
      touch sent_OBCs/${fl}.gz-sent
    fi
    date
  done


done


echo "All done "

exit 0  


