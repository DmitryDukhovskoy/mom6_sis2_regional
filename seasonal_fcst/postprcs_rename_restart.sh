#!/bin/bash -x
#
# Rename output files dumped from NEP MOM6-SIS2
# from gaea to PPAN archive
#
# Assumed file naming is YYYYMMDD.oceanm_YYYY_DDD.nc
# File structure should follow a pattern 
#
# Usage:
set -u

export REG=NEP
export EXPT=seasonal_ensembles
export DARCH=/archive/Dmitry.Dukhovskoy/fre/${REG}/${EXPT}
export PLTF="gfdl.ncrc5-intel22-repro"

if [[ $# < 1 ]]; then
  echo "ERROR: specify year to start/end"
  echo "usage: [sbatch] postprcs_rename_restart.sh YR1 [YR2]"
  exit 1
fi
 
YR1=$1
if [[ $# == 1 ]]; then
  YR2=$YR1
else
  YR2=$2
fi

echo "Processing outputs for $YR1-$YR2"

for (( yr=$YR1; yr<=$YR2; yr+=1 )); do
  cd $DARCH
  for dens in $( ls -d *${yr}-??-e?? ); do
    fend=$( echo $dens | cut -d"_" -f4 )
    mstart=$( echo $fend | cut -d"-" -f2 )
    ens=$( echo $fend | cut -d"-" -f3 ) 
    date_start=${yr}${mstart}01
#
    cd $DARCH/$dens/$PLTF/restart
# Restart date from tar name:
    date_restart=$( ls *.tar | cut -d"." -f1 )

    echo "Processing run $fend, restart $date_restart" 
    pwd

    frest_tar=${date_restart}.tar

    if ! [ -s $frest_tar ]; then
      echo "$frest_tar does not exist, skipping ..."
      continue
    fi

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

#    exit 5 
  done
done

echo "All done"

exit 0
