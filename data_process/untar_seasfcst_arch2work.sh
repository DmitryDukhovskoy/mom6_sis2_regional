#!/bin/bash -x
#
# Untar output files for several ensmble runs
# tar zipped files are typically kept on archive 
# usage: 
# [sbatch] untar_seasfcst_arch2work.sh yr_start mo_start ens1 ens2
#
set -u

if [[ $# < 4 ]]; then
  echo "usage: untar_seasfcst_arch2work.sh yr_start mo_start ens1 ens2"
  exit 1
fi

yr_start=$1
mo_start=$2
ens1=$3
ens2=$4

# F/cast months to extract, 1 <= mo <= 12
export mo1=1
export mo2=11

echo "Untarring performed for forecast months ${mo1}-${mo2} wrt to ${yr_start}/${mo_start}"
export varnm=oceanm # oceanm or icem
export RARCH=/archive/Dmitry.Dukhovskoy/fre/NEP/seasonal_ensembles/
export DUMP=/work/Dmitry.Dukhovskoy/run_output/seasonal_ensembles_climOB/dump
export DSFX=gfdl.ncrc5-intel22-repro/history

mkdir -pv $DUMP

cd $RARCH

# Some output files have been tared some remain in directories by oceanm_YYYYMM/ untarred
mm_start=$( echo $mo_start | awk '{printf("%02d", $1)}' )
for expt in $( ls -d NEPphys_frcst_climOB_${yr_start}-${mm_start}-e?? )
do
  cd $RARCH
  sfx=$( echo $expt | cut -d"_" -f4 )
  YR=$( echo $sfx | cut -d"-" -f1 )
  MO=$( echo $sfx | cut -d"-" -f2 )
  ens=$( echo $sfx | cut -d"-" -f3 )
  nens=${ens#*e}
  if (( 10#$nens >= 10#$ens1 && 10#$nens <= 10#$ens2 )); then
    export DARCH=$RARCH/${expt}/${DSFX}
    cd ${DARCH}
    pwd
    # check if tar exists if not assume output in YYYYMM dirs untarred
    # then create symbolic links
    ntars=$( ls -l ${varnm}*gz 2>/dev/null | wc -l )  
    if (( $ntars == 0 )); then
      echo "output fields have not been tarred, create symb links"

      export DOUT=/work/Dmitry.Dukhovskoy/run_output/seasonal_ensembles_climOB/${expt}
      mkdir -pv ${DOUT}
      cd $DOUT
      pwd 
      ln -sf ${DARCH}/${varnm}_?????? .
      ls -l
    else
      cc=0
      for ftar in $( ls ${varnm}*gz )
      do
        cc=$(( cc+1 ))
        if (( $cc >= 10#$mo1 && $cc <= 10#$mo2 )); then
          tarbase=$( echo $ftar | cut -d"." -f1 )
          export DOUT=/work/Dmitry.Dukhovskoy/run_output/seasonal_ensembles_climOB/${expt}/${tarbase}
          mkdir -pv ${DOUT}
          echo "Untarring $ftar ---> $DOUT"

          /bin/tar -xvf ${ftar} -C $DOUT
          wait

          ls -l $DOUT/.
        fi
      done
    fi
  fi
done

echo "All done"

exit 0 

