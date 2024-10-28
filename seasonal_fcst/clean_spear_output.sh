#!/bin/bash -x
#SBATCH --output=logs/%j.out
#
# Clean SPEAR ocean monthly / ice fields
# extracted for a specified domain
# to create OBs files
#   
set -u

export DTMP=$TMPDIR
export WD=/work/Dmitry.Dukhovskoy/tmp/spear_subset/scripts
export DPYTH=/home/Dmitry.Dukhovskoy/python/setup_seasonal_NEP
export extrpy=extract_domain_spear.py
export extrdaypy=extract_domain_spear_sshdaily.py

/bin/mkdir -pv $WD

if [[ $# < 4 ]]; then
  echo "usage: need to specify initialization yr month and ensemble run"
  echo "usage: sbatch clean_spear_output.sh yr1 yr2 mstart ens1 [ens2]"
  exit 1
fi

YR1=$1
YR2=$2
MS=$3
ens1=$4
if [[ $# == 5 ]]; then
  ens2=$5
else
  ens2=$ens1
fi

echo "Deleting subsets of SPEAR monthly means for $YR1-$YR2 month_start=$MS ensembles=$ens1 - $ens2"

for (( ystart=$YR1; ystart<=$YR2; ystart+=1 )); do
  mstart=$(echo ${MS} | awk '{printf("%02d",$1)}')
  for (( ens=$ens1; ens_run<=$ens2; ens+=1 )); do
    init_date=${ystart}${mstart}
    ens_run=$(echo $ens | awk '{printf("%02d", $1)}')
    spear_dir=/work/Dmitry.Dukhovskoy/tmp/spear_subset/${ystart}/ens${ens_run}

    cd $spear_dir
    /bin/rm NEP_spear_${init_date}.*.nc
  done
done    

echo "All Done"
exit 0


