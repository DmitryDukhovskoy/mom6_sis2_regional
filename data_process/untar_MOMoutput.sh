#!/bin/bash -x
#
# Untar output files
# tar zipped files are typically kept on archive 
#
set -u

#export expt=NEP_BGCphys_GOFS
export expt=NEP_LZRESCALE

export DARCH=/archive/Dmitry.Dukhovskoy/${expt}
export DOUT=/work/Dmitry.Dukhovskoy/run_output/${expt}
export DUMP=/work/Dmitry.Dukhovskoy/run_output/${expt}/dump
export YR=1994

mkdir -pv $DUMP
cd $DOUT/${YR}

#for MM in $( ls -d ?? )
#for MM in 01 02 03 06 07 09 10 12
for MM in 01 02 03
do
  MM=$(echo $MM | awk '{printf("%02d", $1)}')
  if [ ! -d $DARCH/${YR}/$MM ]; then
    echo "does not exist: $DARCH/${YR}/$MM"
    continue
  fi
  cd $DARCH/${YR}/$MM
  mkdir -pv $DOUT/${YR}/${MM}

  for fltar in $( ls *.tar.gz )
#  for fltar in $( ls *_3.tar.gz )
  do
    echo "Untarring ${fltar}"
    tar -xzvf $fltar -C $DOUT/${YR}/${MM}
    wait

#    /bin/mv $fltar $DUMP/.

  done
done

exit 0 

