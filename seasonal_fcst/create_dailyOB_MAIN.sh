#!/bin/bash 
# Main code (wrapper) to create daily OB files and send to gaea
# All steps included
# Automatically checks completion of each step
#
# usage: create_dailyOB_MAIN.sh YR1 [YR2] [M1] ens1 [ens2]
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

YR2inp=""
M1inp=""
M2inp=""
ens1inp=""
ens2inp=""

if [[ $# < 2 ]]; then
  echo "at least init year and ens should be specified"
  echo "usage: create_dailyOB_MAIN.sh YR1 [YR2] [MM] ens1 [ens2]"
  exit 1
fi

YR1=$1
YR2=$YR1
MONTHS=(1 4 7 10)
#ens=$( echo $2 | awk '{printf("%02d",$1)}' )
ens1=$2

YR1inp=$YR1
ens1inp=$ens1

if [[ $# -eq 3 ]]; then
  if [[ $2 -gt 100 ]]; then
    YR2=$2
    YR2inp=$2
  else
    MONTHS=($2)
    M1inp=$2
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

    YR2inp=$YR2
    M1inp=$3
  else
    MONTHS=($2)
    ens1=$3
    ens2=$4

    M1inp=$2
    ens1inp=$ens1
    ens2inp=$ens2
  fi
fi

if [[ $YR1 -lt 1900 ]] || [[ $YR2 -lt 1900 ]]; then
  echo "ERROR: Check input years YR1=$YR1 YR2=$YR2 "
  exit 1
fi

echo "OBCs will be created for ${YR1}-${YR2} MM=${MONTHS[@]} ens=${ens1}-${ens2}" 
date

# Unstage and Subset SPEAR files for NEP domain
echo "Subsetting SPEAR to NEP domain, calling subset_spear_ocean.sh"
${SRC}/subset_spear_ocean.sh $YR1 ${YR2inp} ${M1inp} $ens1 ${ens2inp}
status=$?
if [[ $status -gt 0 ]]; then
  echo "ERROR flag, quitting ..."
  exit 5
fi

# Create daily fields:
echo "Creating daily OB"
${SRC}/create_daily_OBspear.sh $YR1 ${YR2inp} ${M1inp} $ens1 ${ens2inp}
wait 

# ZIP and send to gaea:
echo "ZIP and send ---> gaea"
for mo_start in ${MONTHS[@]}; do
  for (( ens_run=$ens1; ens_run<=$ens2; ens_run+=1 )); do
    ${SRC}/zipOB_to_gaea.sh $YR1 ${YR2inp} ${mo_start} ${ens_run}
  done
done 


echo "======= ALL DONE ========="
date





