#/bin/bash -x
#
# Copy daily sea ice conc data from Near-Real Time NOAA NSIDC 
#
export YR=1994
export DATADR=/home/Dmitry.Dukhovskoy/work_data/NRT_NOAA_NSIDC_seaconc/$YR
export url=https://noaadata.apps.nsidc.org/NOAA/G02202_V4/north/daily/${YR}

mkdir -pv $DATADR
cd $DATADR

for (( mo=1; mo<=12; mo+=1 )); do
  mo0=$( echo $mo | awk '{printf("%02d", $1)}' )

  for (( mday=1; mday<=31; mday+=1 )); do
    mday0=$( echo $mday | awk '{printf("%02d", $1)}' )
    flnm=seaice_conc_daily_nh_${YR}${mo0}${mday0}_f11_v04r00.nc

    echo "Fetching $url/$flnm"
    wget $url/$flnm

  done
done

pwd

exit 0
