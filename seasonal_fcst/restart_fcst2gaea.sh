#!/bin/bash -x
#
# prepare restart files used for seasonal forecasts
# from existing tar files saved on archive server
# transfer these files to gaea 
# restart files are saved every 3 months for 1993 - 2020
#
# Specify start/end years within the model run time period
# for which the restart files need to be transferred to Gaea
#
# Usage: ./restart_fcst2gaea.sh YR1 [YR2 ] [M1] 
# if YR2 is missing then YR2=YR1
#  
set -u

export expt=NEP_physics_202404_nudging-15d

export DARCH=/archive/${USER}/fre/NEP/2024/${expt}/gfdl.ncrc5-intel22-repro/restart
export DOUT=/gpfs/f5/cefi/scratch/${USER}/NEP_data/forecast_input_data/restart
#export DTMP=/work/Dmitry.Dukhovskoy/run_output/NEP_BGCphys/dump
DTMP=$TMPDIR

echo "DTMP: $DTMP"

if [[ $# -lt 1 ]]; then
  echo "usage: ./restart_fcst2gaea.sh YR1 [YR2] [MM]"
  echo " Start/end years are missing"
  exit 1
fi

YR1=$1
YR2=$YR1
M1=1
M2=12
if [[ $# -eq 1 ]]; then
  YR2=$YR1
fi
if [[ $# -eq 2 ]]; then
  if [[ $2 -gt 100 ]]; then
    YR2=$2
  else
    YR2=$YR1
    M1=$2
    M2=$M1
  fi
fi 

if [[ $# -eq 3 ]]; then
  YR2=$2
  M1=$3
  M2=$M1
fi 
M1=$( echo $M1 | awk '{printf("%02d", $1)}' )
M2=$( echo $M2 | awk '{printf("%02d", $1)}' )


mkdir -pv $DTMP
cd $DTMP
# make sure no left-over restart files in the dir:
pwd
rm -rf *.tar
rm -rf MOM.res.*.nc ice_model.res.nc

yr=$YR1
for (( yr=$YR1; yr<=$YR2; yr+=1 )); do
  for (( mo=$M1; mo<=$M2; mo+=3 )); do
    if (( 10#$yr == 1993 )) && (( 10#$mo == 1 )); then
      continue
    fi
    mo0=`echo ${mo} | awk '{printf("%02d", $1)}'`
    ftar=${yr}${mo0}01.tar

    rm -rf *.tar
    rm -rf MOM.res.*.nc ice_model.res.nc

    if [ -s $DARCH/$ftar ]; then 
      echo "Fetching $DARCH/$ftar ..."
      /bin/cp $DARCH/$ftar .
    else
      echo "Does not exist $DARCH/$ftar, skipping ..."
      continue
    fi

    momr=MOM.res.nc
    sisr=ice_model.res.nc
    tar xvf $ftar ./$momr ./$sisr
    wait
    /bin/ls -l

#    ftar_out=restart_${yr}-${mo0}.tar
#    /bin/rm -rf $ftar_out
#    tar cvf $ftar_out $momr $sisr
#    wait 

#    gcp $ftar_out gaea:$DOUT/${yr}${mo0}/
# gcp --batch only on gaea 

    gcp -cd $momr gaea:$DOUT/${yr}${mo0}/
    gcp -cd $sisr gaea:$DOUT/${yr}${mo0}/
#    wait

  done
done

exit 0 

