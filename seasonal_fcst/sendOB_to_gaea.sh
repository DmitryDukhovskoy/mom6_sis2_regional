#!/bin/bash
#SBATCH --output=logs/sendOB%j.out
# 
# no gzip, send OB files to gaea
#
set -u

if module list | grep "gcp"; then
  echo "gcp loaded"
else
  module load gcp/2.3
fi

export obc_dir=/work/Dmitry.Dukhovskoy/NEP_input/spear_obc_daily


YR1=0
YR2=0
MONTHS=(1 4 7 10)
ENSMB=(1 2 3 4 5 6 7 8 9 10)
FS=6

usage() {
  echo "Usage: $0 --ys 1994 [--ye 1995] [--mm 4] --ens 1,...,10 "
  echo "  --ys     start with this year  <-- Required" 
  echo "  --ye     end with this year, default=same as ys"
  echo "  --mm     month to process, default (1,4,7,10)"
  echo "  --ens    SPEAR ens. run to process, default (1,...,10)"
  echo "  --fs     file system on Gaea: 5 or 6, default=6"
  exit 1
}

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
    --mm)
      MONTHS=($2)
      shift 2
      ;;
    --ens)
      ENSMB=($2)
      shift 2
      ;;
    --fs)
      FS=$2
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

if [[ $YR1 -eq 0 ]]; then
  echo "ERR: YR1 was not specified $YR1"
  usage
fi
if [[ $YR2 -eq 0 ]]; then
  YR2=$YR1
fi

#ens=$( echo $3 | awk '{printf("%02d",$1)}' )
if [[ ${FS} -eq 5 ]]; then
  export gaea_dir=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/NEP_data/forecast_input_data/obcs_spear_daily
elif [[ ${FS} -eq 6 ]]; then
  export gaea_dir=/gpfs/f6/ira-cefi/scratch/Dmitry.Dukhovskoy/NEP_data/forecast_input_data/obcs_spear_daily
else
  echo "Unrecognized file system ${FS}"
  usage
fi


mkdir -pv $obc_dir/sent_OBCs

prfx=OBCs_spear_daily_init
for (( ystart=$YR1; ystart<=$YR2; ystart+=1 )); do
  for MM in ${MONTHS[@]}; do
    MM0=$( echo $MM | awk '{printf("%02d", $1)}' )      
    for ens_run in ${ENSMB[@]}; do
      ens=$( echo ${ens_run} | awk '{printf("%02d",$1)}' )
      cd $obc_dir
      flnm=${prfx}${ystart}${MM0}

      if [[ $ens -ne 0 ]]; then
        flnm=${prfx}${ystart}${MM0}01_e${ens}
      fi
  
      /bin/ls -l $flnm*

      # send files that have not been sent yet
      nfnc=$( ls -1 $flnm*nc 2>/dev/null | wc -l )
      if [[ $nfnc -gt 0 ]]; then
        for flnc in $( ls $flnm*nc ); do
          icc=0
          for dflncsent in $( ls sent_OBCs/*${ystart}*-sent ); do
            flncsent=$( echo $dflncsent | cut -d"/" -f2 )
            if [[ ${flnc}-sent == ${flncsent} ]]; then
              echo "${flnc} already sent, no action ..."
              icc=$(( icc+=1 ))
            fi
          done              

          if [[ $icc -eq 0 ]]; then
            yrens=${ystart}_e${ens}
            echo "sending ${flnc} to gaea: ${gaea_dir}/${yrens} ..."

            gcp -cd ${flnc} gaea:${gaea_dir}/${yrens}/
            status=$?
            if [[ $status == 0 ]]; then
              echo "${flnc} sent to gaea "
              touch sent_OBCs/${flnc}-sent
            fi
              
          fi
        done
      fi
    done
  done
done

echo "sendOB_to_gaea.sh: All done "

exit 0  


