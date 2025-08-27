#!/bin/bash 
# 
# rename dir sfxYYYYMMDD to some new name by adding efx at the end: sfxYYYYMMDD_efx
#
set -u

DDIR="/archive/Dmitry.Dukhovskoy/fre/NEP/hindcast_bgc/NEPbgc_nudged_hindcast02/restart"

MONTHS=(1 4 7 10) # initialization months
YR1=0
YR2=0
sfx=""
efx='none'

usage() {
  echo "Usage: $0 --ys 1994 --ye 1994"
  echo "  --ys          start with this init year to pprcs the f/cast <-- Required" 
  echo "  --ye          end with this f/cast init year, default=same as ys"
  echo "  --ms      month to start the f/cast, default: 1,4,7,10" 
  echo "  --sfx     prefix in the dir naming, e.g. restdate_, default - none"
  echo "  --efx     ending added to the renamed file name, e.g _old " 
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
    --sfx)
      sfx="$2"
      shift 2
      ;;
    --efx)
      efx="$2"
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

if [ ${efx} == 'none' ]; then
  echo "ERR: Need to specify ending to add to the dir name"
  usage
fi

cd ${DDIR}
pwd

for (( yr=$YR1; yr<=$YR2; yr+=1 )); do
  for mo in ${MONTHS[@]}; do
    mo0=$(printf "%02d" "$mo")
    drold="${sfx}${yr}${mo0}01"
    drnew="${drold}${efx}"

    if [ -d "$drold" ]; then
      echo "Renaming $drold ---> $drnew "
       mv "$drold" "$drnew"
    else
      echo "Does not exist ${drold}, skipping ..."
      continue
    fi
  done
done


exit 0


