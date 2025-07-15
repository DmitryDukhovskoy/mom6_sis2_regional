#!/bin/bash 
#SBATCH --output=logs/%j.out
#
# Script: Create daily OB from SPEAR output
# running create_daily_from_monthly_spear.py 
#
#  !!!!!!!!!!!!!!!!!!!!!!!!
# Careful when modifying the script - it is called from create_dailyOB_MAIN.sh
#  !!!!!!!!!!!!!!!!!!!!!
#
# To run manually - edit python code and use python directly 
#
# !!!!!
#  Doesnt work on compute node with sbatch - 
# python on compute nodes does not find python yaml etc modules
# !!!!!!!
# 
# Here ens is SPEAR ensemble run, it is also the seasonal f/cast ens# unless 
# fixed SPEAR ens run is used for all seasonal f/casts
# then create 1 OB (e.g. ens=1) and use it as OB for all seasonal f/casts
#
# Usage:  create_daily_OBspear.sh YR1 [YR2] [MM] ens1 [ens2]
# Examples:
#   create_daily_OBspear.sh YR1 ens - generate OBs for init YR1 all months Jan, Apr, .., and ens run = ens
#   create_daily_OBspear.sh YR1 YR2 ens - generate OBs for init YR1-YR2 and ens run = ens
#   create_daily_OBspear.sh YR1 MM ens - generate OBs for init YR1 month=MM and ens run = ens
#   create_daily_OBspear.sh YR1 YR2 MM ens - generate OBs for init YR1-YR2  month=MM and ensrun = ens
#   create_daily_OBspear.sh YR1 MM ens1 ens2 - generate OBs for init YR1  month=MM and ensruns = ens1:ens2
#
# yr_start, mo_start - initialization dates of the SPEAR f/cast 
# ens - SPEAR ens. run
#
#  To send zipped OB file to gaea: 
#  # use zipOB_to_gaea.sh
#
set -u

if module list | grep "python"; then
  echo "python loaded"
else
  module load python/3.13
fi
module list
eval "$($PYPATH/bin/conda shell.bash hook)"
conda activate anls

export obc_dir=/work/Dmitry.Dukhovskoy/NEP_input/spear_obc_daily
export run_dir=/work/Dmitry.Dukhovskoy/NEP_input/obc_daily_scripts
export py_dir=/home/Dmitry.Dukhovskoy/python/setup_seasonal_NEP
export extrpy=create_dailyOB_from_monthly_spear.py
export SRC=/home/Dmitry.Dukhovskoy/scripts/seasonal_fcst
export fzip=0  # = 0 - use zipOB_to_gaea.sh for compressing OB to expedite OB creation for multiple files
export size_min=75  # >0 -check if OB *.nc file has been created to avoid recreating it
                    # size_min - min size (GB *10) of the OB file 
export OBDIR=/work/Dmitry.Dukhovskoy/NEP_input/spear_obc_daily # <-- double check with python yaml


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

echo "create_daily_OBspear.sh: OBCs for ${YR1}-${YR2} MM=${MONTHS[@]} ens=${ENSMB[@]}" 
date

for (( yr_start=$YR1; yr_start<=$YR2; yr_start+=1 )); do
  for mo_start in ${MONTHS[@]}; do
    cd $run_dir
    for fl in config_nep.yaml pypaths_gfdlpub.yaml mod_utils_ob.py mod_regmom.py boundary.py
    do
      /bin/cp $py_dir/$fl .
    done

    /bin/cp $py_dir/$extrpy .

    for ens_run in ${ENSMB[@]}; do
      echo "OBCs: init year=${yr_start} MM=${mo_start} ens_run=${ens_run}"
      ens0=$( echo $ens_run | awk '{printf("%02d",$1)}' )
      mm0=$( echo $mo_start | awk '{printf("%02d", $1)}' )
      obc_file=OBCs_spear_daily_init${yr_start}${mm0}01_e${ens0}.nc 

      $SRC/check_sentOB.sh $yr_start $mm0 $ens0
      status=$?
      if [[ $status -eq 2 ]]; then
        echo "$yr_start $mm0 $ens0 already sent to gaea, skipping ..."
        continue
      fi
# If not sent to gaea, check if *.nc or gzip exists
      ${SRC}/check_createdOB_notsent.sh --yr $yr_start --mm $mm0 --ens $ens0
      status_gz=$?
      if [[ $status_gz -eq 2 ]]; then
        echo " OB file ${obc_file}  created NOT zipped  NOT sent yet, skipping OB creating step ..."
        continue
      fi
      if [[ $status_gz -eq 3 ]]; then
        echo " OB file ${obc_file}.gz  created AND zipped but NOT sent yet, skipping OB creating step ..."
        continue
      fi

# Check if OBC files has been already created:
      if [[ $size_min -gt 0 ]]; then
        /bin/ls -l $OBDIR/$obc_file 2> /dev/null
        status=$?
        if [[ $status -eq 0 ]]; then
          dsz=$( ls -lh $OBDIR/$obc_file | cut -d" " -f5 )
          sz=${dsz%?}
# Remove the dot:
          sz=$( echo $sz | sed -e "s|\.||g" )
          if [[ $sz -ge $size_min ]]; then
            echo "Allready exists: $OBDIR/$obc_file, size=$dsz, skipping ..."
            continue
          fi
        fi
      fi 

      # Old code, use key args instead:
      # frun=create_dailyOB_${yr_start}${mm0}-e${ens0}.py
      #/bin/rm -f $frun
#
      #sed -e "s|^PPTHN[ ]*=.*|PPTHN = '/home/Dmitry.Dukhovskoy/python'|"\
      #    -e "s|^ens_spear[ ]*=.*|ens_spear = $ens_run|"\
      #    -e "s|^yr_start[ ]*=.*|yr_start = $yr_start|"\
      #    -e "s|^mo_start[ ]*=.*|mo_start = $mo_start|" $extrpy > $frun
#
      #chmod 750 $frun
      #ipython $frun
      python $extrpy --ens ${ens_run} --YRS ${yr_start} --MMS ${mo_start}
      wait

      echo "OBCs for ${yr_start}/${mo_start} ens=${ens_run}  completed ..."
      date
  # zipping can be done in zipOB_to_gaea.sh
#      if [[ fzip -eq 1 ]]; then
#        echo "start zipping ..."
#        cd $obc_dir
#
#        ls -l $obc_file
#
#        gzip $obc_file
#        wait
#      fi
    done
  done   # months
done

echo "All done ..."

exit 0

