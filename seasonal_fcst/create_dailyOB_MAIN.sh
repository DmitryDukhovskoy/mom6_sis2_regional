#!/bin/bash 
# Main code (wrapper) to create daily OB files and send to gaea
# All steps included
# Automatically checks completion of each step
#
# usage: create_dailyOB_MAIN.sh YR1 [YR2] [M1] ens1 [ens2]
# Here ens is SPEAR ensemble run, it is also the seasonal f/cast ens# unless 
# fixed SPEAR ens run is used for all seasonal f/casts
# then create 1 OB (e.g. ens=1) and use it as OB for all seasonal f/casts
#
# Examples:
#   create_dailyOB_MAIN.sh YR1 ens - generate OBs for init YR1 all months Jan, Apr, .., and ens run = ens
#   create_dailyOB_MAIN.sh YR1 YR2 ens - generate OBs for init YR1-YR2, all months and ens run = ens
#   create_dailyOB_MAIN.sh YR1 MM ens - generate OBs for init YR1 month=MM and ens run = ens (1 file)
#   create_dailyOB_MAIN.sh YR1 YR2 MM ens - generate OBs for init YR1-YR2  month=MM and ensrun = ens
#   create_dailyOB_MAIN.sh YR1 MM ens1 ens2 - generate OBs for init YR1  month=MM and ensruns = ens1:ens2
#
#
set -u

export obc_dir=/work/Dmitry.Dukhovskoy/NEP_input/spear_obc_daily
export run_dir=/work/Dmitry.Dukhovskoy/NEP_input/obc_daily_scripts
export py_dir=/home/Dmitry.Dukhovskoy/python/setup_seasonal_NEP
export WD=/work/Dmitry.Dukhovskoy/tmp/spear_subset/scripts
export SRC=/home/Dmitry.Dukhovskoy/scripts/seasonal_fcst


if [[ $# < 2 ]]; then
  echo "at least init year and ens should be specified"
  echo "usage: create_dailyOB_MAIN.sh YR1 [YR2] [MM] ens1 [ens2]"
  echo "e.g. create OBs for 1999/4 from 1-10 SPEAR ensembles: create_dailyOB_MAIN.sh 1999 4 1 10"
  echo "e.g. create OBs for 1999/4 from ens=3 SPEAR ensembles: create_dailyOB_MAIN.sh 1999 4 3"
  exit 1
fi

YR1=$1
YR2=$YR1
MONTHS=(1 4 7 10)
#ens=$( echo $2 | awk '{printf("%02d",$1)}' )
ens1=$2


if [[ $# -eq 3 ]]; then
  if [[ $2 -gt 100 ]]; then
    YR2=$2
  else
    MONTHS=($2)
  fi
  ens1=$3
fi
ens2=$ens1

if [[ $# -eq 4 ]]; then
  if [[ $2 -gt 100 ]]; then
    YR2=$2
    MONTHS=($3)
    ens1=$4
    ens2=$ens1
  else
    MONTHS=($2)
    ens1=$3
    ens2=$4
  fi
fi

if [[ $YR1 -lt 1900 ]] || [[ $YR2 -lt 1900 ]]; then
  echo "ERROR: Check input years YR1=$YR1 YR2=$YR2 "
  exit 1
fi

echo "OBCs will be created for ${YR1}-${YR2} MM=${MONTHS[@]} ens=${ens1}-${ens2}" 
date

# First check if gzip exists but has not been sent:
echo "Existing *.nc or gzipped will be checked first, not sent but created fields will be sent to gaea ..."

# Unstage and Subset SPEAR files for NEP domain
echo "Subsetting SPEAR to NEP domain, calling subset_spear_ocean.sh"
for (( YR=$YR1; YR<=$YR2; YR+=1 )); do
  for MM in ${MONTHS[@]}; do
    for (( ens_run=$ens1; ens_run<=$ens2; ens_run+=1 )); do
# Check if OB created:
      ${SRC}/check_createdOB_notsent.sh $YR $MM ${ens_run}
      status=$?
      if [[ $status -eq 2 ]]; then
        echo " OB file *${YR}${MM}01_e${ens_run}.nc created not zipped/sent yet, skipping unstaging ..."
        continue
      fi
      if [[ $status -eq 3 ]]; then
        echo " OB file *${YR}${MM}01_e${ens_run}.nc.gz created AND zipped but NOT sent yet, skipping unstaging ..."
        continue
      fi

      echo "Calling ${SRC}/subset_spear_ocean.sh $YR ${MM} ${ens_run}"
      ${SRC}/subset_spear_ocean.sh $YR ${MM} ${ens_run}
      status=$?
      if [[ $status -gt 0 ]]; then
        echo "ERROR flag, quitting ..."
        exit 5
      fi
    done
  done
done

# Create daily fields:
echo "Creating daily OB"
for (( YR=$YR1; YR<=$YR2; YR+=1 )); do
  for MM in ${MONTHS[@]}; do
    for (( ens_run=$ens1; ens_run<=$ens2; ens_run+=1 )); do
      ${SRC}/create_daily_OBspear.sh $YR ${MM} ${ens_run}
      status=$?
    
      if [[ $status -eq 0 ]]; then 
# ZIP and send to gaea:
        echo "ZIP and send ---> gaea"
        cd ${SRC}
  #    ${SRC}/zipOB_to_gaea.sh $YR1 ${YR2inp} ${mo_start} ${ens_run}
        sbatch -t 120 zipOB_to_gaea.sh $YR ${MM} ${ens_run}
      else
        echo "create_daily_OBspear failed, exit = $status, quitting ..."
        exit 1
      fi

    done
  done 
done

echo "======= ALL DONE ========="
date





