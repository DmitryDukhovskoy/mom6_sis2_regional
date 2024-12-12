#!/bin/bash 
# 
# Assumed file naming is YYYYMMDD.oceanm_YYYY_DDD.nc
# File structure should follow a pattern 
# rename YYYYMMDD.oceanm_YYYY_DDD.nc ---> oceanm_YYYY_DDD.nc
#
# Usage:
set -u

export date_start=19930401
export DARCH=/work/Dmitry.Dukhovskoy/run_output/NEP_ISPONGE/1993/04
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
