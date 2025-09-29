#!/bin/bash
# SBATCH --output=logs/subset2D_%j.out
set -u

if module list | grep "python"; then
  echo "python loaded"
else
  module load python/3.11
fi

#module list
eval "$($PYPATH/bin/conda shell.bash hook)"
conda activate anls

usage() {
  echo "Usage:  [sbatch] $0 --yrs 1993 [--yre 1999] [--mm 4] [--ens1 ...] [--ens2 ...]"
  echo "  --yrs     start year to subset output fields"
  echo "  --yre     end year to subset forecast, default yre=yrs, subset no more than 1 yr - too much data"
  echo "  --mm      init month to subset, default all 1,4,7,10"
  echo "  --ens1    subset seas forecast ens. run ens1"
  echo "  --ens2    subset seas forecast ens. runs ens1-ens2, deault ens2=ens1"
  exit 1
}

run_py() {
  local PYTH=$1
  local MO=$2
  local yrs=$3
  local yre=$4
  local ensS=$5
  local ensE=$6

  echo "running $PYTH"
  echo "MO=$MO yrs=$yrs yre=$yre ensS=$ensS ensE=$ensE"

  if [[ $MO -eq 0 ]]; then
  # all months
    python $PYTH --yrs $yrs --yre $yre --ensS $ensS --ensE $ensE
  else
    python $PYTH --yrs $yrs --yre $yre --ensS $ensS --ensE $ensE --mo $MO
  fi
}

# Defaults:
YR1=0
YR2=0
MM=0
ens1=0
ens2=0
MINIT=(1 4 7 10)
ENSMB=(1 2 3 4 5 6 7 8 9 10)


# Parse the command-line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --yrs) YR1=$2; shift 2 ;;
    --yre) YR2=$2; shift 2 ;;
    --ens1) ens1=$2; shift 2 ;;
    --ens2) ens2=$2; shift 2 ;;
    --mm) MINIT=($2); shift 2 ;;
    --help) usage; exit 0 ;;
    *) echo "Error: Unrecognized option $1"; usage; exit 1 ;;
  esac
done

if [[ $YR1 -eq 0 ]]; then
  echo "ERR: YR1 not specified"
  usage
fi

if [[ $YR2 -eq 0 ]]; then
  YR2=$YR1
fi

if [[ $ens1 -gt 0 ]] && [[ $ens2 -eq 0 ]]; then
  ens2=$ens1
fi

if [[ $ens1 -gt 0 ]]; then
  ENSMB=()
  for (( ii=ens1; ii<=ens2; ii++ )); do
    ENSMB+=($ii)
  done
fi


DPYTH=/home/Dmitry.Dukhovskoy/python/anls_BGCseasonal
pocn=subset_ocean_month3D.py
HEXE=${DPYTH}/${pice}

# Check if the subset has been finished or exists
# Update start year if needed
PTHCLB=/collab1/data_untrusted/Dmitry.Dukhovskoy/NEPbgc_fcst_dailyOB01/
for (( YR=$YR1; YR<=$YR2; YR++ )); do
  for MS in ${MINIT[@]}; do
    for ens in ${ENSMB[@]}; do
      mstart=$(printf "%02d" "$MS")
      nens=$(printf "%02d" "$ens")
      sfx="ocean3Dmonth_init${YR}${mstart}e${nens}"
      fl_done=${sfx}_done
      if [ -f "${fl_done}" ]; then
        echo "${sfx} already processed, skipping ..."
        continue
      fi

      echo "Subsetting $sfx"
      run_py "$HEXE"
    done
  done
done

exit 0



