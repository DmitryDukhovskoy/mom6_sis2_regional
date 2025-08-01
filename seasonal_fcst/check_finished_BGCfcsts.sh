#!/bin/bash 
#
# Check all finished runs for dailyOB expt=01 or 02 (multi-ens OBs)
# ./check_finished_runs.sh [YR1] [expt_nmb] 
set -u

usage() {
  echo "Usage: $0 --ys 1994 [--ye 1995] [--mm 4] --ens 1,...,10 "
  echo "  --ys     start with this year" 
  echo "  --ye     end with this year"
  echo "  --all    >0, all years "
  echo "  --mm     month to process, default (1,4,7,10)"
  echo "  --ens    SPEAR ens. run to process, default all: (1,...,10)"
  echo "  --ensE   set a range of ensembles: [ens, ..., ensE], ensE>=ens, optional"
  echo "  --short  >0: short summary, does not printout detailes, default = 0"
  exit 1
}

function report_result {
  local yr=$1
  local MM=$2
  local ens=$3
  local fldnm=$4
  local nfiles=$5
  local size=$6
  echo "    ${yr}-${MM}-e${ens} ${fldnm} : N files = ${nfiles}  Size = ${size}"
}

export EXPT=NEPbgc_fcst_dailyOB
export expt_nmb=01
export PLTF="gfdl.ncrc6-intel23-repro"
export DAWK=/home/Dmitry.Dukhovskoy/scripts/awk_utils

YR1=0
YR2=0
MONTHS=(1 4 7 10)
ENSMB=(1 2 3 4 5 6 7 8 9 10)
ens1=0
ens2=0
short=0
all=0

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
    --all)
      all=$2
      shift 2
      ;;
    --mm)
      MONTHS=($2)
      shift 2
      ;;
    --ens)
      ens1=$2
      shift 2
      ;;
    --ensE)
      ens2=$2
      shift 2
      ;;
    --short)
      short=$2
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

if [[ $YR1 -eq 0 && $all -eq 0 ]]; then
  usage
fi

if [[ $all -gt 0 ]]; then
  YR1=1993
  YR2=2024
fi

if [[ $YR2 -eq 0 ]]; then
  YR2=$YR1
fi

if [[ $YR1 -lt 1900 ]] || [[ $YR2 -lt 1900 ]]; then
  echo "ERROR: Check input years YR1=$YR1 YR2=$YR2 "
  usage
fi

# If ens. range is requested, redifine ENSMB array:
if [[ $ens1 -gt 0 ]] && [[ $ens2 -eq 0 ]]; then
  ens2=$ens1
fi

if [[ $ens1 -gt 0 ]]; then
  ENSMB=()
  for (( ii=ens1; ii<=ens2; ii++ )); do
    ENSMB+=($ii)
  done
fi

echo "Checking finished runs for ${YR1}-${YR2} MM=${MONTHS[@]} ens=${ENSMB[@]}" 

export EXPT_NAME=${EXPT}${expt_nmb}
export DDUMP=/archive/Dmitry.Dukhovskoy/fre/NEP/forecast_bgc
export DARCH=/archive/Dmitry.Dukhovskoy/fre/NEP/forecast_bgc/${EXPT_NAME}


# Post-processed, rearranged output files:
if [ -d $DARCH ]; then
  cd $DARCH
  for (( YR=$YR1; YR<=$YR2; YR+=1 )); do
    for MM in ${MONTHS[@]}; do
      MM0=$(printf "%02d" "$MM")
      for ens_run in ${ENSMB[@]}; do
        ens0=$( echo $ens_run | awk '{printf("%02d",$1)}' )
        DIROUTP="${YR}-${MM0}-e${ens0}"
        cd $DARCH
        #pwd
        #echo $DIROUTP
        if [ -d "$DIROUTP" ]; then
          cd "$DIROUTP/history"
          # COBALT
          shopt -s nullglob
          files=(*cobalt*.nc)
          ncob=${#files[@]}
          shopt -u nullglob
          cobsize=$(du -ch *cobalt* 2>/dev/null | grep total | cut -f1)

          # OCEAN excluding cobalt files:
          nocn=$(find . -type f -name "*ocean*" ! -name "*ocean_cobalt*" | wc -l)
          ocnsize=$(find . -type f -name "*ocean*" ! -name "*ocean_cobalt*" -print0 | \
                    du --files0-from=- -ch | tail -n 1 | cut -f1)

          # Ice :
          nice=$( find . -type f -name "*ice*" | wc -l )
          icesize=$(find . -type f -name "*ice*" -print0 | \
                    du --files0-from=- -ch | tail -n 1 | awk '{print $1}')
          # Total N files and storage:
          shopt -s nullglob
          files=(*.nc)
          nfiles=${#files[@]}
          shopt -u nullglob
          aa=$( du -ch | tail -1 ) 
          nsize=$( echo $aa | cut -d' ' -f1 )
          if [[ $short -eq 0 ]]; then
            echo "  "
            report_result $YR $MM0 $ens0 "COBALT" $ncob $cobsize
            report_result $YR $MM0 $ens0 "OCEAN" $nocn $ocnsize
            report_result $YR $MM0 $ens0 "ICE" $nice $icesize
          fi
          report_result $YR $MM0 $ens0 "TOTAL" $nfiles $nsize
        else
          echo "    $YR $MM0 $ens0  ---- None ----"
        fi
      done
      echo "==== "
    done
  done
else
  echo "NONE post-processed files"
fi          

# Not post-processed output:
cd $DDUMP
echo " "
echo "Uprocessed tar files"
ntar=0
for (( YR=$YR1; YR<=$YR2; YR+=1 )); do
  for MM in ${MONTHS[@]}; do
    MM0=$(printf "%02d" "$MM")
    nens=0
    for ens_run in ${ENSMB[@]}; do
      ens0=$( echo $ens_run | awk '{printf("%02d",$1)}' )
      DIROUTP="${EXPT_NAME}_${YR}-${MM0}-e${ens0}/gfdl.ncrc6-intel23-repro"
      cd $DDUMP || continue

      if [ -d "$DIROUTP" ]; then
        cd "$DIROUTP/history" || continue
        fltar="${YR}${MM0}01.nc.tar" 
        # Total N files and storage:
        if [ -f $fltar ]; then
          bsize=$( du -b $fltar | cut -f1 )
          ntar=$(( ntar+bsize )) 
          nsize=$( du -ch | tail -1 | cut -f1 )
          nens=$(( nens+1 ))
          if [[ $short -eq 0 ]]; then
            report_result $YR $MM0 $ens0 "TAR TOTAL" 1 $nsize
          fi
        fi
      fi

    done
    echo "    Unprocessed: $YR $MM0:    N ensembles = $nens"
    if [[ $short -eq 0 ]]; then
      echo "  "
    fi
  done
done

if [[ $ntar -eq 0 ]]; then
  echo " NO Uprocessed tar files, size=$ntar"
fi

#echo "All Done"

exit 0

    


