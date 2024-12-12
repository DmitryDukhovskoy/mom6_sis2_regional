#!/bin/bash
# SBATCH --output=logs/unstage_%j.out
#
# submit slurm jobs to unstage multiple SPEAR fields
# 
# Usage:  ./sub_unstage.sh YR1 MM ens1 [ens2]
#
set -u

if [[ $# -lt 3 ]]; then
  echo "ERROR: not enough input parameters"
  echo "usage: ./sub_unstage.sh YR1 mstart ens1 [ens2]"
  exit 1
fi

YR=$1
MM=$2
ens1=$3

if [[ $# -eq 4 ]]; then
  ens2=$4
else
  ens2=$ens1
fi


for (( ens=$ens1; ens<=$ens2; ens+=1 )); do
  echo "submitting job to unstage SPEAR fields for init ${YR}/${MM} ens=${ens}"
  sbatch unstage_spear.sh $YR $MM $ens
done

exit 0
  
