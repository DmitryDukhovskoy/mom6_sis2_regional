#!/bin/bash -x
#SBATCH --output=logs/%j.out
#
# Subset SPEAR ocean monthly fields for a specified domain
# First need to unstage the data 
# Then run python script
#  
# Usage:  sbatch subset_spear_ocean.sh YR1 YR2 mstart ens 
# e.g.: sbatch subset_spear_ocean.sh 1998 2010 1 1
set -u

module load python/3.9 gcp

export DTMP=$TMPDIR
export WD=/work/Dmitry.Dukhovskoy/tmp/spear_subset/scripts
export DPYTH=/home/Dmitry.Dukhovskoy/python/setup_seasonal_NEP
export extrpy=extract_domain_spear.py

/bin/mkdir -pv $WD

if [[ $# < 4 ]]; then
  echo "usage: sbatch subset_spear_ocean.sh YR1 YR2 mstart ens"
  exit 1
fi

YR1=$1
YR2=$2
MS=$3
ens=$4

echo "Extracting SPEAR monthly means for $YR1-$YR2 month_start=$MS ensemble=$ens"

cd $WD

for (( ystart=$YR1; ystart<=$YR2; ystart+=1 )); do

# Find the directory to SPEAR post-processed forecast output on archive
  RT=/archive/l1j/spear_med/rf_hist/fcst/s_j11_OTA_IceAtmRes_L33
  mstart=$(echo ${MS} | awk '{printf("%02d",$1)}')
  subdir1=i${ystart}${mstart}01_OTA_IceAtmRes_L33
  if (( $ystart == 2020 )); then
    subdir1=${subdir1}_rerun
  elif ((( $ystart >= 2015  && $ystart <=2019 ) || $ystart == 2021 )); then
    subdir1=${subdir1}_update
  fi

  nens=$(echo ${ens} | awk '{printf("%02d",$1)}')
  DOCN=$RT/${subdir1}/pp_ens_${nens}/ocean_z/ts/monthly/1yr
  DICE=$RT/${subdir1}/pp_ens_${nens}/ice/ts/monthly/1yr

  DTMPOUT=${DTMP}/${ystart}/ens${nens}
  echo "TMP dir = $DTMPOUT"
  /bin/mkdir -pv $DTMPOUT
  cd $DOCN
  for varnm in so thetao vo uo; do
    flnm=$( ls ocean_z.${ystart}${mstart}-??????.${varnm}.nc ) 
    echo "unstaging $flnm"
    dmget $flnm
    wait
    /bin/cp $flnm $DTMPOUT/.
  done

  cd $DICE
  flnm=$( ls ice.${ystart}${mstart}-??????.SSH.nc ) 
  echo "unstaging $flnm"
  dmget $flnm
  /bin/cp $flnm $DTMPOUT/. 
  wait

  echo "Staging finished"
  ls -lh $DTMPOUT/*.nc
    
# ================
#   Data subsetting 
# ================
  cd $WD
  pwd
  /bin/cp $DPYTH/*.py .
  /bin/cp $DPYTH/config_nep.yaml .
  fexe=run_extr_${ystart}${mstart}.py
  /bin/rm -rf $fexe

  sed -e "s|^pthtmp[ ]*=.*|pthtmp = '${DTMP}'|"\
      -e "s|^tmpdir[ ]*=.*|tmpdir = '${DTMPOUT}'|"\
      -e "s|^YR[ ]*=.*|YR = ${ystart}|"\
      -e "s|^mstart[ ]*=.*|mstart = ${MS}|"\
      -e "s|^ens[ ]*=.*|ens = ${ens}|" $extrpy > $fexe

  chmod 750 $fexe
  python $fexe
  wait

done 

echo "All Done"
exit 0


