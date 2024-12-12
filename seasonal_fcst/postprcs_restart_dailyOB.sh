#!/bin/bash 
#
# Rename output files dumped from NEP MOM6-SIS2
# from gaea to PPAN archive
#
# Assumed file naming is YYYYMMDD.oceanm_YYYY_DDD.nc
# File structure should follow a pattern 
# Restart and outher output fields should be moved to
#
# seasonal_daily/NEPphys_frcst_dailyOB-expt01/YYYY-MM-eXX/{restart, ascii, history}
#
# This script is called from postprcs_fcst_dailyOB.sh
#
set -u

export REG=NEP
export EXPT=seasonal_daily
export PLTF=gfdl.ncrc5-intel23-repro
export RSTDIR=restart  # this dummy var is used for sed from postprcs_fcst_dailyOB.sh
export expt_nmb=01 # forecast run experiment number or forecast group name 
export DARCH=/archive/Dmitry.Dukhovskoy/fre/${REG}/${EXPT}
#export yr=1993
#export mstart=04
#export ens=e01
export fend=1993-04-e01
export expt_name=NEPphys_frcst_dailyOB-expt${expt_nmb}
export DNEW=$DARCH/$expt_name/$fend

yr=$( echo $fend | cut -d"-" -f1 )
mstart=$( echo $fend | cut -d"-" -f2 )
ens=$( echo $fend | cut -d"-" -f3 )

echo "Processing restart for ${fend}"

RSTDIR=$DNEW/restart
cd $RSTDIR

# Should be 1 tar with date stamp = next day of the end of the f/cast:
# Check if tar file  exists and only 1:
ntar=$( ls -l ????????.tar | wc -l )
if [[ $ntar -eq 0 ]]; then
  echo "tar file does not exist, skipping ..."
  exit 0
fi
if [[ $ntar -gt 1 ]]; then
  echo "Found >1 tar files in $RSTDIR"
  echo "restart processing skipped ..."
  ls -l *.tar
  exit 0
fi

# Restart date from tar name:
#if [[ $ntar -eq 1 ]]; then
date_restart=$( ls *.tar | cut -d"." -f1 )

echo "Processing run $fend, restart $date_restart" 
pwd

frest_tar=${date_restart}.tar
tar -xvf $frest_tar
wait

fmomres=MOM.res.${date_restart}-${ens}.nc
fsisres=SIS.res.${date_restart}-${ens}.nc

echo "MOM.res.nc --> $fmomres"
/bin/mv MOM.res.nc $fmomres

echo "ice_model.res.nc --> $fsisres"
/bin/mv ice_model.res.nc $fsisres

echo "Compressing $fmomres"
/bin/rm -f $fmomres.gz
gzip $fmomres
wait

echo "Compressing $fsisres"
/bin/rm -f $fsisres.gz
gzip $fsisres
wait

pwd
ls -lh

if [ -s $fmomres.gz ] && [ -s $fsisres.gz ]; then
  echo "Removing $frest_tar"
  /bin/rm $frest_tar
fi

echo "restart processing done"

exit 0
