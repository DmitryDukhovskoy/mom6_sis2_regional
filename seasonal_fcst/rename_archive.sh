#!/bin/bash 
# 
# Assumed file naming is YYYYMMDD.oceanm_YYYY_DDD.nc
# File structure should follow a pattern 
# rename YYYYMMDD.oceanm_YYYY_DDD.nc ---> oceanm_YYYY_DDD.nc
#
# Usage: rename_archive.sh -d <YYYYMMDD> -e <1,... expt nmb> [-c - use current dir]
#  ./rename_archive.sh -c   will rename file in the current dir ignoring default expt_nmb
#
set -u

export date_start=19930401
export enmb=3          # experiment number 
export YS=1993         # f/cast initialization year
export MS=04           # f/cast initialization month
export expt_name=test_ice_relax
export DROOT=/archive/Dmitry.Dukhovskoy/fre/NEP/${expt_name}
export use_cwd=0

while getopts "d:e:c" opt; do
  case $opt in
    d)
      date_start="$OPTARG"
      ;;
    e) 
      enmb="$OPTARG"
      ;;
    c)
      use_cwd=1
      ;;
    *)
      echo "unrecognized option / flag"
      echo "Usage $0 -d <YYYYMMDD> -e<expt number> [-c flag to use current dir]"
      exit 1
      ;;
  esac
done

expt_nmb=$( echo ${enmb} | awk '{printf("%02d", $1)}')
export SDIR=NEPphys_expt${expt_nmb}
export DARCH=${DROOT}/${SDIR}/${YS}-${MS}

if [[ $use_cwd -eq 1 ]]; then
  DARCH=$(pwd)
fi


echo "renaming files ${date_start}.*.nc from ${DARCH}"

export oprfx=oceanm
export iprfx=icem
export DAWK=/home/Dmitry.Dukhovskoy/scripts/awk_utils

cd $DARCH

# Get rid of the leading time stamp in the file names:
for FL in $( ls ${date_start}.*.nc ); do
  fldname=$( echo ${FL} | cut -d"." -f 2)
  echo "$FL ---> ${fldname}.nc"
  /bin/mv $FL ${fldname}.nc
done

exit 0
