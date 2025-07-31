#!/bin/bash 
#
# Restart archives are not needed
# for seasonal forecasts
set -u

export REG=NEP
export EXPT=forecast_bgc
export DARCH=/archive/Dmitry.Dukhovskoy/fre/${REG}/${EXPT}
export PLTF=gfdl.ncrc6-intel23-repro
export oprfx=oceanm    # ocean daily fields naming
export iprfx=icem      # ice daily fields naming
export expt_nmb=01     # forecast run experiment number or forecast group name 

expt_name=NEPbgc_fcst_dailyOB${expt_nmb}
cd $DARCH
pwd

for dir_outp in $( ls -d ${expt_name}_????-??-e?? ); do
  cd $DARCH/${dir_outp}/${PLTF}
  echo "Removing ${dir_outp}/${PLTF}/restart"
  /bin/rm -rf restart/*
done

echo "All done"

exit 0
