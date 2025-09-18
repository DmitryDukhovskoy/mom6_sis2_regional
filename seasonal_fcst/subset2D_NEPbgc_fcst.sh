#!/bin/bash
# SBATCH --output=logs/subset2D_%j.out
#  sbatch does not work for untrusted output dir !
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
  echo "Usage:  $0 --yrs 1993 [--yre 1999] [--mm 4] [--ens1 ...] [--ens2 ...] [...]"
  echo "  --yrs     start year to subset output fields"
  echo "  --yre     end year to subset SPEAR, default yre=yrs"
  echo "  --mm      init month to subset, default all 1,4,7,10"
  echo "  --ens1    subset SPEAR ens. run ens1"
  echo "  --ens2    subset SPEAR ens. runs ens1-ens2, deault ens2=ens1"
  echo "  --ocnm    T/F - subset ocean_month.nc, default F"
  echo "  --icem    T/F - subset ice_month.nc, default F"
  echo "  --cobbtm  T/F - subset ocean_cobalt_btm, default F"
  echo "  --cobtrc  T/F - subset ocean_cobalt_tracers_int, default F"
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
ocnm=F
icem=F
cobbtm=F
cobtrc=F
YR1=0
YR2=0
MM=0
ens1=0
ens2=0

# Parse the command-line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --yrs) YR1=$2; shift 2 ;;
    --yre) YR2=$2; shift 2 ;;
    --ens1) ens1=$2; shift 2 ;;
    --ens2) ens2=$2; shift 2 ;;
    --mm) MM=$2; shift 2 ;;
    --ocnm) ocnm=${2^^}; shift 2 ;;
    --icem) icem=${2^^}; shift 2 ;;
    --cobbtm) cobbtm=${2^^}; shift 2 ;;
    --cobtrc) cobtrc=${2^^}; shift 2 ;;
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

if [[ $ens1 -eq 0 ]]; then
  ens1=1
fi
if [[ $ens2 -eq 0 ]]; then
  ens2=10
fi

DPYTH=/home/Dmitry.Dukhovskoy/python/anls_BGCseasonal
pocn=subset_ocean2D.py
pice=subset_ice_month.py
pcobbtm=subset_cobalt_btm.py
pcobtrc=subset_cobalt_tracers_int.py


if [[ $ocnm == 'T' ]]; then
  HEXE=${DPYTH}/${pocn}
  run_py "$HEXE" "$MM" "$YR1" "$YR2" "$ens1" "$ens2" 
fi

if [[ $icem == 'T' ]]; then
  HEXE=${DPYTH}/${pice}
  run_py "$HEXE" "$MM" "$YR1" "$YR2" "$ens1" "$ens2" 
fi

if [[ $cobbtm == 'T' ]]; then
  HEXE=${DPYTH}/${pcobbtm}
  run_py "$HEXE" "$MM" "$YR1" "$YR2" "$ens1" "$ens2" 
fi

if [[ $cobtrc == 'T' ]]; then
  HEXE=${DPYTH}/${pcobtrc}
  run_py "$HEXE" "$MM" "$YR1" "$YR2" "$ens1" "$ens2" 
fi

exit 0



