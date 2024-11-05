#!/bin/bash -x
#SBATCH --output=logs/%j.out
#
# unstage SPEAR ocean monthly fields before running python script
# First need to unstage the data 
# Then run python script
#  
# Usage:  [sbatch] unstage_spear_ocean.sh YR1 YR2 [mstart] ens 
# e.g.: unstage_spear_ocean.sh 1998 2010 1 - will unstage all months 1,4,7,10 for yrs 1998-2010 ens=1
#       unstage_spear_ocean.sh 1998 4 1  - will unstage 1998 month=4 ens=1
#       unstage_spear_ocean.sh 1998 1    - will unstage 1998 all months (1,4,7,10) ens=1
set -u

export DTMP=$TMPDIR
export WD=/work/Dmitry.Dukhovskoy/tmp/spear_subset/scripts
export DPYTH=/home/Dmitry.Dukhovskoy/python/setup_seasonal_NEP
export extrpy=extract_domain_spear.py

/bin/mkdir -pv $WD

if [[ $# < 2 ]]; then
  echo "usage: sbatch subset_spear_ocean.sh YR1 [YR2] [mstart] ens"
  exit 1
fi

SSH_DAY=1  # =0 : use monthly SSH
           # =1 : use daily SSH from ice_daily 
           # =2 : use daily SSH from ocean_daily - not avail for all years 

YR1=$1
YR2=$YR1
MONTHS=(1 4 7 10)
if [[ $# -gt 2 ]]; then
  if [[ $2 -gt 100 ]]; then
    YR2=$2
  else
    MONTHS=($2)
  fi
#  ens=$( echo $3 | awk '{printf("%02d",$1)}' )
  ens=$3
else 
  ens=$2
fi


echo "Extracting SPEAR monthly means for $YR1-$YR2 ensemble=$ens"

cd $WD

if [[ $SSH_DAY -gt 0 ]]; then
  day_ssh=True
  mo_ssh=False
else
  day_ssh=False
  mo_ssh=True
fi

for (( ystart=$YR1; ystart<=$YR2; ystart+=1 )); do
  for MS in ${MONTHS[@]}; do
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
    if [[ $SSH_DAY -eq 2 ]]; then
      DSSHDAY=$RT/${subdir1}/pp_ens_${nens}/ocean_daily/ts/daily/1yr
      ssh_prfx=ocean_daily
      fssh=ssh
    else
      ssh_prfx=ice_daily
      DSSHDAY=$RT/${subdir1}/pp_ens_${nens}/ice_daily/ts/daily/1yr
      fssh=SSH
    fi


  #  DTMPOUT=${DTMP}/${ystart}${mstart}/ens${nens}
  #  echo "TMP dir = $DTMPOUT"
  #  /bin/mkdir -pv $DTMPOUT
    cd $DOCN
    for varnm in so thetao vo uo; do
      flnm=$( ls ocean_z.${ystart}${mstart}-??????.${varnm}.nc ) 
      echo "unstaging $flnm"
      dmget $flnm
      #wait
  #    /bin/cp $flnm $DTMPOUT/.
    done

  # Monthly mean SSH:
    if [[ $SSH_DAY -eq 0 ]]; then
      cd $DICE
      flnm=$( ls ice.${ystart}${mstart}-??????.SSH.nc ) 
      echo "unstaging $flnm"
      dmget $flnm
    #  /bin/cp $flnm $DTMPOUT/. 
    #  wait
    fi

  # Daily SSH:
    if [[ $SSH_DAY -eq 1 ]]; then
      cd $DSSHDAY
      flnm=$( ls ${ssh_prfx}.${ystart}${mstart}01-????????.${fssh}.nc )
      echo "unstaging $flnm"
      dmget $flnm
    #  /bin/cp $flnm $DTMPOUT/. 
    #  wait
    fi

    echo "Staging finished ${ystart} ${MS} ${ens}"
  #  ls -lh $DTMPOUT/*.nc
  done
done 

echo "All Done"
exit 0


