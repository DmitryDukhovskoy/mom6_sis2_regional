#!/bin/bash
#  !!! be careful when modifying this code !!!
# is it called by several other scripts to check the status of OB files
# e.g. create_dailyOB_MAIN.sh
#
# Check if OB file has been sent to gaea
# check: status=$?
# if status == 2 - file already sent
#
#  usage: check_sentOB.sh YR MM ens
# 
set -u

export obc_dir=/work/Dmitry.Dukhovskoy/NEP_input/spear_obc_daily
export gaea_dir=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/NEP_data/forecast_input_data/obcs_spear_daily
export prfx=OBCs_spear_daily_init


if [[ $# -lt 3 ]]; then
  echo "MIssing YR MM ENSEMBLE"
  echo "usage: check_sentOB.sh YR MM ens"
  exit 1
fi

YR=$1
MM=$2
ens=$3
MM0=$( echo $MM | awk '{printf("%02d", $1)}' )      
ens0=$( echo $ens | awk '{printf("%02d",$1)}' )

cd $obc_dir

flnm=${prfx}${YR}${MM0}01_e${ens0}
flz=${flnm}.nc.gz

icc=0
for dflzsent in $( ls sent_OBCs/*-sent ); do
  flzsent=$( echo $dflzsent | cut -d"/" -f2 )
  if [[ ${flz}-sent == ${flzsent} ]]; then
     icc=$(( icc+1 ))
  fi
done

if [[ $icc -eq 1 ]]; then
  echo "$flnm has been already sent to gaea"
  exit 2
else
  echo "$flnm has NOT been sent to gaea"
fi

exit 0  


