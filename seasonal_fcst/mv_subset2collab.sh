#!/bin/bash
#
# move subsetted files from work dir to 
# untrusted collab for transfer to PSL
#
set -u

PTHCLB=/collab1/data_untrusted/Dmitry.Dukhovskoy/NEPbgc_fcst_dailyOB01/

usage() {
  echo "Usage:  $0 --yrs 1993 [--yre 1999] [--mm 4] [--ens1 ...] [--ens2 ...] [...]"
  echo "  --yrs     start year to subset output fields"
  echo "  --yre     end year to subset forecast, default yre=yrs"
  exit 1
}

YR1=0
YR2=0
# Parse the command-line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --yrs) YR1=$2; shift 2 ;;
    --yre) YR2=$2; shift 2 ;;
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


PTHW=/work/Dmitry.Dukhovskoy/tmp/NEPbgc_fcst_dailyOB01
cd $PTHW || { echo "ERROR: Couldn't cd into $PTHW"; exit 1; }
pwd
for (( YR=$YR1; YR<=$YR2; YR+=1 )); do
  if [ -d ${YR} ]; then
    echo "Moving ${YR} --> $PTHCLB"
    mv ${YR} $PTHCLB/.
  fi
done

exit 0


