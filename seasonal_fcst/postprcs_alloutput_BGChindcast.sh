#!/bin/bash 
#
# Postprocess all output after NEP BGC spinups/nudged hindcasts:
# untar and arrange archive files (both standard and N-daily output)
# rename and zip restart files
# 
# 
# Rename output files dumped from NEP MOM6-SIS2
# from gaea to PPAN archive
#
# Assumed file naming is YYYYMMDD.oceanm_YYYY_DDD.nc
# File structure should follow a pattern 
#
set -u

export REG=NEP
export EXPT=hindcast_bgc
export PLTF=gfdl.ncrc5-intel23-repro
export expt_grp=NEPbgc_nudged_spinup    # experiment group name
export DARCH=/archive/Dmitry.Dukhovskoy/fre/${REG}/${EXPT}/${expt_grp}
export oprfx=oceanm    # ocean daily fields naming
export iprfx=icem      # ice daily fields naming
export DAWK=/home/Dmitry.Dukhovskoy/scripts/awk_utils
export SRCD=/home/Dmitry.Dukhovskoy/scripts/seasonal_fcst

function get_month_mday {
  local FL=$1
  local bname=$( echo ${FL} | cut -d"." -f 1 )
  local year=$( echo ${bname} | cut -d "_" -f 2 )
  local jday=$( echo ${bname} | cut -d "_" -f 3 )
# Assign values to global variables:
  YY=$year
  MM=`echo "YRDAY2MDAY" | awk -f ${DAWK}/dates.awk y01=$YY d01=$jday | awk '{printf("%02d",$2)}'`
  mday=`echo "YRDAY2MDAY" | awk -f ${DAWK}/dates.awk y01=$YY d01=$jday | awk '{printf("%02d",$3)}'`
}

function untar_dir {
  local WDIR=$1
  local tar_file=$2
  local date_file=$3
  local yr=$4

  cd "$WDIR" || { echo "Failed to cd into $WDIR"; return 1; }

  if [[ -f "$tar_file" ]]; then
    mkdir -p "${yr}"
    tar -xvf "$tar_file" -C "${yr}"
    status=$?

    cd "${yr}" || return 1
    if [[ -d ${date_file}.metadata.out ]]; then
      for fl in ${date_file}.metadata.out/*; do
        mv "$fl" .
      done
      /bin/rmdir "${date_file}.metadata.out"
    fi

    cd "$WDIR"
    nfiles=$(find "${yr}" -type f | wc -l)
    if [[ $status -eq 0 && $nfiles -gt 0 ]]; then
      echo "Extraction successful. Removing ${tar_file}"
      /bin/rm "${tar_file}"
    else
      echo "Warning: tar extraction may have failed or yielded no files."
    fi
  else
    echo "Tar file $tar_file not found!"
    return 1
  fi
}

usage() {
  echo "Usage: $0 --ys 1994 --ye 1994"
  echo "  --ys          start with this init year to pprcs the f/cast <-- Required" 
  echo "  --ye          end with this f/cast init year, default=same as ys"
  exit 1
}


if [[ $# -lt 1 ]]; then
  echo "ERROR: specify year to start/end"
  usage
fi


YR2=0
if [[ $# == 1 ]] && [[ $1 =~ ^[0-9]+ ]]; then
  YR1=$1
  YR2=$YR1
else
  # input with key arguments:
  # Parse the command-line arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      --ys)
        YR1=$2
        shift 2 # Move past the flag and its arg. to the next flag
        ;;
      --ye)
        YR2=$2
        shift 2
        ;;
      *)
      echo "Error: Unrecognized option $1"
      usage
      ;;
    esac
  done
fi

if [[ $YR2 -eq 0 ]]; then
  YR2=$YR1
fi

expt_name=$expt_grp

echo "Processing outputs for $YR1-$YR2"

/bin/cp $DAWK/dates.awk .

# Change dir structure:
DNEW=$DARCH
if [[ -d "$DARCH/${PLTF}" ]]; then
  cd $DARCH/${PLTF}
  mkdir -pv $DNEW
  for dout in history restart ascii; do
    echo "Moving $DARCH/${PLTF}/$dout ---> $DNEW/$dout"
    /bin/mv -f $DARCH/${PLTF}/$dout $DNEW/.
  done
  cd $DARCH
  /bin/rmdir $DARCH/$PLTF
else
  echo " Output has already been moved to post-processed directories, skipping this step ... "
fi

HSTDIR=$DNEW/history
RSTDIR=$DNEW/restart
ASCDIR=$DNEW/ascii

# ASCII output files: log files, err files, stat files, remove all *logfile.*.out from PE
for (( yr=$YR1; yr<=$YR2; yr+=1 )); do
  echo "Processing ${yr}"
  echo "Processing ascii output"
  cd $ASCDIR
  pwd

  # Should be 1 tar with date stamp = YYYYMMDD:
  # Check if tar file  exists:
  ntar=$( ls -l ${yr}????.*.tar | wc -l )
  if [[ $ntar -eq 0 ]]; then
    echo "tar file does not exist, skipping ..."
    continue
  fi

  date_ascii=$( ls *${yr}*.tar | cut -d"." -f1 )

  echo "Processing ascii $date_ascii" 
  pwd

  fascii_tar=${date_ascii}.ascii_out.tar
  untar_dir "$ASCDIR" "$fascii_tar" "$date_ascii" "$yr"
  untar_status=$?

  if [[ $untar_status -ne 0 ]]; then
    echo "WARNING: Failed to untar $fascii_tar in $ASCDIR"
    continue
  fi
done

# Restart:
for (( yr=$YR1; yr<=$YR2; yr+=1 )); do
  echo "Processing restart files ${yr}"
  cd ${RSTDIR}
  pwd

  ntar=$( ls -l ${yr}????*tar | wc -l )
  if [[ $ntar -eq 0 ]]; then
    echo "tar restart file does not exist, skipping ..."
    continue
  fi
  
  date_rest=$( ls *${yr}*.tar | cut -d"." -f1 )

  echo "Processing restart: $date_rest" 
  pwd

  frest_tar=${date_rest}.tar
  untar_dir "$RSTDIR" "$frest_tar" "$date_rest" "$yr"
  untar_status=$?

  if [[ $untar_status -ne 0 ]]; then
    echo "WARNING: Failed to untar $frest_tar in $RSTDIR"
    continue
  fi
done


# History archives
for (( yr=$YR1; yr<=$YR2; yr+=1 )); do
  echo "Processing archive files ${yr}"
  cd ${HSTDIR}
  pwd

  ntar=$( ls -l ${yr}????.nc.tar | wc -l )
  if [[ $ntar -eq 0 ]]; then
    echo "tar restart file does not exist, skipping ..."
    continue
  fi

  date_hist=$( ls *${yr}*.tar | cut -d"." -f1 )

  echo "Processing history archives: $date_hist" 
  pwd

  fhist_tar=${date_hist}.nc.tar
  untar_dir "$HSTDIR" "$fhist_tar" "$date_hist" "$yr"
  untar_status=$?

  if [[ $untar_status -ne 0 ]]; then
    echo "WARNING: Failed to untar $fhist_tar in $HSTDIR"
    continue
  fi

  # Rename archive files:
  # Get rid of the leading time stamp in the file names:
  cd $HSTDIR/$yr
  for FL in $( ls ${date_hist}.*.nc ); do
    fldname=$( echo ${FL} | cut -d"." -f 2)
    echo "$FL ---> ${fldname}.nc"
    /bin/mv $FL ${fldname}.nc
  done
 
done

echo "All done"

exit 0
