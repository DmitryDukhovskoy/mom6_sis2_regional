#!/bin/bash -x
# 
# send runoff data to gaea
# groupped N years data
# 
#  usage: runoff_to_gaea.sh
#
set -u

export dir_riv=/work/Dmitry.Dukhovskoy/NEP_input/glofas_runoff
export gaea_dir=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/NEP_data/forecast_input_data/runoff

if module list | grep "gcp"; then
  module load gcp/2.3
fi

prfx=glofas_runoff_NEP_816x342_daily_

cd $dir_riv
pwd
ls -l $prfx*.nc

for flriv in $( ls $prfx*.nc ); do
  echo "sending ${flriv} to gaea: ${gaea_dir} ..."
  gcp ${flriv} gaea:${gaea_dir}/.
#    status=$?
#    if [[ $status == 0 ]]; then
#      echo "${fl}.gz sent to gaea "
#      touch sent_riv/${fl}.gz-sent
#    fi
#  done
done

echo "All done "

exit 0  


