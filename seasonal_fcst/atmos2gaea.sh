#!/bin/bash 
#
# Send tar.gz atmos fields to gaea
# if tar bundles do not exist - the script will call
# atmos_tar.sh to create tar.gz files
# 
# Transfer tar atmos fields for N ensembles prepared from SPEAR
# for seasonal ensemble forecasts
#
# Atmos subsets prepared in python:
# /home/Dmitry.Dukhovskoy/python/setup_seasonal_NEP/write_spear_atmos.py
# 
# Usage: atmos2gaea.sh YR1 [YR2] 
# or sbatch atmos2gaea.sh YR1 [YR2]
set -u

if module list | grep "gcp"; then
  echo "gcp loaded"
else
  module load gcp/2.3
fi

export DATM=/home/Dmitry.Dukhovskoy/work1/NEP_input/fcst_forcing/atmos
export SRC=/home/Dmitry.Dukhovskoy/scripts/seasonal_fcst

MONTHS=(1 4 7 10) # initialization months
ENSMB=(1 2 3 4 5 6 7 8 9 10)   # ens runs
FS=6    # File system on Gaea
YR1=0
YR2=0
ensS=0
ensE=0

usage() {
  echo "Usage: $0 --ys 1994 --ye 1994 --ms 1 --ensS 3 --ensE 9 --fs 6"
  echo "  --ys          start with this init year to pprcs the f/cast <-- Required" 
  echo "  --ye          end with this f/cast init year, default=same as ys"
  echo "  --ms      month to start the f/cast, default: 1,4,7,10" 
  echo "  --ensS    1st ensemble # to run, default: all ensmbls: 1, ..., 10"
  echo "  --ensE    last ensemble number to run, f/cast will be run for ensS,...,ensE, default=ensS"
  echo "  --fs      File system on Gaea: 5 or 6, default=6"
  exit 1
}

# Pars flags for optional arguments:
while [[ $# -gt 0 ]]; do
  case $1 in
    --ys)
      YR1="$2"
      shift 2
      ;;
    --ye)
      YR2="$2"
      shift 2
      ;;
    --ms)
      MONTHS=("$2")
      shift 2
      ;;
    --ensS)
      ensS=$2
      shift 2
      ;;
    --ensE)
      ensE=$2
      shift 2
      ;;
    --fs)
      FS="$2"
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

if [[ ${YR1} -eq 0 ]]; then
  echo "ERR: Start year was not specified"
  usage
fi

if [[ ${YR2} -eq 0 ]]; then
  YR2="$YR1"
fi

if (( ensS > 0 && ensE == 0 )); then
  ensE=$ensS
fi

if (( ensS > 0 )); then
  ENSMB=()
  for (( ens=$ensS; ens<=$ensE; ens++ )); do
    ENSMB+=("$ens")
  done
fi

if (( FS != 5 && FS != 6 )); then
  echo "ERROR: FS=$FS should be 5 or 6"
  usage
fi

if [[ $FS -eq 5 ]]; then
  DGAEA=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/NEP_data/forecast_input_data/atmos
else
  DGAEA=/gpfs/f6/ira-cefi/scratch/Dmitry.Dukhovskoy/NEP_data/forecast_input_data/atmos
fi

cd $DATM || { echo "Error: Cannot cd to $DATM"; exit 1; }
pwd
#ls -l


for (( yr=$YR1; yr<=$YR2; yr+=1 )); do
  for mo in ${MONTHS[@]}; do
    mo0=$(printf "%02d" "$mo")
    for ens in ${ENSMB[@]}; do
      ens0=$(printf "%02d" "$ens")

      #ftar=spear_atmos_${yr}${mo0}.tar.gz   # 1 tar bundle zipped for all ensembles
      ftar=spear_atmos_${yr}${mo0}e${ens0}.tar

      chck_file=spear_atmos_${yr}${mo0}_sent    # old naming for all ensembles combined in 1 tar
      chck_new="spear_atmos_${yr}${mo0}e${ens0}_sent"
      if [ -s $chck_file ] || [ -s $chck_new ]; then
        echo "$ftar was already sent"
        continue
      fi


      if ! [ -s $ftar ]; then
        echo "${ftar} does not exist, checking if atmos fields exist for tarring"
        $SRC/atmos_tar.sh --ys "$yr" --ms "$mo" --ensS "$ens" --dgaea "$DGAEA"
        status=$?
        if [[ $status -ne 0 ]]; then
          echo "ERROR in SPEAR atmos tar/gzip step, exiting ..."
          exit 5
        fi
      fi
  
# Tar may still not exist, if not all ensembles were create, for instance:
      if ! [ -s $ftar ]; then
        echo "$ftar still not found, check tar/gzip step, not all ensembles ?? Skipping ..."
        continue
      fi
   
      echo "Sending $ftar to gaea:$DGAEA ..." 
      /bin/rm -f $chck_new
      gcp $ftar gaea:$DGAEA/
      status=$?
      if [[ $status == 0 ]]; then
        echo $ftar > $chck_new
        echo "removing $ftar"
        rm $ftar
      fi

    done
  done
done

exit 0 

