#!/bin/bash
#
# To resend zipped file, need to clear sent OB files list
#
#  usage: delete_sentOB_list.sh YR1 MM ens1 [ens2] 
# 
set -u

export OBDIR=/work/Dmitry.Dukhovskoy/NEP_input/spear_obc_daily
export prfx=OBCs_spear_daily_init

if [[ $# -lt 3 ]]; then
  echo "MIssing YR MM ENSEMBLE"
  echo "usage: delete_sentOB_list.sh YR MM ens"
  exit 1
fi

YR=$1
MM=$2
ens=$3
MM0=$( echo $MM | awk '{printf("%02d", $1)}' )      
ens0=$( echo $ens | awk '{printf("%02d",$1)}' )

obc_file=${prfx}${YR}${MM0}01_e${ens0}.nc
sent_file=${obc_file}.gz-sent

echo "Deleting sent file: $OBDIR/sent_OBCs/$sent_file"
/bin/rm -f $OBDIR/sent_OBCs/$sent_file

exit 0  


