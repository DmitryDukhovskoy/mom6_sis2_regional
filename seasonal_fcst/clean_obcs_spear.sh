#!/bin/bash 
#
# Delete SPEAR subset fields used to create OB files (subset_spear_ocean.sh)
# /work/Dmitry.Dukhovskoy/tmp/spear_subset/
#
# and OBCs files sent to gaea
# /work/Dmitry.Dukhovskoy/NEP_input/spear_obc_daily
#
# usage: clean_obcs_spear.sh YR1 [YR2] [ens]
#    clean_obcs_spear.sh 1999        - delete OBC files for all ensembles and init months 1999
#    clean_obcs_spear.sh 1999 2000   - delete OBC files for all ensembles and init months 1999-2000
#    clean_obcs_spear.sh 1999 4      - delete OBC files for ensemble 04 and all init months 1999
#    clean_obcs_spear.sh 1999 2005 9 - delete OBC files for ensemble 09 and all init months 1999-2005
# 
#
set -u

export DSUBSET=/work/Dmitry.Dukhovskoy/tmp/spear_subset
export DOBCS=/work/Dmitry.Dukhovskoy/NEP_input/spear_obc_daily
export sfx=OBCs_spear_daily_init
YR1=0
YR2=0
ens_run=0

usage() {
  echo "Usage: $0 --ys 1994 [--ye 1995] [--mm 4] --ens 1,...,10 "
  echo "  --ys     start with this year" 
  echo "  --ye     end with this year, default=same as ys"
  echo "  --ens    SPEAR ens. run to process, default all: (1,...,10)"
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
    --ens)
      ens_run=$2
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
if [[ $ens_run -gt 0 ]]; then
  ens_run=$(echo ${ens_run} | awk '{printf("%02d",$1)}')
fi


# SPEAR subsets for deleted OBC years/ens  will be deleted
cd $DOBCS
cd ./sent_OBCs
pwd
ls -l
for flsent in $(  ls ${sfx}*.*-sent ); do
  #flgz=$( echo $flsent | sed -e "s|gz-sent|gz|" )
  flgz=$( echo "$flsent" | sed -E 's|-sent$||' )  # any *.nc-sent or *.gz-sent 
  dmm=$( echo ${flsent} | cut -d"_" -f5 )
#    ens=$( echo ${dmm:1:2} | awk '{printf("%02d", $1)}' )
  nchar=$( echo ${sfx} | wc -m )
  ncharS=$(( nchar-1 ))
  yr=${flsent:${ncharS}:4}
  ens=${dmm:1:2}

  spear_dir=$DSUBSET/${yr}/ens${ens}
  #echo "${yr} ens=${ens}"
  if [[ $yr -ge $YR1 ]] && [[ $yr -le $YR2 ]]; then
    if [[ 10#$ens_run -eq 10#$ens ]] || [[ $ens_run -eq 0 ]]; then 
      echo "Deleting $DOBCS/$flgz"
      /bin/rm -f $DOBCS/$flgz

      echo "Deleting SPEAR subset: $spear_dir"
      /bin/rm -f $spear_dir/NEP_spear_${yr}*.nc
    fi
  else 
    continue
  fi
done

exit 0


