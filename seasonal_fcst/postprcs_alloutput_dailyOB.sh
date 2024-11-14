#!/bin/bash 
#
# Postprocess all output after NEP f/casts:
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
# Usage:  [sbatch] postprcs_fcst_dailyOB.sh YR1 [YR2]
set -u

export REG=NEP
export EXPT=seasonal_daily
export DARCH=/archive/Dmitry.Dukhovskoy/fre/${REG}/${EXPT}
export PLTF=gfdl.ncrc5-intel23-repro
export oprfx=oceanm    # ocean daily fields naming
export iprfx=icem      # ice daily fields naming
#export expt_nmb=01        # forecast run experiment number or forecast group name 
#                       # 01 - with 1 SPEAR ens for OBCs, 02- multi SPEAR ens, etc.
export DAWK=/home/Dmitry.Dukhovskoy/scripts/awk_utils
export SRCD=/home/Dmitry.Dukhovskoy/scripts/seasonal_fcst

if [[ $# -lt 1 ]]; then
  echo "ERROR: specify year to start/end"
  echo "usage: [sbatch] postprcs_fcst_dailyOB.sh YR1 [YR2]"
  exit 1
fi

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
 
YR1=$1
if [[ $# == 1 ]]; then
  YR2=$YR1
else
  YR2=$2
fi

echo "Processing outputs for $YR1-$YR2"

/bin/cp $DAWK/dates.awk .

for (( yr=$YR1; yr<=$YR2; yr+=1 )); do
  cd $DARCH
  for dens in $( ls -d *${yr}-??-e?? ); do
# Assumed nameing NEPphys_frcst_dailyOBXX, XX - expt number
# if not - then expt=01
    bsname=$( echo $dens | cut -d"_" -f3 )
    nchar=$( echo $bsname | wc -m )
    cS=$(( nchar-3 ))
    expt_nmb=${bsname:${cS}:2}
   
    if [[ $expt_nmb -gt 0 ]]; then 
      echo "expt number = ${expt_nmb}"
    else
      expt_nmb=99
      echo "expt number not defined, set it = ${expt_nmb}"
    fi
    expt_name=NEPphys_frcst_dailyOB-expt${expt_nmb}
#  for dens in $( ls -d *${yr}-04-e01 ); do
    fend=$( echo $dens | cut -d"_" -f4 )
    mstart=$( echo $fend | cut -d"-" -f2 )
    ens=$( echo $fend | cut -d"-" -f3 ) 
#
# Change dir structure:
    DNEW=$DARCH/$expt_name/$fend
    mkdir -pv $DNEW
    for dout in history restart ascii; do
      echo "Moving $DARCH/$dens/$PLTF/$dout ---> $DNEW/$dout"
      /bin/mv $DARCH/$dens/$PLTF/$dout $DNEW/.
    done
    cd $DARCH
    /bin/rmdir $DARCH/$dens/$PLTF
    /bin/rmdir $DARCH/$dens
  done
done

for (( yr=$YR1; yr<=$YR2; yr+=1 )); do
  cd $DARCH/$expt_name
  for fend in $( ls -d ${yr}-??-e?? ); do
    mstart=$( echo $fend | cut -d"-" -f2 )
    ens=$( echo $fend | cut -d"-" -f3 ) 
    DNEW=$DARCH/$expt_name/$fend 

# ----------
    echo "Processing run $fend" 

    HSTDIR=$DNEW/history
    RSTDIR=$DNEW/restart
    ASCDIR=$DNEW/ascii

# ASCII output files: log files, err files, stat files, remove all *logfile.*.out from PE
  ascii_sh=postprcs_ascii_dailyOB.sh
  sed -e "s|REG=.*|REG=${REG}|"\
      -e "s|EXPT=.*|EXPT=${EXPT}|"\
      -e "s|PLTF=.*|PLTF=${PLTF}|"\
      -e "s|RSTDIR=.*|RSTDIR=${RSTDIR}|"\
      -e "s|expt_nmb=.*|expt_nmb=${expt_nmb}|"\
      -e "s|DARCH=.*|DARCH=${DARCH}|"\
      -e "s|fend=.*|fend=${fend}|" $SRCD/$ascii_sh > pp_ascii_${fend}.sh

  chmod 700 pp_ascii_${fend}.sh
  ./pp_ascii_${fend}.sh 

# Restart:
  rest_sh=postprcs_restart_dailyOB.sh
#  /bin/cp $SRCD/$rest_sh .
  sed -e "s|REG=.*|REG=${REG}|"\
      -e "s|EXPT=.*|EXPT=${EXPT}|"\
      -e "s|PLTF=.*|PLTF=${PLTF}|"\
      -e "s|RSTDIR=.*|RSTDIR=${RSTDIR}|"\
      -e "s|expt_nmb=.*|expt_nmb=${expt_nmb}|"\
      -e "s|DARCH=.*|DARCH=${DARCH}|"\
      -e "s|fend=.*|fend=${fend}|" $SRCD/$rest_sh > pp_restart_${fend}.sh

  chmod 700 pp_restart_${fend}.sh
  ./pp_restart_${fend}.sh

# Model output - history files
    cd $HSTDIR
    pwd

# Check if tar file  exists:
    ntar=$( ls -l ${yr}${mstart}??.nc.tar | wc -l )

#    if ! [ -s $farch_tar ]; then
#      nftar=0
    if [[ $ntar -eq 0 ]]; then
      echo "tar file does not exist, checking untarred filed ..."
#      continue
# check if daily files have been untarred:
      nftar=$( ls ${yr}${mstart}??.{${oprfx},${iprfx}}_*.nc | wc -l )     
      echo "Found $nftar untarred daily files"
# check standard output files untarred:
      nftar_std=$( ls ${yr}${mstart}??.{ocean,ice}_*.nc | wc -l )
      echo "Found ${nftar_std} untarred standard output files"

# Daily files need to be grouped by months for ease of analysis
# Check renamed daily files but not yet grouped:
      nrenm=$( ls {${oprfx},${iprfx}}_*.nc | wc -l )
      echo "Found ${nrenm} renamed daily files for processing"
# Check renamed standard output files:
# Do not need to group standard files, only get rid off the leading time stamp in the name
      nrenm_std=$( ls {ocean,ice}_*.nc | wc -l )
      echo "Found ${nrenm_std} renamed standard output files, no processing needed"

      if [[ $nftar_std -gt 0 ]]; then
        date_start=$( ls -1 ${yr}${mstart}??.{ocean,ice}_*.nc | head -1 | cut -d"." -f 1 )
        farch_tar=${date_start}.nc.tar
      elif [[ $nftar -gt 0 ]]; then
        date_start=$( ls -1 ${yr}${mstart}??.{${oprfx},${iprfx}}_*.nc | head -1 | cut -d"." -f 1 )
        farch_tar=${date_start}.nc.tar
      elif [[ $nrenm -gt 0 ]]; then
# Guess start date:
        date_start=${yr}${mstart}01
        farch_tar=${date_start}.nc.tar 
      else
        date_start=99999999
        echo "No files found for processing, skipping ..."
        continue
      fi
    else
# Start date of the run from tar name:
      date_start=$( ls ${yr}${mstart}??.nc.tar | cut -d"." -f1 )
      farch_tar=${date_start}.nc.tar

# Check # of ocean, ice files in the tar: 
      nftar=$( tar tvf $farch_tar | grep -E "${oprfx}|${iprfx}" | wc -l )
      nftar_std=$( tar tvf $farch_tar | grep -E "ocean_|ice_" | wc -l )

      tar -xvf $farch_tar
      wait
    fi
    
# Get rid of the leading time stamp in the file names:
    for FL in $( ls ${date_start}.*.nc ); do
      fldname=$( echo ${FL} | cut -d"." -f 2)
      echo "$FL ---> ${fldname}.nc"
      /bin/mv $FL ${fldname}.nc
    done
    nfls=$( ls -l {${oprfx},${iprfx}}*.nc | wc -l )
    nfls_std=$( ls -l {ocean_,ice_}*.nc | wc -l )

    if [[ $nfls -ne $nftar ]] || [[ $nfls_std -ne $nftar_std ]]; then
      echo "Some std output files were not untarred: N untarred=${nfls_std}, N in tar =${nftar_std} ?"
      echo "OR: daily files were not untarred: N untarred=${nfls}, N in the tar=${nftar} ?"
#     exit 1
    else
      echo "Removing $farch_tar"
      /bin/rm -f $farch_tar
    fi

# If there are daily output files, group those otherwise skip:
    if [[ $nfls -eq 0 ]]; then
      echo "No daily output files found, $nfls, skipping ${dens} ..."
      pwd
      continue
    fi
# group daily ocean archive files by months 
    for FL in $( ls ${oprfx}_*.nc ); do
      get_month_mday ${FL}

      DOUT=oceanm_${YY}${MM}
      if [ ! -d $DOUT ]; then
        /bin/mkdir -pv ${HSTDIR}/${DOUT}
      fi
      echo "Moving $FL ---> ${DOUT}"
      /bin/mv $FL $DOUT/.
    done
    
# group daily ice archive files by months 
    for FL in $( ls ${iprfx}_*.nc ); do
      get_month_mday ${FL}

      DOUT=icem_${YY}${MM}
      if [ ! -d $DOUT ]; then
        /bin/mkdir -pv ${HSTDIR}/${DOUT}
      fi
      echo "Moving $FL ---> ${DOUT}"
      /bin/mv $FL $DOUT/.
    done

#    exit 5
  done
done

echo "All done"

exit 0
