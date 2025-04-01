#/bin/bash -x
#
# Copy monthly sea ice conc data from Near-Real Time NOAA NSIDC 
#
export YRS=0
export YRE=0

usage() {
  echo "Usage: $0 --yrs 1994 --yre 1995 --dday 5"
  echo "  --yrs         year to start downloading data"
  echo "  --yre         year to end the download, default=1 year"
  exit 1
}


if [[ $# -lt 1 ]]; then
  echo "ERROR: specify year to download"
  usage
fi

while [[ $# -gt 0 ]]; do
  case $1 in
    --yrs)
      YRS=$2
      shift 2 # Move past the flag and its arg. to the next flag
      ;;
    --yre)
      YRE=$2
      shift 2
      ;; 
    *)
    echo "Error: Unrecognized option $1"
    usage
    ;;
  esac
done

if [[ $YRS -eq 0 ]]; then
  echo "ERROR: YR=${YR}: specify year to download"
  usage
fi

if [[ $YRE -eq 0 ]]; then
  YRE=$YRS
fi

for (( YR=YRS; YR<=YRE; YR+=1 )); do
  echo "Delivering year $YR ..."
  export DATADR=/work/Dmitry.Dukhovskoy/data/NRT_NOAA_NSIDC_seaconc/${YR}_mnth
  export url=https://noaadata.apps.nsidc.org/NOAA/G02202_V4/north/monthly/

  mkdir -pv $DATADR
  cd $DATADR

  for (( mo=1; mo<=12; mo+=1 )); do
    mo0=$( echo $mo | awk '{printf("%02d", $1)}' )

    vrs=v04r00
    if [[ $YR -lt 1995 ]]; then
      fsfx='f11'
    fi
    if [[ $YR -eq 1995 ]] && [[ $mo -ge 10 ]]; then
      fsfx='f13'
    fi
    if [[ $YR -ge 1996 ]]; then
      fsfx='f13'
    fi
    if [[ $YR -ge 2008 ]]; then
      fsfx='f17'
    fi

    mday0=$( echo $mday | awk '{printf("%02d", $1)}' )
    flnm=seaice_conc_monthly_nh_${YR}${mo0}_${fsfx}_${vrs}.nc

    echo "Fetching $url/$flnm"
    wget $url/$flnm

  done

  pwd
  echo "Done $YR "
  echo "    "

done

exit 0
