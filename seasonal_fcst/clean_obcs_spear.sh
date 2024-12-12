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

if [[ $# -lt 1 ]] || [[ $# -gt 3 ]]; then
  echo "usage: clean_obcs_spear.sh YR1 [YR2] [ens]" 
  echo "clean_obcs_spear.sh 1999        - delete OBC files for all ensembles and init months 1999"
  echo "clean_obcs_spear.sh 1999 2000   - delete OBC files for all ensembles and init months 1999-2000"
  echo "clean_obcs_spear.sh 1999 4      - delete OBC files for ensemble 04 and all init months 1999"
  echo "clean_obcs_spear.sh 1999 2005 9 - delete OBC files for ensemble 09 and all init months 1999-2005"
  exit 1
fi

YR1=$1
YR2=$YR1
ens_run=0

if [[ $# -eq 2 ]]; then
  if [[ $2 -gt 100 ]]; then
    YR2=$2
  else
    ens=$3
    ens_run=$(echo ${ens} | awk '{printf("%02d",$1)}')
  fi
fi

if [[ $# -eq 3 ]]; then
  YR2=$2
  ens=$3
  ens_run=$(echo ${ens} | awk '{printf("%02d",$1)}')
fi

# SPEAR subsets for deleted OBC years/ens  will be deleted
cd $DOBCS
cd ./sent_OBCs
pwd
ls -l
for flsent in $(  ls ${sfx}*.gz-sent ); do
  flgz=$( echo $flsent | sed -e "s|gz-sent|gz|" )
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


