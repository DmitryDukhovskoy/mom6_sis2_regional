#!/bin/bash 
#
# zip and move tar files from Jessies directory 
# usage: 
# [sbatch] move_tarfiles.sh 
#
set -u

export DR=/archive/Jessie.Liu/fre/cefi/NEP/2024_08
export DOUT=/archive/Dmitry.Dukhovskoy/Jessie_runs

#for drnm in NEP10k_082024_control_prod NEP10k_082024_atm_climat_prod \
#    NEP10k_082024_atm_climat_var_pro NEP10k_082024_obc_climat_prod; do
#for drnm in NEP10k_082024_control_prod; do
#for drnm in NEP10k_082024_atm_climat_prod; do
#for drnm in NEP10k_082024_atm_climat_var_prod; do
for drnm in NEP10k_082024_obc_climat_prod; do
  drin=${DR}/${drnm}/gfdl.ncrc5-intel23-repro/history
  drsave=${DOUT}/$drnm

  mkdir -pv $drsave

  cd $drin
  ls -l

  for fltar in $( ls *.nc.tar ); do
    if [ -s ${drsave}/${fltar}.gz ]; then 
      echo "${drsave}/${fltar}.gz exists, skipping ..."
      continue
    fi
    echo "copying $fltar to --> ${drsave} ..."
    /bin/cp $fltar $drsave/.
    wait

    cd $drsave
    echo "zipping $fltar ..."
    gzip $fltar
    
    cd $drin
  done
done

exit 0


