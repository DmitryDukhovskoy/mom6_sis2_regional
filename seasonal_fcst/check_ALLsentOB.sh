#!/bin/bash
#
# Check all OB file has been sent to gaea
#
#  usage: check_ALLsentOB.sh [YR] || [YR]  [MM]
# 
set -u

export obc_dir=/work/Dmitry.Dukhovskoy/NEP_input/spear_obc_daily
export gaea_dir=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/NEP_data/forecast_input_data/obcs_spear_daily
export prfx=OBCs_spear_daily_init

YR=0
MM=0
if [[ $# -eq 1 ]]; then
  YR=$1
fi 
if [[ $# -eq 2 ]]; then
  YR=$1
  MM=$2
fi
MM0=$( echo $MM | awk '{printf("%02d", $1)}' )

cd $obc_dir

#flnm=${prfx}${YR}${MM0}01_e${ens0}
#flz=${flnm}.nc.gz

icc=0
for dflzsent in $( ls sent_OBCs/${prfx}*-sent ); do
  flzsent=$( echo $dflzsent | cut -d"/" -f2 )
  flnm=$( echo $flzsent | cut -d"." -f1 )
  dmm=$( echo $flnm | cut -d"_" -f4 )
  yr0=${dmm:4:4}
  mm0=${dmm:8:2}
  ens0=$( echo $flnm | cut -d"_" -f5 )
  if [[ $YR -gt 0 ]] && [[ 10#$yr0 -ne 10#$YR ]]; then
    continue
  else
    echo "OB $flnm $yr0/$mm0-${ens0}  ---->  sent to gaea"
  fi
done

exit 0  


