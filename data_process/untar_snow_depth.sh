#!/bin/bash -x
#Untar snow depth NASA data
# downloaded from
# https://earth.gsfc.nasa.gov/cryo/data/antarctic-snow-depth-sea-ice
#
set -u

DTAR=/work/Dmitry.Dukhovskoy/data/snow_nasa
cd "${DTAR}" || { echo "Failed cd to ${DTAR}"; exit 1; }
pwd

for ftar in s*hs.tar; do
  YR="${ftar:1:4}"
  echo "Processing ${YR}"
  mkdir -pv "${YR}"
  mv "$ftar" "${YR}/."
  cd "${YR}" || { echo "Failed cd to ${YR}"; exit 1; }

  tar xvf "${ftar}"
  if [ $? -eq 0 ]; then
    rm "${ftar}"
  fi

  for fl in s*.hs.gz; do
    echo "unzipping $fl"
    gunzip "$fl"
  done

  cd ${DTAR}

done

echo "All done"

exit 0 

