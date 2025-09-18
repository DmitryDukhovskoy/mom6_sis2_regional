#!/bin/bash 
# Prepare restart, OBC, runoff links for ice relax run 
# for specified year
#  link history or restart directories between the hindcasts 
#  asuumed similar dir structure
#
set -u

usage() {
  echo "Usage: $0 --year 1994 jnmb 210776438"
  echo "  --year  year of the forcing fields"
  echo "  --jnmb  run job number where restart files are"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --year)
      YR=$2
      shift 2 # Move past the flag and its arg. to the next flag
      ;;
    --jnmb)
      jnmb=$2
      shift 2
      ;;
    *)
    echo "Error: Unrecognized option $1"
    usage
    ;;
  esac
done

sfx=NEP_irlx
DSRC=/ncrc/home1/Dmitry.Dukhovskoy/scripts/seasonal_fcst
DRUN=/gpfs/f6/ira-cefi/scratch/Dmitry.Dukhovskoy/work/NEP_irlx_test/INPUT
NEP_WORLD=/gpfs/f6/ira-cefi/world-shared/NEP_input
DNEP=/gpfs/f6/ira-cefi/scratch/Dmitry.Dukhovskoy/NEP_data/forecast_input_data
RST=${DRUN}/../${sfx}_${jnmb}

echo "Setting forcing and restart files for ${YR}"
${DSRC}/link_f6era5_files.sh --year ${YR}

YRp1=$(( YR+1 ))
ln -sf "${DNEP}/sis2/PIOMASv21_ithkn_iconc_${YR}_${YRp1}_monthly.nc" irelax_thkn_conc.nc
ln -sf "${NEP_WORLD}/runoff/glofas_v4/glofas_v4_hill_dis_runoff_${YR}.nc" glofas_v4_hill_dis_runoff.nc
ln -sf "${NEP_WORLD}/obcs/glorys/nep_10km_glorys_obcs_${YR}.nc" obcs.nc

# Restart from previous year
# May need different files for 1st year
if [ -d $RST ]; then
  ln -sf $RST/ice_model.res.nc ice_model.res.nc
  ln -sf $RST/coupler.res coupler.res
  ln -sf $RST/MOM.res.nc MOM.res.nc 
else
  echo "Restart dir does not exist: $RST "
  exit 5
fi


exit 0


