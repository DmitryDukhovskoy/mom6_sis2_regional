#!/bin/bash 
#
# Postprocess all output after NEP BGC spinup
# untar and arrange archive files (both standard and N-daily output)
# rename and zip restart files
# in restart files - add date stamp in the file name
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
export PLTF=gfdl.ncrc6-intel23-repro
export expt_grp=NEPbgc_nudged_spinup     # experiment group name
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
  MM=$(echo "YRDAY2MDAY" | awk -f ${DAWK}/dates.awk y01=$YY d01=$jday | awk '{printf("%02d",$2)}')
  mday=$(echo "YRDAY2MDAY" | awk -f ${DAWK}/dates.awk y01=$YY d01=$jday | awk '{printf("%02d",$3)}')
}

function untar_dir {
  local WDIR=$1
  local tar_file=$2
  local date_file=$3
  local yr=$4
  local DIROUT=$5

  cd "$WDIR" || { echo "Failed to cd into $WDIR"; return 1; }

  if [[ -f "$tar_file" ]]; then
    mkdir -p "${DIROUT}"
    tar -xvf "$tar_file" -C "${DIROUT}"
    status=$?

    nfintar=$( tar tvf ${tar_file} | grep -v '^d' | wc -l ) # exclude dirs
    cd "${DIROUT}" || return 1
    if [[ -d "${date_file}.metadata.out" &&\
          -n "$(ls -A "${date_file}.metadata.out")" ]]; then  
      for fl in "${date_file}.metadata.out"/*; do
        mv "$fl" .
      done
      /bin/rmdir "${date_file}.metadata.out"
    fi

    cd "$WDIR"
    nfiles=$(find "${DIROUT}" -type f | wc -l) # N files untarred in output dir
    
    if [[ $status -eq 0 && $nfiles -eq $nfintar ]]; then
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
  echo "Processing ascii output  ${yr}"
  cd $ASCDIR
  pwd

  # Should be 1 tar with date stamp = YYYYMMDD:
  # Check if tar file  exists:
  ntar=$( ls -l ${yr}????.*.tar 2>/dev/null | wc -l )
  if [[ $ntar -eq 0 ]]; then
    echo "tar file does not exist, skipping ..."
    continue
  fi

  for fltar in $( ls ${yr}*.tar ); do
    date_ascii=$( echo $fltar | cut -d"." -f1 )
    echo "Processing ascii $date_ascii" 
    fascii_tar=${date_ascii}.ascii_out.tar
    untar_dir "$ASCDIR" "$fascii_tar" "$date_ascii" "$yr" "$date_ascii"
    untar_status=$?

    if [[ $untar_status -ne 0 ]]; then
      echo "WARNING: Failed to untar $fascii_tar in $ASCDIR"
      continue
    fi
  done
done

# Restart:
# Note the date on restart tars are restart date not the
# initialization date !!!
for (( yr=$YR1; yr<=$YR2; yr+=1 )); do
  yr_restart=$(( yr + 1 ))
  echo "Processing restart files from ${yr} run for restart year: ${yr_restart}"
  cd ${RSTDIR}
  pwd

  ntar=$( ls -l ${yr_restart}????*tar 2>/dev/null | wc -l )
  if [[ $ntar -eq 0 ]]; then
    echo "tar restart file does not exist, skipping ..."
    
  else
    for fltar in $( ls ${yr_restart}*.tar ); do 
      date_rest=$( echo $fltar | cut -d"." -f1 )
      echo "Processing restart: $date_rest" 

      frest_tar=${date_rest}.tar
      untar_dir "$RSTDIR" "$frest_tar" "${date_rest}" "$yr" "restdate_${date_rest}"
      untar_status=$?

      if [[ $untar_status -ne 0 ]]; then
        echo "WARNING: Failed to untar $frest_tar in $RSTDIR"
        continue
      fi
    done    
  fi

  for fdir in $( ls -d restdate_${yr_restart}* ); do
    # Rename restart files, add restart date:
    cd ${RSTDIR}/$fdir
    date_rest=$( echo $fdir | cut -d"_" -f2 )
    for ftr in ice_cobalt MOM ice_model ocean_cobalt_airsea_flux; do
      flin="${ftr}.res.nc"
      flout="${ftr}_${date_rest}.res.nc"
      if [ -f $flin ]; then
        echo "Renaming ${flin} --> ${flout}"
        /bin/mv $flin $flout
      fi
    done
    [ -f coupler.res ] && /bin/mv coupler.res coupler_${date_rest}.res

    for i in {1..7}; do
      flin="MOM.res_${i}.nc"
      flout="MOM_${date_rest}.res_${i}.nc"
      if [ -f "$flin" ]; then 
        echo "Renaming $flin --> $flout"
        mv "$flin" "$flout"
      fi
    done
  done

done


# History archives
for (( yr=$YR1; yr<=$YR2; yr+=1 )); do
  echo "Processing archive files ${yr}"
  cd ${HSTDIR}
  pwd

  ntar=$( ls -l ${yr}????.nc.tar 2>/dev/null | wc -l )
  if [[ $ntar -eq 0 ]]; then
    echo "tar restart file does not exist ..."
  else
    for fltar in $( ls *${yr}*.tar ); do
      date_hist=$( echo $fltar | cut -d"." -f1 )
      echo "Processing history archives: $date_hist" 
      pwd

      fhist_tar=${date_hist}.nc.tar
      untar_dir "$HSTDIR" "$fhist_tar" "$date_hist" "$yr" "$date_hist"
      untar_status=$?

      if [[ $untar_status -ne 0 ]]; then
        echo "WARNING: Failed to untar $fhist_tar in $HSTDIR"
        continue
      fi
    done
  fi

  # Rename archive files:
  # Get rid of the leading time stamp in the file names:
  # WARNING: it may override files from different tar files
  #   e.g., 19931001.ice_month.nc  --->  ice_month.nc
  echo "Renaming archives if needed "
  cd $HSTDIR
  for YDR in $( ls -d ${yr}* ); do
    cd "$YDR" || exit 1
    pwd
    for FL in ${yr}????.*.nc; do
      [ -f "$FL" ] || continue  # Skip if no match
      fldname=$(echo "$FL" | cut -d"." -f2)
      echo "$FL ---> ${fldname}.nc"
      /bin/mv "$FL" "${fldname}.nc"
    done
  done
done

echo "All done"

exit 0
