#!/bin/bash 
#SBATCH --output=logs/%j.out
#
# Subset SPEAR ice monthly fields for a specified domain (NEP)
# First need to unstage the data 
# Then run python script
#   
# Change ICE_MO=1 for using monthly SSH to 0 for skipping monthly ssh
# ICE_DAY=1 for using daily SSH
#
# usage: sbatch subset_spear_ocean.sh YR1 [YR2] [MM] ens1 [ens2]
#         subset_spear_ocean.sh YR1 ens - subset OBs for init YR1 all months Jan, Apr, .., and ens run = ens
#         subset_spear_ocean.sh YR1 YR2 ens - subset OBs for init YR1-YR2 and ens run = ens
#         subset_spear_ocean.sh YR1 MM ens - subset OBs for init YR1 month=MM and ens run = ens
#         subset_spear_ocean.sh YR1 MM ens1  ens2 - subset OBs for init YR1  month=MM and ensruns = ens1:ens2
#
# run ipython on login node
# e.g.: subset_spear_ocean.sh 1998 7 1 10 --> OBs subset for init 1998/7 ens=1-10
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
export extrpy=extract_domain_ice_spear.py
#export extrdaypy=extract_domain_spear_sshdaily.py  <--- need to update code for daily ice fields !!!
export SRC=/home/Dmitry.Dukhovskoy/scripts/seasonal_fcst

usage() {
  echo "Usage: $0 --yr1 1995 [--yr2 1999] --ens1 2 [--ens2 5] [MM 7]"
  echo "  --yr1     subset SPEAR to NEP for init YR1"
  echo "  --yr2     subset SPEAR for YR1 - YR2 years, default YR2=YR1"
  echo "  --ens1    subset SPEAR ens. run ens1"
  echo "  --ens2    subset SPEAR ens. runs ens1-ens2, deault ens2=ens1"
  echo "  --MM      subset SPEAR for month MM, default = [Jan, Apr, Jul, Oct]"
  exit 1
}


/bin/mkdir -pv $WD

echo "Number of inputs $#"
if [[ $# -lt 2 ]]; then
  echo "at least init year and ens should be specified"
  usage
fi

ICE_MO=1   # =1 : use monthly fields, otherwise - daily
#ICE_DAY=1  # =1 : use daily from ice_daily 
if [[ $ICE_MO -eq 1 ]]; then
  ICE_DAY=0
else
  ICE_DAY=1
  echo "THe code works only for monthly ice thkn and conc, daily fields - adjust the script"
  exit 1
fi 

YR2=0
ens1=0
ens2=0
MONTHS=(1 4 7 10)
# input with key arguments:
# Parse the command-line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --yr1)
      YR1=$2
      shift 2 # Move past the flag and its arg. to the next flag
      ;;
    --yr2)
      YR2=$2
      shift 2 
      ;;
    --ens1)
      ens1=$2
      shift 2
      ;;
    --ens2)
      ens2=$2
      shift 2
      ;;
    --MM)
      MONTHS=($2)
      shift 2
      ;;
    *)
    echo "Error: Unrecognized option $1"
    usage
    ;;
  esac
done

if [[ $ens1 -eq 0 ]]; then
  echo "ens1 required, not provided, quitting ..."
  usage
fi

if [[ $YR2 -eq 0 ]]; then
  YR2=$YR1
fi

if [[ $ens2 -eq 0 ]]; then
  ens2=$ens1
fi

echo "SPEAR ice fields subset to NEP domain for ${YR1}-${YR2} MM=${MONTHS[@]} ens=${ens1}-${ens2}" 

cd $WD

if [[ $ICE_DAY -gt 0 ]]; then
  day_ice=True
  mo_ice=False
else
  day_ice=False
  mo_ice=True
fi

for (( ystart=$YR1; ystart<=$YR2; ystart+=1 )); do
  for (( ens_run=$ens1; ens_run<=$ens2; ens_run+=1 )); do
    ens=$( echo $ens_run | awk '{printf("%d",$1)}' )
    nens=$(echo ${ens_run} | awk '{printf("%02d",$1)}')
    echo "Starting year=${ystart} for ens run${ens}"
    for MS in ${MONTHS[@]}; do
      #$SRC/check_sentOB.sh $ystart $MS $ens 
      #status=$?
      #if [[ $status -eq 2 ]]; then
      #  echo "$ystart $MS $ens already sent to gaea, skipping ..."
      #  continue
      #fi

      # Find the directory to SPEAR post-processed forecast output on archive
      RT=/archive/l1j/spear_med/rf_hist/fcst/s_j11_OTA_IceAtmRes_L33
      mstart=$(echo ${MS} | awk '{printf("%02d",$1)}')
      subdir1=i${ystart}${mstart}01_OTA_IceAtmRes_L33
      if (( $ystart == 2020 )); then
        subdir1=${subdir1}_rerun
      elif ((( $ystart >= 2015  && $ystart <=2019 ) || $ystart == 2021 )); then
        subdir1=${subdir1}_update
      fi

      fconc=siconc
      fthkn=sithick
      if [[ $ICE_DAY -eq 0 ]]; then
        DICE=$RT/${subdir1}/pp_ens_${nens}/ice/ts/monthly/1yr
        ice_prfx=ice
      else
        ice_prfx=ice_daily
        DICE=$RT/${subdir1}/pp_ens_${nens}/ice_daily/ts/daily/1yr
      fi

      DTMPOUT=${DTMP}/${ystart}${mstart}/ens${nens}
      echo "SPEAR ice dir=$DICE"
      echo "TMP dir = $DTMPOUT"
      /bin/mkdir -pv $DTMPOUT
      chmod 750 $DTMPOUT
      /bin/rm $DTMPOUT/*${ystart}${mstart}.*.nc

      cd $DICE
      for varnm in siconc sithick ; do
        flnm=$( ls ${ice_prfx}.${ystart}${mstart}-??????.${varnm}.nc ) 
        echo "unstaging $flnm"
        dmget $flnm
        wait
        /bin/cp $flnm $DTMPOUT/.
      done

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

      if [[ $ICE_MO -gt 0 ]]; then
        sed -e "s|^pthtmp[ ]*=.*|pthtmp = '${DTMP}'|"\
            -e "s|^tmpdir[ ]*=.*|tmpdir = '${DTMPOUT}'|"\
            -e "s|^YR[ ]*=.*|YR = ${ystart}|"\
            -e "s|^mstart[ ]*=.*|mstart = ${MS}|"\
            -e "s|^ens[ ]*=.*|ens = ${ens}|" $extrpy > $fexe

        chmod 750 $fexe
      #  python $fexe
        ipython $fexe
        wait
      else
        cd $WD
        pwd
        fexeday=run_extrday_${ystart}${mstart}.py
        /bin/rm -rf $fexeday
         
        sed -e "s|^pthtmp[ ]*=.*|pthtmp = '${DTMP}'|"\
            -e "s|^tmpdir[ ]*=.*|tmpdir = '${DTMPOUT}'|"\
            -e "s|^YR[ ]*=.*|YR = ${ystart}|"\
            -e "s|^mstart[ ]*=.*|mstart = ${MS}|"\
            -e "s|^varnm[ ]*=.*|varnm = '${fssh}'|"\
            -e "s|^prefix[ ]*=.*|prefix = '${ice_prfx}'|"\
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

echo "All Done"
exit 0


