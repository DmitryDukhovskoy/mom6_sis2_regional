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
  echo "  --dstr   date_start time string used in the MOM/SIS2 file names " 
  echo "  --exptn  2 "
  echo "  --curdir >0 - use current directory where arch files, =0 - use default dir "
  exit 1
}


export date_start=20010101
export enmb=2          # experiment number 
export expt_name=test_ice_relax
export DROOT=/archive/Dmitry.Dukhovskoy/fre/NEP/${expt_name}
export use_cwd=0


# Parse the command-line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --dstr)
      date_start=$2
      shift 2 # Move past the flag and its arg. to the next flag
      ;;
    --exptn)
      enmb=$2
      shift 2
      ;;
    --curdir)
      use_cwd=$2
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


YS=${date_start:0:4}
MS=${date_start:4:2}

expt_nmb=$( echo ${enmb} | awk '{printf("%02d", $1)}')
export SDIR=NEPphys_expt${expt_nmb}
export DARCH=${DROOT}/${SDIR}/${YS}-${MS}

if [[ $use_cwd -eq 1 ]]; then
  DARCH=$(pwd)
fi


echo "renaming files ${date_start}.*.nc from ${DARCH}"

cd $DARCH

# Get rid of the leading time stamp in the file names:
for FL in $( ls ${date_start}.*.nc ); do
  fldname=$( echo ${FL} | cut -d"." -f 2)
  echo "$FL ---> ${fldname}.nc"
  /bin/mv $FL ${fldname}.nc
done

exit 0
