# Create TA/DIC fields for COBALT using ESPER matlab subroutines
# from NEP daily T/S OB fields for 4 OB segments
# the OB fields are derived from SPEAR f/casts (monthly)
# The OB daily fields should be on PPAN archive server
#
# ESPER OB fields prepared from 1 ens and init month = Jan
# For each year from YRS to YRE matlab will produce ESPER files 
# Each file will contain 2years of data (overlapping), e.g. 1993-1994, 1994-1995, ...
#  to allow 1-yr seas. f/casts initialized at different months during the 1st year
#
set -u

export DIRARCH=/archive/Dmitry.Dukhovskoy/NEP_input/spear_obc_daily
export DIRESPER=/archive/Dmitry.Dukhovskoy/NEP_input/BGC_esper_seasfcast
export DIRSCR=/home/Dmitry.Dukhovskoy/matlab/setup_BGCseasfcast

YRS=0
YRE=0
MM=1
ens=1
owrt=0

usage() {
  echo "Usage: $0 --ys 1994 [--ye 1995] [--mm 1] [--ens 1] "
  echo "  --ys     start with this year  <-- Required" 
  echo "  --ye     end with this year, default=same as ys"
  echo "  --mm     SPEAR init month to process, default 1 (Jan)"
  echo "  --ens    SPEAR ens. run to process, default ens=1"
  echo "  --owrt   1, overwrite existing files, default = 0"
  exit 1
}

# Parse the command-line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --ys)
      YRS=$2
      shift 2 # Move past the flag and its arg. to the next flag
      ;;
    --ye)
      YRE=$2
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
    --owrt)
      owrt=$2
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

if [[ $YRS -eq 0 ]]; then
  echo "ERR: YRS was not specified $YRS"
  usage
fi

if [[ $YRE -eq 0 ]]; then
  YRE=$YRS
fi

if [[ $YRS -lt 1900 ]] || [[ $YRE -lt 1900 ]]; then
  echo "ERROR: Check input years YRS=$YRS YRE=$YRE "
  usage
fi

ens0=$(printf "%02d" "${ens}")
MM0=$(printf "%02d" "${MM}")

# Check if any years have already been processed and OBC files exist:
#echo "YRS=$YRS"
yr_missed=9999
for (( YR1=$YRS; YR1<=$YRE; YR1+=1 )); do
  YR2=$(( YR1+1 ))

  # Current year:
  DRIN=${DIRARCH}/${YR1}_e${ens0}
  flobc="OBCs_spear_daily_init${YR1}${MM0}01_e${ens0}.nc"
  if [ ! -s ${DRIN}/${flobc} ]; then
    echo "Does not exist OBC file: ${DRIN}/${flobc}, quitting ..."
    exit 1
  fi
  # And next year:
  DRIN=${DIRARCH}/${YR2}_e${ens0}
  flobc="OBCs_spear_daily_init${YR2}${MM0}01_e${ens0}.nc"
  if [ ! -s ${DRIN}/${flobc} ]; then
    echo "Does not exist OBC file: ${DRIN}/${flobc}, quitting ..."
    exit 1
  fi


  flbgc="bgc_esper_SPEARmnth_${YR1}-${YR2}.nc"
  #echo $flbgc
  if [ -s ${DIRESPER}/${flbgc} ]; then
    if [[ ${owrt} -gt 0 ]]; then
      echo "Deleting existing NGC file: ${DIRESPER}/${flbgc}"
      rm -f ${DIRESPER}/${flbgc}  
    else
      echo "${YR1} Already created: ${DIRESPER}/${flbgc} "
      YRS=$YR2
      echo "Start year changed to ${YRS}"
    fi
  else
    echo "$YR1 has not been created yet"
    # not finished - need to account for a situation when 1 or more files are
    # missing and the rest already created during YRS-YRE
    # for now - run for 1 missing year
    yr_missed=$YR1
  fi
done


# All years already created:
if [[ $YRS -gt $YRE ]]; then
  echo "All years already created, nothing to process"
  exit 0
fi


# Process not-existing ESPER files:
HEXE=esper_cobalt_OBCdaily.m
echo "Starting esper calculation for $YRS - $YRE: $HEXE"
matlab241 -nodisplay -nosplash -r "YR1=${YRS}; YR2=${YRE}; run('${DIRSCR}/${HEXE}'); exit;"

#done

echo "All done"
date
   

