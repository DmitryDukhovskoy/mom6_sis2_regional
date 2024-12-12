#!/bin/bash 
#
# Restart archives are not needed
# for seasonal forecasts
set -u

export REG=NEP
export EXPT=seasonal_daily
export DARCH=/archive/Dmitry.Dukhovskoy/fre/${REG}/${EXPT}
export PLTF=gfdl.ncrc5-intel23-repro
export oprfx=oceanm    # ocean daily fields naming
export iprfx=icem      # ice daily fields naming
export expt_nmb=02     # forecast run experiment number or forecast group name 
#                      # 01 - with 1 SPEAR ens for OBCs, 02- multi SPEAR ens, etc.
                       # expt_nmb will be changed based on output fields names
                       # it is needed only if output fields have laready been 
                       # moved to post-processed directories to finish
                       # post-processing if it has been interrupted
export expt_prfx=NEPphys_frcst_dailyOB


expt_name=NEPphys_frcst_dailyOB-expt${expt_nmb}
cd $DARCH/${expt_name}
pwd

for dir_outp in $( ls -d ????-??-e?? ); do
  cd $DARCH/${expt_name}/${dir_outp}/restart
  for flrest in $( ls ???.res.*-e??.nc.gz ); do
    echo "Removing ${expt_name}/${dir_outp}/restart/${flrest}"
    /bin/rm -f $flrest
    touch $flrest
  done
done

echo "All done"

exit 0
