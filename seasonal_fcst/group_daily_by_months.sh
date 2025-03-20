#!/bin/bash
# 
# Group daily ocean ice fields in the directory by months
# and move them into monthly dirs
# Usage: group_daily_by_months.sh  [0], 0 - use current dir as the output dir
#
# !!! The script has not been tested !!!
#
set -u

export date_start=19930401
export DARCH=/work/Dmitry.Dukhovskoy/run_output/NEP_ISPONGE/1993/04
export DAWK=/home/Dmitry.Dukhovskoy/scripts/awk_utils
export SRCD=/home/Dmitry.Dukhovskoy/scripts/seasonal_fcst
export oprfx=oceanm    # ocean daily fields naming
export iprfx=icem      # ice daily fields naming

if [[ $# -eq 0 ]]; then
  DARCH=$(pwd)
fi

function get_month_mday {
  local FL=$1
  local bname=$( echo ${FL} | cut -d"." -f 1 )
  local year=$( echo ${bname} | cut -d "_" -f 2 )
  local jday=$( echo ${bname} | cut -d "_" -f 3 )
# Assign values to global variables:
  YY=$year
  MM=`echo "YRDAY2MDAY" | awk -f ${DAWK}/dates.awk y01=$YY d01=$jday | awk '{printf("%02d",$2)}'`
  mday=`echo "YRDAY2MDAY" | awk -f ${DAWK}/dates.awk y01=$YY d01=$jday | awk '{printf("%02d",$3)}'`
}

cd $DARCH

# Check renamed daily files but not yet grouped:
nfls=$( ls -l {${oprfx},${iprfx}}*.nc | wc -l )
if [[ $nfls -eq 0 ]]; then
  echo "No daily output files found, $nfls, skipping ${fend} ..."
  pwd
  exit 0
fi
# group daily ocean archive files by months 
for FL in $( ls ${oprfx}_*.nc ); do
  get_month_mday ${FL}

  DOUT=oceanm_${YY}${MM}
  if [ ! -d $DOUT ]; then
    /bin/mkdir -pv ${DOUT}
  fi
  echo "Moving $FL ---> ${DOUT}"
  /bin/mv $FL $DOUT/.
done

for FL in $( ls ${iprfx}_*.nc ); do
  get_month_mday ${FL}

  DOUT=icem_${YY}${MM}
  if [ ! -d $DOUT ]; then
    /bin/mkdir -pv ${DOUT}
  fi
  echo "Moving $FL ---> ${DOUT}"
  /bin/mv $FL $DOUT/.
done

exit 0


