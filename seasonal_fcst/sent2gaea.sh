#!/bin/bash
set -u

if [[ $# < 1 ]]; then
  echo "Usage: sent2gaea.sh file_to_send"
  exit 5
fi

fl=$1
DG=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/NEP_data/forecast_input_data/sis2
echo "$fl --> gaea:${DG}"
gcp $fl  gaea:$DG/.

exit 0
