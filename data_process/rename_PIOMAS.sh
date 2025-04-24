#!/bin/bash -x
#
set -u

DDIR=/work/Dmitry.Dukhovskoy/data/PIOMAS_ice
cd "$DDIR" || exit 1

#for file in piomas20c_*_v21.nc; do
for file in $( ls piomas20c_*_v21.nc ); do
  fnew=$(echo "$file" | sed 's|20c||')
  echo "Moving $file ---> $fnew"

  /bin/mv "$file" "$fnew"
done

exit 0
  


