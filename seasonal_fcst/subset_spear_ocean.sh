#!/bin/bash -x
#SBATCH --output=logs/%j.out
#
# Subset SPEAR ocean monthly fields for a specified domain
# First need to unstage the data 
# Then run python script
#   
# Change SSH_MO=1 for using monthly SSH to 0 for skipping monthly ssh
# SSH_DAY=1 for using daily SSH
#
# usage: sbatch subset_spear_ocean.sh YR1 [YR2] [MM] ens
#         subset_spear_ocean.sh YR1 ens - will generate OBs for init YR1 all months Jan, Apr, .., and ens run = ens
#         subset_spear_ocean.sh YR1 YR2 ens - will generate OBs for init YR1-YR2 and ens run = ens
#         subset_spear_ocean.sh YR1 MM ens - will generate OBs for init YR1 month=MM and ens run = ens
#
# run ipython on login node
# e.g.: subset_spear_ocean.sh 1998 2010 1 1
set -u

if module list | grep "python"; then
  echo "python loaded"
else
  module load python/3.11
fi

#module list
eval "$($PYPATH/bin/conda shell.bash hook)"
conda activate anls


export DTMP=$TMPDIR
export WD=/work/Dmitry.Dukhovskoy/tmp/spear_subset/scripts
export DPYTH=/home/Dmitry.Dukhovskoy/python/setup_seasonal_NEP
export extrpy=extract_domain_spear.py
export extrdaypy=extract_domain_spear_sshdaily.py

/bin/mkdir -pv $WD

if [[ $# < 2 ]]; then
  echo "at least init year and ens should be specified"
  echo "usage: sbatch subset_spear_ocean.sh YR1 [YR2] [MM] ens" 
  exit 1
fi

SSH_MO=0   # =1 : use monthly SSH
SSH_DAY=1  # =1 : use daily SSH from ice_daily 
#          # =2 : use daily SSH from ocean_daily - not avail for all years 
YR1=$1
YR2=$YR1
MONTHS=(1 4 7 10)
#ens=$( echo $2 | awk '{printf("%02d",$1)}' )
ens=$2

if [[ $# -gt 2 ]]; then
  if [[ $2 -gt 100 ]]; then
    YR2=$2
  else
    MONTHS=($2)
  fi
#  ens=$( echo $3 | awk '{printf("%02d",$1)}' )
  ens=$3
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
  echo "Starting year=${ystart} for ens run${ens}"
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

    DTMPOUT=${DTMP}/${ystart}${mstart}/ens${nens}
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

    if [[ $SSH_MO -eq 1 ]]; then
      cd $DICE
      flnm=$( ls ice.${ystart}${mstart}-??????.SSH.nc ) 
      echo "unstaging $flnm"
      dmget $flnm
      /bin/cp $flnm $DTMPOUT/. 
      wait
    fi

  # Daily SSH:
    if [[ $SSH_DAY -gt 0 ]]; then
      cd $DSSHDAY
      flnm=$( ls ${ssh_prfx}.${ystart}${mstart}01-????????.${fssh}.nc )
      echo "unstaging $flnm"
      dmget $flnm
      /bin/cp $flnm $DTMPOUT/. 
      wait
    fi

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
        -e "s|^f_ssh[ ]*=.*|f_ssh = ${mo_ssh}|"\
        -e "s|^mstart[ ]*=.*|mstart = ${MS}|"\
        -e "s|^ens[ ]*=.*|ens = ${ens}|" $extrpy > $fexe

    chmod 750 $fexe
  #  python $fexe
    ipython $fexe
    wait

    if [[ $SSH_DAY -gt 0 ]]; then
      cd $WD
      pwd
      fexeday=run_extrday_${ystart}${mstart}.py
      /bin/rm -rf $fexeday
       
      sed -e "s|^pthtmp[ ]*=.*|pthtmp = '${DTMP}'|"\
          -e "s|^tmpdir[ ]*=.*|tmpdir = '${DTMPOUT}'|"\
          -e "s|^YR[ ]*=.*|YR = ${ystart}|"\
          -e "s|^mstart[ ]*=.*|mstart = ${MS}|"\
          -e "s|^varnm[ ]*=.*|varnm = '${fssh}'|"\
          -e "s|^prefix[ ]*=.*|prefix = '${ssh_prfx}'|"\
          -e "s|^ens[ ]*=.*|ens = ${ens}|" $extrdaypy > $fexeday

      chmod 750 $fexeday
  #    python $fexeday
      ipython $fexeday
      wait

    fi
  done
done 

echo "All Done"
exit 0


