#!/bin/bash
#
# Clean collab 
# mark finished years
#
set -u

PTHCLB=/collab1/data_untrusted/Dmitry.Dukhovskoy/NEPbgc_fcst_dailyOB01/

usage() {
  echo "Usage:  $0 --yrs 1993 [--yre 1999] [--mm 4] [--ens1 ...] [--ens2 ...] [...]"
  echo "  --yrs     start year to subset output fields"
  echo "  --yre     end year to subset SPEAR, default yre=yrs"
  echo "  --minit   init month, default [1,4,7,10]"
  echo "  --ens     ensemble run, default [1,...,10]"
  exit 1
}

MINIT=(1 4 7 10)
ENSMB=(1 2 3 4 5 6 7 8 9 10)
YR1=0
YR2=0
# Parse the command-line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --yrs) YR1=$2; shift 2 ;;
    --yre) YR2=$2; shift 2 ;;
    --minit) MINIT=($2); shift 2 ;;
    --ens) ENSMB=($2); shift 2 ;;
    --help) usage; exit 0 ;;
    *) echo "Error: Unrecognized option $1"; usage; exit 1; ;;
  esac
done

if [[ $YR1 -eq 0 ]]; then
  echo "ERR: YR1 not specified"
  usage
fi

if [[ $YR2 -eq 0 ]]; then
  YR2=$YR1
fi

shopt -s nullglob

nfiles=12

cd $PTHCLB || { echo "ERROR: Couldn't cd into $PTHCLB"; exit 1; }
pwd

for (( YR=$YR1; YR<=$YR2; YR+=1 )); do
  cd $PTHCLB/${YR} || { echo "ERROR: Couldn't cd into $PTHCLB/$YR"; exit 1; }
  for MS in ${MINIT[@]}; do
    mstart=$(printf "%02d" "$MS")
    for ens in ${ENSMB[@]}; do
      nens=$(printf "%02d" "$ens")
      sfx="ocean3Dmonth_init${YR}${mstart}e${nens}"
      files=( ${sfx}_??????.nc )

      echo "found files: ${#files[@]}"
      if [[ ${#files[@]} -eq 0 ]]; then
        echo "No matching files for ${sfx}_??????.nc in year $YR"
      elif [[ ${#files[@]} -lt ${nfiles} ]]; then 
        echo "Missing some files for ${sfx}_??????.nc"
      else
        for fl in "${files[@]}"; do
          echo "Deleting $fl"
          rm "$fl"
        done
        touch "${sfx}_done"
      fi

    done
  done
done

exit 0


