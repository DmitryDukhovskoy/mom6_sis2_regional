#!/bin/bash
# Extract cice files from HPSS
set -u 

YR=0
MM=0
DD=0

usage() {
  echo "Usage: $0 --yr 2025 --mm 7 --dd 2"
  echo "  --yr         init year"
  echo "  --mm         init month"
  echo "  --dd         init day"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --yr)
      YR=$2
      shift 2 # Move past the flag and its arg. to the next flag
      ;;
    --mm)
      MM=$2
      shift 2
      ;;
    --dd)
      DD=$2
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

if [[ $YR -eq 0 || $MM -eq 0 || $DD -eq 0 ]]; then
  usage
fi

MM=$(printf "%02d" "$MM")
DD=$(printf "%02d" "$DD")

vv=2.4
if [[ $YR -eq 2025 && $MM -ge 8 ]]; then
  vv=2.5
elif [[ $YR -eq 2025 && $MM -eq 7 && $DD -ge 29 ]]; then
  vv=2.5
elif [[ $YR -gt 2025 ]]; then
  vv=2.5
fi

DCICE="/NCEPPROD/1year/hpssprod/runhistory/rh${YR}/${YR}${MM}/${YR}${MM}${DD}"
FTAR="com_rtofs_v${vv}_rtofs.${YR}${MM}${DD}.nc.tar"
DOUTP="/scratch4/NCEPDEV/stmp/Dmitry.Dukhovskoy/RTOFS_CICE4/${YR}${MM}${DD}"

mkdir -pv $DOUTP
cd "$DOUTP" || { echo "Could not cd to ${DOUTP}"; exit 1; }
pwd

for ihr in 00 24 48 72 96 120 144 168 192; do
  if [[ $ihr == 00 ]]; then
    fcice="rtofs_glo.t00z.n${ihr}.cice_inst.nc"
  else
    fcice="rtofs_glo.t00z.f${ihr}.cice_inst.nc"
  fi
  echo "Extracting $fcice"
  echo "htar -xvf ${DCICE}/${FTAR} ./${fcice}"
  htar -xvf ${DCICE}/${FTAR} ./${fcice} 
done

echo "ALL done"

exit 0
