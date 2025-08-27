#!/bin/bash
#
# restart files for SIS2, MOM6, COBALT prepared during
# NEP BGC hindcast 1993-2023
# restarts were saved very 3 months
#
# Specify start/end years within the model run time period
# for which the restart files need to be transferred to Gaea
#
# Usage: ./restart_fcst2gaea.sh YR1 [YR2 ] [M1] 
# if YR2 is missing then YR2=YR1
#  
set -u

export expt=NEPbgc_nudged_hindcast02
export DARCH=/archive/Dmitry.Dukhovskoy/fre/NEP/hindcast_bgc/${expt}/restart
export DOUT=/gpfs/f6/ira-cefi/scratch/Dmitry.Dukhovskoy/NEP_data/forecast_input_data/restart_bgc/seas_fcast
DTMP=$TMPDIR

echo "DTMP: $DTMP"

usage() {
  echo "Usage: $0 --ys 1994 --ye 1994 --ms 7 --me 10"
  echo "  --ys          restart year to begin the transfer"
  echo "  --ye          last restart year to transfer default=same as ys"
  echo "  --ms          1st restart month in each year to transfer, default=1"
  echo "  --me          last restart month in each year to transfer, default=10"
  exit 1
}

YR1=0
YR2=0
M1=0
M2=0
dltM=3
# input with key arguments:
# Parse the command-line arguments
while [ $# -gt 0 ]; do
  case $1 in
    --ys)
      YR1=$2
      shift 2 # Move past the flag and its arg. to the next flag
      ;;
    --ye)
      YR2=$2
      shift 2
      ;;
    --ms)
      M1=$2
      shift 2
      ;;
    --me)
      M2=$2
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

if [[ $YR1 -eq 0 ]]; then
  echo "YR1 is required YR1=$YR1"
  usage
fi
if [[ $YR2 -eq 0 ]]; then
  YR2=$YR1
fi
if [[ ${M1} -eq 0 ]]; then
  M1=1
fi
if [[ ${M2} -eq 0 ]]; then
  M2=10
fi

#echo "M1=$M1 M2=$M2"

mkdir -pv $DTMP
cd $DTMP
# make sure no left-over restart files in the dir:
pwd
rm -rf *.tar
rm -rf MOM.res.*.nc ice_model.res.nc

yr=$YR1
for (( yr=$YR1; yr<=$YR2; yr+=1 )); do
  for (( mo=$M1; mo<=$M2; mo+=dltM )); do
    mo0=`echo ${mo} | awk '{printf("%02d", $1)}'`
    rdate=${yr}${mo0}01
    RSTDIR=${DARCH}/restdate_${rdate}
    cd $RSTDIR || { echo "Missing directory: $RSTDIR"; continue; }
    pwd
   
    for fl in $( ls *${rdate}.res* ); do 
      echo "Transferring ${fl} --> gaea:${DOUT}/restdate_${rdate}"
      gcp -cd $fl  gaea:${DOUT}/restdate_${rdate}/
    done

  done
done

exit 0 

