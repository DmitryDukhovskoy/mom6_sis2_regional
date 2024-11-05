#!/bin/bash -x
#SBATCH --output=logs/%j.out
#
# Script: Create daily OB from SPEAR output
# running create_daily_from_monthly_spear.py 
#
# To run manually - edit python code and use python directly 
#
# !!!!!
#  Doesnt work on compute node with sbatch - 
# python on compute nodes does not find python yaml etc modules
# !!!!!!!
# 
# Usage:  create_daily_OBspear.sh YR1 [YR2] [MM] ens
#         create_daily_OBspear.sh YR1 ens - will generate OBs for init YR1 all months Jan, Apr, .., and ens run = ens
#         create_daily_OBspear.sh YR1 YR2 ens - will generate OBs for init YR1-YR2 and ens run = ens
#         create_daily_OBspear.sh YR1 MM ens - will generate OBs for init YR1 month=MM and ens run = ens
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
  module load python/3.10 
fi
module list
eval "$($PYPATH/bin/conda shell.bash hook)"
conda activate anls

export obc_dir=/work/Dmitry.Dukhovskoy/NEP_input/spear_obc_daily
export run_dir=/work/Dmitry.Dukhovskoy/NEP_input/obc_daily_scripts
export py_dir=/home/Dmitry.Dukhovskoy/python/setup_seasonal_NEP
export extrpy=create_dailyOB_from_monthly_spear.py
export fzip=0  # use zipOB_to_gaea.sh for compressing OB

if [[ $# < 2 ]]; then
  echo "at least init year and ens should be specified"
  echo "usage: sbatch create_daily_OBspear.sh YR1 [YR2] [MM] ens" 
  exit 1
fi

YR1=$1
YR2=$YR1
MONTHS=(1 4 7 10)
#ens=$( echo $2 | awk '{printf("%02d",$1)}' )
ens_run=$2

if [[ $# -gt 2 ]]; then
  if [[ $2 -gt 100 ]]; then
    YR2=$2
  else
    MONTHS=($2)
  fi   
#  ens=$( echo $3 | awk '{printf("%02d",$1)}' )
  ens_run=$3
fi

for (( yr_start=$YR1; yr_start<=$YR2; yr_start+=1 )); do
  echo "Starting year=${yr_start} for ens run${ens_run}"
  for mo_start in ${MONTHS[@]}; do
#    ens0=$ens

    cd $run_dir
    for fl in config_nep.yaml pypaths_gfdlpub.yaml mod_utils_ob.py mod_regmom.py boundary.py
    do
      /bin/cp $py_dir/$fl .
    done

    /bin/cp $py_dir/$extrpy .

    ens0=$( echo $ens_run | awk '{printf("%02d",$1)}' )
    mm0=$( echo $mo_start | awk '{printf("%02d", $1)}' )
    frun=create_dailyOB_${yr_start}${mm0}-e${ens0}.py
    /bin/rm -f $frun

    sed -e "s|^PPTHN[ ]*=.*|PPTHN = '/home/Dmitry.Dukhovskoy/python'|"\
        -e "s|^ens_spear[ ]*=.*|ens_spear = $ens_run|"\
        -e "s|^yr_start[ ]*=.*|yr_start = $yr_start|"\
        -e "s|^mo_start[ ]*=.*|mo_start = $mo_start|" $extrpy > $frun

    chmod 750 $frun
    ipython $frun
    wait

    echo "OBCs for ${yr_start}/${mo_start} ens=${ens_run}  completed ..."
# zipping can be done in zipOB_to_gaea.sh
    if [[ fzip -eq 1 ]]; then
      echo "start zipping ..."
      cd $obc_dir

      obc_file=OBCs_spear_daily_init${yr_start}${mm0}01_e${ens0}.nc 
      ls -l $obc_file

      gzip $obc_file
      wait
    fi
  done   # months
done

echo "All done ..."

exit 0

