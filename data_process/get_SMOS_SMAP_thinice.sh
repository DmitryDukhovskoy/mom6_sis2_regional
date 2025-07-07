#/bin/bash -x
#
# Copy daily sea ice conc data from Near-Real Time NOAA NSIDC 
#
export YRS=0
export YRE=0
dlt_day=1

usage() {
  echo "Usage: $0 --yrs 1994 --yre 1995"
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
  echo "ERROR: YR=${YRS}: specify year to download"
  usage
fi

if [[ $YRE -eq 0 ]]; then
  YRE=$YRS
fi

for (( YR=YRS; YR<=YRE; YR+=1 )); do
  echo "Delivering year $YR ..."
  export DATADR=/work/Dmitry.Dukhovskoy/data/SMOS_SMAP_thin_ice/${YR}
  export url=https://data.seaice.uni-bremen.de/smos_smap/archive/netCDF/north

  mkdir -pv $DATADR
  cd $DATADR
  if [[ $YR -le 2018 ]]; then
    fsfx=v100
  else
    fsfx=v200
  fi

  for (( mo=1; mo<=12; mo+=1 )); do
    # Frist record is 2015/03/31
    if [[ YR -eq 2015 && mo -lt 4 ]]; then
      continue
    fi
    mo0=$( echo $mo | awk '{printf("%02d", $1)}' )

    for (( mday=1; mday<=31; mday+=dlt_day )); do
      if [[ $mo -eq 2 && $mday -gt 29 ]]; then
        continue
      elif [[ $mo -eq 4 || $mo -eq 6 || $mo -eq 9 || $mo -eq 11 ]]; then
        if [[ $mday -gt 30 ]]; then
          continue
        fi
      fi
    
      mday0=$( echo $mday | awk '{printf("%02d", $1)}' )
      flnm=${YR}${mo0}${mday0}_north_mix_sit_${fsfx}.nc	

      echo "Fetching $url/$flnm"
      wget $url/$flnm

    done
  done

  pwd
  echo "Done $YR "
  echo "    "

done

exit 0
