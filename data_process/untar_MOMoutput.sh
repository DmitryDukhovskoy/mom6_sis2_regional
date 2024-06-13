#!/bin/bash -x
#
# Untar output files
# tar zipped files are typically kept on archive 
#
set -u

export expt=NEP_BGCphys_GOFS

export DARCH=/archive/Dmitry.Dukhovskoy/${expt}
export DOUT=/work/Dmitry.Dukhovskoy/run_output/${expt}
export DUMP=/work/Dmitry.Dukhovskoy/run_output/${expt}/dump
export YR=1993

mkdir -pv $DUMP
cd $DOUT/${YR}

#for MM in $( ls -d ?? )
for MM in 05
do
  cd $DARCH/${YR}/$MM
  mkdir -pv $DOUT/${YR}/${MM}

  for fltar in $( ls *.tar.gz )
  do
    echo "Untarring ${fltar}"
    tar -xzvf $fltar -C $DOUT/${YR}/${MM}
    wait

#    /bin/mv $fltar $DUMP/.

  done
done

exit 0 

