#!/bin/bash
#
# Merge converted DATM individual files
#

set -eu

module load nco/5.2.4

YS=""
YE=""
fixpr=1  # correct negative precip

usage() {
  echo "Usage: $0 [--ys YYYY] [--ye YYYY] ..."
  echo "  --ys    start year, default - all years in DATM dir"
  echo "  --ye    end year, ignore if ys is not specified, default = ys"
  echo "  --fixpr =1: fix negative precipitation, =0 - not, default ${fixpr}"
  exit 1
}

make_record() {
  local flname=$1
  local rec=$2
  local bname="${flname%.nc}"

  ncks --mk_rec_dmn time "$flname" "${bname}_${rec}.nc"
  echo "${flname} --> ${bname}_${rec}.nc" >&2    # do not send to stand. output

  local datestamp="${bname#*.}" 
  echo "$datestamp"
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --ys)
      YS=$2
      shift 2
      ;;
    --ye)
      YE=$2
      shift 2
      ;;
    --fixpr)
      fixpr=$2
      shift 2
      ;;
    --help)
      usage
      ;;
    *)
    echo "ERR: Unrecognized option $1"
    usage
    ;;
  esac
done

if [[ ! -z $YS ]] && [[ -z $YE ]]; then
  YE=$YS
fi

sfx=gfs
DATM="/scratch4/NCEPDEV/stmp/${USER}/datm_forcing/DATM/GFS2DATM"

cd ${DATM} || { echo "ERR: failed cd to ${DATM}"; exit 1; }
pwd

rm -rf ${sfx}.??????????_*.nc
rm -rf ${sfx}.*_*.nc.*.tmp

rec=1
if [[ -z $YS ]]; then
  echo "ys and ye not specified: Merging all ${sfx}.*.nc in ${DATM}"
  for fl in ${sfx}.??????????.nc; do
    dstamp=$(make_record "$fl" "$rec")
    [[ $rec -eq 1 ]] && dstamp1=$dstamp
    rec=$(( rec + 1 ))
  done
else
  echo "Merging ${sfx}.*.nc for ${YS}-${YE} in ${DATM}"
  for (( YR=$YS; YR<=$YE; YR++)); do
    flsyr=( ${sfx}.${YR}??????.nc )
    if (( ${#flsyr[@]} == 0 )); then
      echo "No files for ${YR}, skipping..."
      continue
    fi

    for fl in ${sfx}.${YR}??????.nc; do
      dstamp=$(make_record "$fl" "$rec")
      [[ $rec -eq 1 ]] && dstamp1=$dstamp
      rec=$(( rec + 1 ))
    done
  done
fi

flout="${sfx}.${dstamp1}_${dstamp}.merged.nc"
flmrg=merged.nc
rm -rf $flout ${flmrg} ${flmrg}_*

echo "Merging files by record concatenating --> ${flmrg}"
ncrcat ${sfx}.??????????_*.nc "$flmrg"

rm -rf ${sfx}.??????????_?.nc
rm -rf ${sfx}.??????????_??.nc

if [[ $fixpr -eq 0 ]]; then
  echo "WARNING: Negative precip: No precip correction"
  echo "${flmrg} --> ${flout}"
  mv ${flmrg} ${flout}
  touch merged_precip_notcrcted
else
  echo "Correcting negative precipitation  ---> ${flout}"
  cd $DATM

  ncap2 -s 'where(fprecp<0.) fprecp=0.;' ${flmrg} -O ${flout}
  status=$?

  if [[ $status -eq 0 ]]; then
    touch merged_precip_corrected
  else
    echo "Failed to correct precip ${status}"
    exit 1
  fi
fi

rm -rf ${flmrg}

echo "All Done"

exit 0

