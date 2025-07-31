#!/bin/bash
# Send OB daily fields for NEP seasonal forecasts
# from gaea to PPAN archive for storing the data
# ~9TB of data
# 
set -u

export gaea_dir=/gpfs/f6/ira-cefi/scratch/Dmitry.Dukhovskoy/NEP_data/forecast_input_data/obcs_spear_daily
export ppan_dir=/archive/Dmitry.Dukhovskoy/NEP_input/spear_obc_daily

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


for (( YR=$YR1; YR<=$YR2; YR+=1 )); do
  for MM in ${MONTHS[@]}; do
    for ens_run in ${ENSMB[@]}; do
      #ens0=$( echo $ens_run | awk '{printf("%02d",$1)}' )
      ens0=$(printf "%02d" "$ens_run")
      MM0=$(printf "%02d" "$MM")
      DRIN="${gaea_dir}/${YR}_e${ens0}"
      DROUT="${ppan_dir}/${YR}_e${ens0}"
      mkdir -pv ${DROUT}

      flob="OBCs_spear_daily_init${YR}${MM0}01_e${ens0}.nc"
      # Check if the file has already been copied:
      if [ -s ${DROUT}/${flob} ]; then
        echo "Already copied: ${DROUT}/${flob}, skipping ..."
        continue
      fi

      echo "Copying gaea:${DRIN}/${flob} ---> gfdl:${DROUT}"
      gcp gaea:${DRIN}/${flob} gfdl:${DROUT}/

    done
  done
done

echo "All done "
date

exit 0
