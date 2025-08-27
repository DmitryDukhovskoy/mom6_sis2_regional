#!/bin/bash 
#
# Careful when modifying this file, it is called from atmos2gaea.sh !!!
#
# Can run atmos2gaea.sh, it will call this script if tar bundles are not found
#
# Prepare tar files bundled by year and forecast start month 
# with perturbations to run ensemles
# Next, transfer atmos fields for N ensembles prepared from SPEAR
# for seasonal ensemble forecasts - use atmos2gaea.sh
# 
# Atmos subsets prepared in python:
# /home/Dmitry.Dukhovskoy/python/setup_seasonal_NEP/write_spear_atmos.py
# 
# Usage: sbatch atmos_tar.sh  YR1 [YR2] 
set -u


export DATM=/home/Dmitry.Dukhovskoy/work1/NEP_input/fcst_forcing/atmos
MONTHS=(1 4 7 10) # initialization months
ENSMB=(1 2 3 4 5 6 7 8 9 10)   # ens runs
YR1=0
YR2=0
ensS=0
ensE=0

usage() {
  echo "Usage: $0 --ys 1994 --ye 1994"
  echo "  --ys          start with this init year to pprcs the f/cast <-- Required" 
  echo "  --ye          end with this f/cast init year, default=same as ys"
  echo "  --datm        home directory where NEP atm forcing is, default=DATM"
  echo "  --dgaea       atm. forc. dir on Gaea"
  echo "  --ms      month to start the f/cast, default: 1,4,7,10" 
  echo "  --ensS    1st ensemble # to run, default: all ensmbls: 1, ..., 10"
  echo "  --ensE    last ensemble number to run, f/cast will be run for ensS,...,ensE, default=ensS"
  exit 1
}

# Pars flags for optional arguments:
while [[ $# -gt 0 ]]; do
  case $1 in
    --ys)
      YR1="$2"
      shift 2
      ;;
    --ye)
      YR2="$2"
      shift 2
      ;;
    --ms)
      MONTHS=("$2")
      shift 2
      ;;
    --ensS)
      ensS=$2
      shift 2
      ;;
    --ensE)
      ensE=$2
      shift 2
      ;;
    --datm)
      DATM="$2"
      shift 2
      ;;
    --dgaea)
      DGAEA="$2"
      shift 2
      ;;
    --ensE)
      ensE=$2
      shift 2
      ;;
    --fs)
      FS="$2"
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

if [[ ${YR1} -eq 0 ]]; then
  echo "ERR: Start year was not specified"
  usage
fi

if [[ ${YR2} -eq 0 ]]; then
  YR2="$YR1"
fi

if (( ensS > 0 && ensE == 0 )); then
  ensE=$ensS
fi

if (( ensS > 0 )); then
  ENSMB=()
  for (( ens=$ensS; ens<=$ensE; ens++ )); do
    ENSMB+=("$ens")
  done
fi

nensmb=10

echo "Tarring atm forcing files for $YR1 - $YR2 MM=${MONTHS[@]} ENS=${ENSMB[@]}"
cd "$DATM" || { echo "Error: Cannot cd to $DATM"; exit 1; }
pwd
ls -l

for (( yr=$YR1; yr<=$YR2; yr+=1 )); do
  ndirs=$( ls -d ${yr}-??-e?? 2> /dev/null | wc -l )
  if [[ $ndirs -eq 0 ]]; then
    echo "No SPEAR fields for ${yr} found ..."
    continue
  fi

  for mo in ${MONTHS[@]}; do
    mo0=`echo ${mo} | awk '{printf("%02d", $1)}'`

    for ens in ${ENSMB[@]}; do
      ens0=$(printf "%02d" "$ens")
      atm_dir="${yr}-${mo0}-e${ens0}"
      ftar=spear_atmos_${yr}${mo0}e${ens0}.tar
      if [ -d "$atm_dir" ]; then
        echo "Creating tar ${ftar}"
        /bin/tar -cvf ${ftar} ${atm_dir}
        wait
      else
        echo "Missing ${atm_dir}"
        echo "Need to run write_spear_atmos.py to finish atmos fields for $yr-$mo0"
        echo "skipping ..."
        continue
      fi
    done
  done
done

echo "atmos_tar.sh: All done "

exit 0 

