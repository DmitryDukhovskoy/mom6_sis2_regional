#!/bin/bash 
#  link history or restart directories between the hindcasts 
#  asuumed similar dir structure
#
set -u


MONTHS=(1 4 7 10) # initialization months
YR1=0
YR2=0
sfx=""

usage() {
  echo "Usage: $0 --ys 1994 --ye 1994"
  echo "  --ys          start with this init year to pprcs the f/cast <-- Required" 
  echo "  --ye          end with this f/cast init year, default=same as ys"
  echo "  --ms      month to start the f/cast, default: 1,4,7,10" 
  echo "  --sfx     prefix in the dir naming, e.g. restdate_, default - none"
  echo "  --fld     hist or rest for history dir or restart dir"
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
    --fld)
      fld="$2"
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

if [[ -z ${fld} ]]; then
  echo "ERR: Specify fld as hist or rest"
  usage
fi

if [[ "$fld" == "hist" ]]; then
  dirname="history"
elif [[ "$fld" == "rest" ]]; then
  dirname="restart"
fi

DEPNT="/archive/Dmitry.Dukhovskoy/fre/NEP/hindcast_bgc/NEPbgc_nudged_hindcast02/${dirname}"
DTRGT="/archive/Dmitry.Dukhovskoy/fre/NEP/hindcast_bgc/NEPbgc_nudged_hindcast03/${dirname}"

cd ${DEPNT} || { echo "Cannot access $DEPNT"; exit 1; }
pwd

for (( yr=$YR1; yr<=$YR2; yr+=1 )); do
  for mo in ${MONTHS[@]}; do
    mo0=$(printf "%02d" "$mo")
    drold="${sfx}${yr}${mo0}01"
    drnew=$drold

    if [ -d "$drnew" ]; then
      echo "${drnew} exists, skipping ..."
      continue
    fi

    echo "Linking ${DTRGT}/${drold}"
    ln -s ${DTRGT}/${drold} ${drnew}

  done
done


exit 0


