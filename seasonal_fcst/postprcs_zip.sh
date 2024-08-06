#!/bin/bash -x
#
# Run this script after running postprcs_arch.sh 
# zip ice/ocean output history files grouped by months
# No annual mean files here
# zip 1 ensemble run and 1 year at a time
#
# Rename output files dumped from NEP MOM6-SIS2
# from gaea to PPAN archive
#
# Untar output file, separate ocean and ice files, groupd by months
# and zip them
#
# Assumed file naming is YYYYMMDD.oceanm_YYYY_DDD.nc
# File structure should follow a pattern 
#
# Usage: postprcs_zip.sh yearstart monthstart ensemble
set -u

export REG=NEP
export EXPT=seasonal_ensembles
export DARCH=/archive/Dmitry.Dukhovskoy/fre/${REG}/${EXPT}
export PLTF="gfdl.ncrc5-intel22-repro"
export oprfx=oceanm
export iprfx=icem
export DAWK=/home/Dmitry.Dukhovskoy/scripts/awk_utils

if [[ $# < 3 ]]; then
  echo "ERROR: specify year month and ensemle run"
  echo "usage: [sbatch] postprcs_zip.sh yrstart mostart ens"
  exit 1
fi

YR=$1
mstart=$( echo $2 | awk '{printf("%02d",$1)}' )
nens=$( echo $3 | awk '{printf("%02d",$1)}' ) 

echo "zipping ocean ice outputs for $YR ensemble $nens"
cd $DARCH
for dens in $( ls -d *${YR}--e${nens} ); do
  fend=$( echo $dens | cut -d"_" -f4 )
#  mstart=$( echo $fend | cut -d"-" -f2 )
#  ens=$( echo $fend | cut -d"-" -f3 )
#
  HSTDIR=$DARCH/$dens/$PLTF/history
  cd $HSTDIR

# Check if this dir has been preprocessed and files have been groupped by months
  nidir=$( ls -1 | grep ${iprfx} | wc -l )
  nodir=$( ls -1 | grep ${oprfx} | wc -l )

  if ! [[ $nidir -gt 0 ]] || ! [[ $nodir -gt 0 ]]; then
     pwd
     ls -l
     echo " $YR $mstart ens=$ens - no monthly dir found for ice/ocean, skipping "
     continue
  fi
#
# MOM6
  for fdir in $( ls -d ${oprfx}_* ); do
    cd $HSTDIR/$fdir
    ocn_tar=$fdir

    nfls=$( ls -l ${oprfx}*.nc | wc -l )
    echo "${oprfx}: tarring $nfls files"
    /bin/rm -f ${ocn_tar}*
    /bin/tar -czvf ${ocn_tar}.tar.gz ${oprfx}*.nc
    wait
 
    /bin/mv ${ocn_tar}.tar.gz $HSTDIR/.
  done
# SIS
  cd $HSTDIR
  for fdir in $( ls -d ${iprfx}_* ); do
    cd $HSTDIR/$fdir
    ice_tar=$fdir

    nfls=$( ls -l ${iprfx}*.nc | wc -l )
    echo "${iprfx}: tarring $nfls files"
    /bin/rm -f ${ice_tar}*
    /bin/tar -czvf ${ice_tar}.tar.gz ${iprfx}*.nc
    wait
 
    /bin/mv ${ice_tar}.tar.gz $HSTDIR/.
  done

# Remove unneeded dirs/files:
  cd $HSTDIR
  for ftar in $( ls *.tar.gz ); do
    fdir=$( echo $ftar | cut -d"." -f 1 )
    echo "$ftar created, removing $fdir"
    /bin/rm -rf $fdir
  done

  echo "Test stoppage"
  exit 5
done

echo "All Done"

exit 1

    


