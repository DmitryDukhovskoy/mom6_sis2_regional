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
# Usage: ./prepare_restart_fcst.sh YR1 [YR2 ]
# if YR2 is missing then YR2=YR1
#  
set -u

export expt=NEP_physics_202404_nudging-15d

export DARCH=/archive/${USER}/fre/NEP/2024/${expt}/gfdl.ncrc5-intel22-repro/restart
export DOUT=/gpfs/f5/cefi/scratch/${USER}/NEP_data/forecast_input_data/restart
#export DTMP=/work/Dmitry.Dukhovskoy/run_output/NEP_BGCphys/dump
DTMP=$TMPDIR

echo "DTMP: $DTMP"

if [[ $# < 1 ]]; then
  echo "usage: ./prepare_restart_fcst.sh YR1 [YR2 ]"
  echo " Start/end years are missing"
  exit 1
fi

YR1=$1
if [[ $# == 1 ]]; then
  YR2=$YR1
else
  YR2=$2
fi 

mkdir -pv $DTMP
cd $DTMP
# make sure no left-over restart files in the dir:
pwd
rm -rf *.tar
rm -rf MOM.res.*.nc ice_model.res.nc

yr=$YR1
while [ $yr -le $YR2 ]; do
  for (( mo=10; mo<=12; mo+=3 )); do
    if (( 10#$yr == 1993 )) && (( 10#$mo == 1 )); then
      continue
    fi
    mo0=`echo ${mo} | awk '{printf("%02d", $1)}'`
    ftar=${yr}${mo0}01.tar

    rm -rf *.tar
    rm -rf MOM.res.*.nc ice_model.res.nc
    echo "Fetching $DARCH/$ftar ..."
    /bin/cp $DARCH/$ftar .
    wait

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
    wait

  done
  yr=$((yr + 1))
  echo "yr=$yr"

done

exit 0 

