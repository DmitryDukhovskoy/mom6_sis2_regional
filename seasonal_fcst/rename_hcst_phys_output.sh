#!/bin/bash 
# 
# Assumed file naming is YYYYMMDD.oceanm_YYYY_DDD.nc
# File structure should follow a pattern 
# rename YYYYMMDD.oceanm_YYYY_DDD.nc ---> oceanm_YYYY_DDD.nc
#
#
set -u

usage() {
  echo "Usage: $0 --dstr 19941201 --exptn 2 [--curdir 1] "
  echo "  --yr   year of the model run to process"
  echo "  --curdir >0 - use current directory where arch files, =0 - use default dir "
  exit 1
}

regn='NEP'
YR=0
export expt_name=NEPphys_nonudg_irlx_hcast # h/cast no GLORSY nudg but IRLX is on

export use_cwd=0

# Parse the command-line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --curdir)
      use_cwd=$2
      shift 2
      ;;
    --yr)
      YR=$2
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

if [[ $YR -eq 0 ]]; then
  echo "ERR: specify YR"
  usage
fi

echo "Renaming files for ${regn}"

DARCH=/archive/Dmitry.Dukhovskoy/fre/NEP/hindcast_phys/NEPphys_nonudg_irlx_hcast/${YR}

if [[ $use_cwd -eq 1 ]]; then
  DARCH=$(pwd)
fi

date_start=${YR}0101
echo "renaming files ${date_start}.*.nc from ${DARCH}"

cd $DARCH

# Get rid of the leading time stamp in the file names:
for FL in $( ls ${date_start}.*.nc ); do
  fldname=$( echo ${FL} | cut -d"." -f 2)
  echo "$FL ---> ${fldname}.nc"
  /bin/mv $FL ${fldname}.nc
done

exit 0
