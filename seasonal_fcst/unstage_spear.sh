#!/bin/bash 
#SBATCH --output=logs/%j.out
#
# unstage SPEAR ocean monthly fields before running python script
# First need to unstage the data 
# Then run python script
#  
# Usage:  [sbatch] $0 --ys 1994 [--ye 1995] [--ms 4] [-ens 1,...,10]
set -u

export DTMP=$TMPDIR
export WD=/work/Dmitry.Dukhovskoy/tmp/spear_subset/scripts
export DPYTH=/home/Dmitry.Dukhovskoy/python/setup_seasonal_NEP
export extrpy=extract_domain_spear.py

/bin/mkdir -pv $WD

YR1=0
YR2=0
MONTHS=(1 4 7 10)
ENSMB=(1 2 3 4 5 6 7 8 9 10)
SSH_DAY=1  # =0 : use monthly SSH
           # =1 : use daily SSH from ice_daily 
           # =2 : use daily SSH from ocean_daily - not avail for all years 

usage() {
  echo "Usage: $0 --ys 1994 [--ye 1995] [--mm 4] [--ens 1,...,10] "
  echo "  --ys     start with this year  <-- Required" 
  echo "  --ye     end with this year, default=same as ys"
  echo "  --mm     month to process, default (1,4,7,10)"
  echo "  --ens    SPEAR ens. run to process, default (1,...,10)"
  exit 1
}

# input with key arguments:
# Parse the command-line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --ys)
      YR1=$2
      shift 2 # Move past the flag and its arg. to the next flag
      ;;
    --ye)
      YR2=$2
      shift 2
      ;;
    --mm)
      MONTHS=($2)
      shift 2
      ;;
    --ens)
      ENSMB=($2)
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
  echo "ERR: YR1 was not specified $YR1"
  usage
fi
if [[ $YR2 -eq 0 ]]; then
  YR2=$YR1
fi


echo "Unstaging SPEAR monthly means for $YR1-$YR2 MM=${MONTHS[@]} ensembles=${ENSMB[@]}"

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
    for ens in ${ENSMB[@]}; do
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
      pwd
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
        pwd
        flnm=$( ls ice.${ystart}${mstart}-??????.SSH.nc ) 
        echo "unstaging $flnm"
        dmget $flnm
      #  /bin/cp $flnm $DTMPOUT/. 
      #  wait
      fi

    # Daily SSH:
      if [[ $SSH_DAY -eq 1 ]]; then
        cd $DSSHDAY
        pwd
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
done 

echo "All Done"
exit 0


