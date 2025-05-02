#!/bin/bash
# Assumed file names: $fltmp${yrs}{yrs+nyrs-1}$flend
# Modify tamplate accordingly
set -u

fltmp=PIOMASv21_ithkn_iconc_
flend=_monthly.nc
nyrs=2            # numb of years in clim files
DG=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/NEP_data/forecast_input_data/sis2

usage() {
  echo "Usage: $0 --yrs 1993 [--yre 1999] [--nyrs 2]"
  echo "  --yrs    1st year to send to gaea"
  echo "  --yre    last year to send to gaea, default=yrs"
  echo "  --nyrs   number of years of processed fields in the file, default=${nyrs}"
  exit 1
}

if [[ $# < 1 ]]; then
  usage
fi

while [[ $# -gt 0 ]]; do
  case $1 in
    --yrs)
      YRS=$2
      YRE=$YRS
      shift 2
      ;;
    --yre)
      YRE=$2
      shift 2
      ;;
    --nyrs)
      nyrs=$2
      shift 2
      ;;
    *)
    echo "Error: Unrecognized option $1"
    usage
    ;;
  esac
done

if [[ -z "${YRS:-}" ]]; then
  echo "Error: --yrs is required."
  usage
fi

for (( yr1=$YRS; yr1<=$YRE; yr1+=1 )); do
  yr2=$(( yr1+nyrs-1 ))
  fl="$fltmp"${yr1}_${yr2}"$flend"  
  echo "$fl --> gaea:${DG}"
  gcp $fl  gaea:$DG/.
done

exit 0
