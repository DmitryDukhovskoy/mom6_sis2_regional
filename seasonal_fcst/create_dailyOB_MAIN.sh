#!/bin/bash 
# Main code (wrapper) to create daily OB files and send to gaea
# All steps included
# Automatically checks completion of each step
#
# Here ens is SPEAR ensemble run, it is also the seasonal f/cast ens# unless 
# fixed SPEAR ens run is used for all seasonal f/casts
# then create 1 OB (e.g. ens=1) and use it as OB for all seasonal f/casts
#
set -u

export obc_dir=/work/Dmitry.Dukhovskoy/NEP_input/spear_obc_daily
export run_dir=/work/Dmitry.Dukhovskoy/NEP_input/obc_daily_scripts
export py_dir=/home/Dmitry.Dukhovskoy/python/setup_seasonal_NEP
export WD=/work/Dmitry.Dukhovskoy/tmp/spear_subset/scripts
export SRC=/home/Dmitry.Dukhovskoy/scripts/seasonal_fcst

YR1=0
YR2=0
MONTHS=(1 4 7 10)
ENSMB=(1 2 3 4 5 6 7 8 9 10)
ens1=0
ens2=0

usage() {
  echo "Usage: $0 --ys 1994 [--ye 1995] [--mm 4] --ens 1,...,10 "
  echo "  --ys     start with this year  <-- Required" 
  echo "  --ye     end with this year, default=same as ys"
  echo "  --mm     month to process, default (1,4,7,10)"
  echo "  --ens    SPEAR ens. run to process, default all: (1,...,10)"
  echo "  --ensE   set a range of ensembles: [ens, ..., ensE], ensE>=ens, optional"
  exit 1
}

# Parse the command-line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --ys)
      YR1=$2
      shift 2 # Move past the flag and its arg. to the next flag
      ;;
    --ye)
      YR2=$2
      shift 2
      ;;
    --mm)
      MONTHS=($2)
      shift 2
      ;;
    --ens)
      ens1=$2
      shift 2
      ;;
    --ensE)
      ens2=$2
      shift 2
      ;;
    --help)
      usage
      ;;
    *)
    echo "Error: Unrecognized option $1"
    usage
    ;;
  esac
done

if [[ $YR1 -eq 0 ]]; then
  echo "ERR: YR1 was not specified $YR1"
  usage
fi
if [[ $YR2 -eq 0 ]]; then
  YR2=$YR1
fi

if [[ $YR1 -lt 1900 ]] || [[ $YR2 -lt 1900 ]]; then
  echo "ERROR: Check input years YR1=$YR1 YR2=$YR2 "
  usage
fi

# If ens. range is requested, redifine ENSMB array:
if [[ $ens1 -gt 0 ]] && [[ $ens2 -eq 0 ]]; then
  ens2=$ens1
fi

if [[ $ens1 -gt 0 ]]; then
  ENSMB=()
  for (( ii=ens1; ii<=ens2; ii++ )); do
    ENSMB+=($ii)
  done
fi

echo "OBCs will be created for ${YR1}-${YR2} MM=${MONTHS[@]} ens=${ENSMB[@]}" 
date

# First check if gzip exists but has not been sent:
echo "Existing *.nc or gzipped will be checked first, not sent but created fields will be sent to gaea ..."

# Unstage and Subset SPEAR files for NEP domain
echo "Subsetting SPEAR to NEP domain, calling subset_spear_ocean.sh"
for (( YR=$YR1; YR<=$YR2; YR+=1 )); do
  for MM in ${MONTHS[@]}; do
    for ens_run in ${ENSMB[@]}; do
      ens0=$( echo $ens_run | awk '{printf("%02d",$1)}' )
# Check if OB created:
      ${SRC}/check_createdOB_notsent.sh --yr $YR --mm $MM --ens ${ens_run}
      status=$?
      if [[ $status -eq 2 ]]; then
        echo " OB file *${YR}${MM}01_e${ens0}.nc created not zipped/sent yet, skipping unstaging ..."
        continue
      fi
      if [[ $status -eq 3 ]]; then
        echo " OB file *${YR}${MM}01_e${ens0}.nc.gz created AND zipped but NOT sent yet, skipping unstaging ..."
        continue
      fi

      echo "Calling ${SRC}/subset_spear_ocean.sh $YR ${MM} ${ens_run}"
      ${SRC}/subset_spear_ocean.sh --ys $YR --mm ${MM} --ens ${ens_run}
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
    for ens_run in ${ENSMB[@]}; do
      ens0=$( echo $ens_run | awk '{printf("%02d",$1)}' )
      ${SRC}/create_daily_OBspear.sh --ys $YR --mm ${MM} --ens ${ens_run}
      status=$?
    
      if [[ $status -eq 0 ]]; then 
# ZIP and send to gaea:
# Do not zip, just send to gaea:
#        echo "ZIP and send ---> gaea"
        echo "send ---> gaea"
        cd ${SRC}
  #    ${SRC}/zipOB_to_gaea.sh $YR1 ${YR2inp} ${mo_start} ${ens_run}
        #sbatch -t 120 zipOB_to_gaea.sh $YR ${MM} ${ens_run}
        sbatch -t 120 sendOB_to_gaea.sh --ys $YR --mm ${MM} --ens ${ens_run}
      else
        echo "create_daily_OBspear failed, exit = $status, quitting ..."
        exit 1
      fi

    done
  done 
done

echo "======= ALL DONE ========="
date





