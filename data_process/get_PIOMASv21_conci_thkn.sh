#/bin/bash -x
#
#  Download PIOMAS sea ice fields for createing relaxation fields
#  https://psc.apl.uw.edu/research/projects/arctic-sea-ice-volume-anomaly/data/model_grid
#  
# Ice concentration assimilated from sat. obs:
# PIOMAS model (v2.1)  grid data include model output for 1978-present. 
#
# Download Monthly mean (daily also available) thickness (=volume/unit area m3/m2)
# daily for partila area (monthly not available)
# save by years
# 
export YRS=0
export YRE=0

usage() {
  echo "Usage: $0 --yrs 1994 --yre 1995"
  echo "  --yrs         year to start downloading data"
  echo "  --yre         year to end the download, default=1 year"
  exit 1
}

get_data() {
  url=$1
  file_in=$2
  file_new=$3

  echo "Fetching $url/${file_in}.gz"
  wget --no-check-certificate ${url}/${file_in}.gz
  status=$?
  if [[ $status == 0 ]]; then
    gunzip ${file_in}.gz
    /bin/mv $file_in $file_new
  else
    echo "Failed to get $file_in"
  fi

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

if [[ $YRS -lt 1979 ]]; then
  echo "PIOMASv2.1 covers 1979 - present, start year should be after 1978, requested $YRS"
  exit 1
fi


for (( YR=YRS; YR<=YRE; YR+=1 )); do
  echo "Delivering year $YR ..."
  export DATADR=/work/Dmitry.Dukhovskoy/data/PIOMAS_ice
  export urlc=https://pscfiles.apl.washington.edu/zhang/PIOMAS/data/v2.1/area
  export urlh=https://pscfiles.apl.uw.edu/zhang/PIOMAS/data/v2.1/heff

  #mkdir -pv $DATADR
  cd $DATADR

  flthkn=heff.H${YR}.nc
  flthkn_new=piomas_heff${YR}_v21.nc
  flconc=area.H${YR}.nc
  flconc_new=piomas_area${YR}_v21.nc

  get_data $urlh $flthkn $flthkn_new
  get_data $urlc $flconc $flconc_new

  pwd
  echo "Done $YR "
  echo "    "

done

exit 0
