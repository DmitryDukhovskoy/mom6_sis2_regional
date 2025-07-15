#!/bin/bash 
#SBATCH --output=logs/%j.out
#
# Subset SPEAR ocean monthly fields for a specified domain
# First need to unstage the data 
# Then run python script
#   
# Change SSH_MO=1 for using monthly SSH to 0 for skipping monthly ssh
# SSH_DAY=1 for using daily SSH
#
# usage: sbatch subset_spear_ocean.sh --ys 1994 [--ye 1995] [--mm 4] --ens 1,...,10
#
# run ipython on login node
# e.g.: subset_spear_ocean.sh --ys 1998 --mm 7  --> OBs subset for init 1998/7 ens=1-10
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
export SRC=/home/Dmitry.Dukhovskoy/scripts/seasonal_fcst

/bin/mkdir -pv $WD

SSH_MO=0   # =1 : use monthly SSH
SSH_DAY=1  # =1 : use daily SSH from ice_daily 
#          # =2 : use daily SSH from ocean_daily - not avail for all years 
YR1=0
YR2=0
MONTHS=(1 4 7 10)
ENSMB=(1 2 3 4 5 6 7 8 9 10)

usage() {
  echo "Usage: $0 --ys 1994 [--ye 1995] [--mm 4] --ens 1,...,10 "
  echo "  --ys     start with this year  <-- Required" 
  echo "  --ye     end with this year, default=same as ys"
  echo "  --mm     month to process, default (1,4,7,10)"
  echo "  --ens    SPEAR ens. run to process, default (1,...,10)"
  exit 1
}

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


echo "OBCs will be subset for ${YR1}-${YR2} MM=${MONTHS[@]} ens=${ENSMB[@]}" 

cd $WD

if [[ $SSH_DAY -gt 0 ]]; then
  day_ssh=True
  mo_ssh=False
else
  day_ssh=False
  mo_ssh=True
fi

for (( ystart=$YR1; ystart<=$YR2; ystart+=1 )); do
  for ens in ${ENSMB[@]}; do
    #ens=$( echo $ens_run | awk '{printf("%d",$1)}' )
    nens=$(echo ${ens} | awk '{printf("%02d",$1)}')
    echo "Starting year=${ystart} for ens run${ens}"
    for MS in ${MONTHS[@]}; do
      mstart=$(echo ${MS} | awk '{printf("%02d",$1)}')
      $SRC/check_sentOB.sh $ystart $MS $ens 
      status=$?
      if [[ $status -eq 2 ]]; then
        echo "$ystart $MS $ens already sent to gaea, skipping ..."
        continue
      fi

      # Check if subset files have been already created:
      DSUBSET=/work/Dmitry.Dukhovskoy/tmp/spear_subset/${ystart}/ens${nens}
      icheck=0
      for fldnm in so ssh_daily thetao uo vo; do
        flnm_sub=NEP_spear_${ystart}${mstart}.${fldnm}.nc
        if [ -s ${DSUBSET}/${flnm_sub} ]; then
          echo "Found ${DSUBSET}/${flnm_sub} no subsetting required ..."
        else
          icheck=1
        fi
      done
 
      if [[ $icheck -eq 0 ]]; then
        echo "Skipping subsetting  for ${ystart}/${mstart} ...."
        continue
      fi

      # Find the directory to SPEAR post-processed forecast output on archive
      RT=/archive/l1j/spear_med/rf_hist/fcst/s_j11_OTA_IceAtmRes_L33
      subdir1=i${ystart}${mstart}01_OTA_IceAtmRes_L33
      if (( $ystart == 2020 )); then
        subdir1=${subdir1}_rerun
      elif ((( $ystart >= 2015  && $ystart <=2019 ) || $ystart == 2021 )); then
        subdir1=${subdir1}_update
      fi

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
      echo "SPEAR ocean dir=$DOCN"
      echo "SPEAR ice dir=$DICE"
      echo "SPEAR ssh dir=$DSSHDAY"
      echo "TMP dir = $DTMPOUT"
      /bin/mkdir -pv $DTMPOUT
      chmod 750 $DTMPOUT
      /bin/rm $DTMPOUT/*${ystart}${mstart}.*.nc

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
        status=$?
        if [[ $status -gt 0 ]]; then
          echo "ERROR: failed $fexeday ..."
          exit 5
        fi

      fi
    done
  done
done 

echo "subset_spear_ocean.sh: All Done"
exit 0


