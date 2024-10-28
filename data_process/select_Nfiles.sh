#!/bin/bash 
#
# In the output directory, select everyth Nth file and delete the rest
#
#
set -u

export expt=NEP_BGCphys_GOFS

#export DARCH=/archive/Dmitry.Dukhovskoy/${expt}
export DOUT=/work/Dmitry.Dukhovskoy/run_output/${expt}
export DUMP=/work/Dmitry.Dukhovskoy/run_output/${expt}/dump
export YR=1993
export df=5

#mkdir -pv $DUMP
cd $DOUT/${YR}

#for MM in $( ls -d ?? )
for MM in 01 02 03 04 05 06 07 08 09 10 11 12
do
  cd $DOUT/${YR}/${MM}
  pwd
  icc=$(( df-1 ))
  for FL in $( ls ocean_*.nc ); do
    icc=$(( icc+1 ))
    if [[ icc -lt $df ]]; then
      echo "$icc moving $FL ---> $DUMP/"
      /bin/mv $FL $DUMP/.
    else
      echo "leaving $FL"
      icc=0
    fi
#    /bin/mv $fltar $DUMP/.
  done
done

exit 0 

