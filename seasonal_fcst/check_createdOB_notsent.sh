#!/bin/bash
#  !!! be careful when modifying this code !!!
# is it called by several other scripts to check the status of OB files
# e.g. create_dailyOB_MAIN.sh
#
# Check if OB file has not been sent but has been created and  zipped 
# check: status=$?
# if status == 2 - file created
#
# If OB file not found check if zipped file exists but has not been sent yet:
# do not recreate it
# if status == 3 - zip created 
#
#  usage: check_createdOB_notsent.sh YR MM ens
# 
set -u

export OBDIR=/work/Dmitry.Dukhovskoy/NEP_input/spear_obc_daily
export gaea_dir=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/NEP_data/forecast_input_data/obcs_spear_daily
export prfx=OBCs_spear_daily_init
export size_min=75  # >0 -check if OB *.nc file has been created to avoid recreating it
                    # size_min - min size (GB *10) of the OB file 

export size_gz=20  # GB*10 for gzipped files

if [[ $# -lt 3 ]]; then
  echo "MIssing YR MM ENSEMBLE"
  echo "usage: check_sentOB.sh YR MM ens"
  exit 1
fi

YR=$1
MM=$2
ens=$3
MM0=$( echo $MM | awk '{printf("%02d", $1)}' )      
ens0=$( echo $ens | awk '{printf("%02d",$1)}' )

obc_file=${prfx}${YR}${MM0}01_e${ens0}.nc
obcgz_file=${obc_file}.gz

/bin/ls -l $OBDIR/$obc_file 2> /dev/null
status=$?

/bin/ls -l $OBDIR/$obcgz_file 2> /dev/null
status_gz=$?

#echo $status
if [[ $status -eq 0 ]]; then
  dsz=$( ls -lh $OBDIR/$obc_file | cut -d" " -f5 )
  sz=${dsz%?}
# Remove the dot:
  sz=$( echo $sz | sed -e "s|\.||g" )
  if [[ $sz -ge $size_min ]]; then
    echo "Allready exists: $OBDIR/$obc_file, size=$dsz"
    exit 2
  fi
fi

if [[ $status_gz -eq 0 ]]; then
  dsz=$( ls -lh $OBDIR/$obcgz_file | cut -d" " -f5 )
  sz=${dsz%?}
# Remove the dot:
  sz=$( echo $sz | sed -e "s|\.||g" )
  if [[ $sz -ge $size_gz ]]; then
    echo "zipped file exists: $OBDIR/$obcgz_file, size=$dsz"
    exit 3   
  fi
fi


echo "NOT created, NOT zipped: $OBDIR/$obc_file"

exit 0  


