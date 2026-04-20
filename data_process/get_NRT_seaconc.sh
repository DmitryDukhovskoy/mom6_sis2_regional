#/bin/bash -x
#
# Copy daily sea ice conc data from Near-Real Time NOAA NSIDC 
#
set -u

export YRS=0
export YRE=0
export dlt_day=1   # skip N days
moS=1
moE=0
regn=north

usage() {
  echo "Usage: $0 --yrs 1994 --yre 1995 --dday 5"
  echo "  --yrs         year to start downloading data"
  echo "  --yre         year to end the download, default=yrs"
  echo "  --dlt_day     number of days to skip for downloaded data, default=${dlt_day}"
  echo "  --ms          month to start download, default=1"
  echo "  --me          month to end download, default=ms"
  echo "  --regn        north or south, default=${regn}"
  exit 1
}


if [[ $# -lt 1 ]]; then
  echo "ERROR: specify year to download"
  usage
fi

vers=6

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
    --dlt_day)
      dlt_day=$2
      shift 2
      ;;
    --ms)
      moS=$2
      shift 2
      ;;
    --me)
      moE=$2
      shift 2
      ;;
    --regn)
      regn=$2
      shift 2
      ;;
    --help)
      usage
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

if [[ $moE -eq 0 ]]; then
  moE=$moS
fi
      
noaa_version=G02202_V${vers}  # Check what version to use on the website
vrs=v0${vers}r00

if [[ $regn == "south" ]]; then
  if (( vers < 6 )); then
    regn_sfx="sh"
  elif (( vers == 6 )); then
    regn_sfx="pss"
  else
    echo "Warning: Unsupported version '$vers' for region 'south'"
  fi
else
  if (( vers < 6 )); then
    regn_sfx="nh"
  elif (( vers == 6 )); then
    regn_sfx="psn"
  else
    echo "Warning: Unsupported version '$vers' for region 'north'"
  fi
fi


for (( YR=YRS; YR<=YRE; YR+=1 )); do
  echo "Delivering year $YR ..."
  export DATADR=/work/Dmitry.Dukhovskoy/data/NRT_NOAA_NSIDC_seaconc/$YR
  export url=https://noaadata.apps.nsidc.org/NOAA/${noaa_version}/${regn}/daily/${YR}

  mkdir -pv $DATADR
  cd $DATADR

  for (( mo=$moS; mo<=$moE; mo+=1 )); do
    mo0=$( echo $mo | awk '{printf("%02d", $1)}' )

    for (( mday=1; mday<=31; mday+=dlt_day )); do
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
     
      if [[ $vers -lt 6 ]]; then
        flnm=seaice_conc_daily_nh_${YR}${mo0}${mday0}_${fsfx}_${vrs}.nc
      elif [[ $vers -eq 6 ]]; then
        flnm=sic_${regn_sfx}25_${YR}${mo0}${mday0}_am2_${vrs}.nc
      fi 

      echo "Fetching $url/$flnm"
      wget $url/$flnm

    done
  done

  pwd
  echo "Done $YR "
  echo "    "

done

exit 0
