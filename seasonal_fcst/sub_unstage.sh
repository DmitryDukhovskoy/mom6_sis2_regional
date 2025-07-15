#!/bin/bash
# SBATCH --output=logs/unstage_%j.out
#
# submit slurm jobs to unstage multiple SPEAR fields
# submit 1 year at a time 
# Usage:  ./sub_unstage.sh --ys 1997 [--mm 4] [--ens 1,...,10]
#
set -u

YR1=0
MONTHS=(1 4 7 10)
ENSMB=(1 2 3 4 5 6 7 8 9 10)
SSH_DAY=1  # =0 : use monthly SSH
           # =1 : use daily SSH from ice_daily 
           # =2 : use daily SSH from ocean_daily - not avail for all years 

usage() {
  echo "Usage: $0 --ys 1994 [--mm 4] [--ens 1,...,10] "
  echo "  --ys     start with this year  <-- Required" 
  echo "  --mm     month to process, default (1,4,7,10)"
  echo "  --ens    SPEAR ens. run to process, default (1,...,10)"
  exit 1
}

# input with key arguments:
# Parse the command-line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --ys)
      YR=$2
      shift 2 # Move past the flag and its arg. to the next flag
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

if [[ $YR -eq 0 ]]; then
  echo "ERR: YR1 was not specified $YR1"
  usage
fi

for MM in ${MONTHS[@]}; do
  for ens in ${ENSMB[@]}; do
    echo "submitting job to unstage SPEAR fields for init ${YR}/${MM} ens=${ens}"
    sbatch unstage_spear.sh --ys $YR --mm $MM --ens $ens
  done
done

exit 0
  
