#!/bin/bash -x
#
# Arrange ascii output files (log files, stat files) dumped from NEP MOM6-SIS2
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
export ADIR=restart  # this dummy var is used for sed from postprcs_fcst_dailyOB.sh
export expt_nmb=01 # forecast run experiment number or forecast group name 
export DARCH=/archive/Dmitry.Dukhovskoy/fre/${REG}/${EXPT}
export fend=1993-04-e01
export expt_name=NEPphys_frcst_dailyOB-expt${expt_nmb}
export DNEW=$DARCH/$expt_name/$fend

yr=$( echo $fend | cut -d"-" -f1 )
mstart=$( echo $fend | cut -d"-" -f2 )
ens=$( echo $fend | cut -d"-" -f3 )

echo "Processing restart for ${fend}"

ADIR=$DNEW/ascii
cd $ADIR

# Should be 1 tar with date stamp = next day of the end of the f/cast:
# Check if tar file  exists and only 1:
ntar=$( ls -l *.tar | wc -l )
if [[ $ntar -eq 0 ]]; then
  echo "tar file does not exist, skipping ..."
  exit 0
fi
if [[ $ntar -gt 1 ]]; then
  echo "Found >1 tar files in $ADIR"
  echo "ascii processing skipped ..."
  ls -l *.tar
  exit 0
fi

date_ascii=$( ls *.tar | cut -d"." -f1 )

echo "Processing run $fend, ascii $date_ascii" 
pwd

fascii_tar=${date_ascii}.ascii_out.tar
tar -xvf $fascii_tar
wait

/bin/rm -f *.logfile.*.out

pwd
ls -lh

echo "Removing $fascii_tar"
/bin/rm $fascii_tar

echo "ascii processing done"

exit 0
