#! /bin/bash 
#
# Fetch GFS GDAS atmoshperic fields for specified dates
#
set -u 

module load wgrib2/3.1.3_ncep

usage() {
  echo "Usage: $0 --sdate YYYYMMDD [--edate YYYYMMDD]"
  echo "  --sdate    start date HR=0"
  echo "  --edate    end date, defualt = sdate HR=last available on this date"
  exit 1
}

sdate=""
edate=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --sdate)
      sdate=$2
      shift 2
      ;;
    --edate)
      edate=$2
      shift 2
      ;;
    --help)
      usage
      ;;
    *)
    echo "ERR: Unrecognized option $1"
    usage
    ;;
  esac
done

if [[ $sdate -eq 0 ]]; then
  echo "ERR: missing sdate"
  usage
fi

[[ $edate -eq 0 ]] && edate=$sdate

if [[ -z "$sdate" ]]; then
  echo "ERR: missing --sdate"
  usage
fi

[[ -z "$edate" ]] && edate="$sdate"

echo "sdate: $sdate"
echo "edate: $edate"

# Check date formats:  
if [[ ! "$sdate" =~ ^[0-9]{8}$ ]]; then
  echo "ERR: sdate must be in format YYYYMMDD, input: $sdate"
  usage
fi

if [[ ! "$edate" =~ ^[0-9]{8}$ ]]; then
  echo "ERR: sdate must be in format YYYYMMDD, input: $edate"
  usage
fi

rdir=/NCEPPROD/hpssprod/runhistory   # HPSS dir
odir=/scratch4/NCEPDEV/stmp/${USER}/datm_forcing/DATM/Reanal
wdir=/scratch4/NCEPDEV/stmp/${USER}/datm_forcing/DATM/Tmp_get

mkdir -pv $odir
mkdir -pv $wdir

cd $wdir || { echo "Couldnot cd to $wdir"; exit 1; }

#-- PRATE,UFLX,VFLX are from the f006 fcst of the run before 6 hour. 
hprep=f006

date0=$sdate
while [[ $date0 -le $edate ]]; do
  yy=${date0:0:4}
  ym=${date0:0:6}
  mm=${date0:4:2} 
  dd=${date0:6:2}  
  
  for (( hr=0; hr<=18; hr+=6 )); do
    hh=$(printf "%02d" $hr )
    echo "Processing ${date0}:${hh} ..." 

    dathb=$(date -d "$date0 $hh 6 hour ago" +%Y%m%d%H)
    yyb=${dathb:0:4}
    ymb=${dathb:0:6}
    ddb=${dathb:6:2}
    hhb=${dathb:8:2}
    datb=${ymb}${ddb}

    flux_tar="${rdir}/rh${yy}/${ym}/${date0}/com_gfs_v16.3_gdas.${date0}_${hh}.gdas_flux.tar"
    nc_tar="${rdir}/rh${yy}/${ym}/${date0}/com_gfs_v16.3_gdas.${date0}_${hh}.gdas_nc.tar"
    flux_tar_b="${rdir}/rh${yyb}/${ymb}/${datb}/com_gfs_v16.3_gdas.${datb}_${hhb}.gdas_flux.tar"

    htar -xvf "$flux_tar" ./gdas.${date0}/${hh}/atmos/gdas.t${hh}z.sfluxgrbf000.grib2
    htar -xvf "$flux_tar_b" ./gdas.${datb}/${hhb}/atmos/gdas.t${hhb}z.sfluxgrb${hprep}.grib2
    htar -xvf "$nc_tar" ./gdas.${date0}/${hh}/atmos/gdas.t${hh}z.atmf000.nc

    if [[ -f ./gdas.${date0}/${hh}/atmos/gdas.t${hh}z.sfluxgrbf000.grib2 ]]; then
      echo "Files found OK, extracting and processing..."
      wgrib2 ./gdas.${datb}/${hhb}/atmos/gdas.t${hhb}z.sfluxgrb${hprep}.grib2 -s \
        | egrep ':PRATE:|:UFLX:|:VFLX:|:NBDSF:|:NDDSF:|:VBDSF:|:VDDSF:' \
        | wgrib2 -i -grib sfluxgrb${hprep}.puvflx.grib2 ./gdas.${datb}/${hhb}/atmos/gdas.t${hhb}z.sfluxgrb${hprep}.grib2

      mv ./gdas.${date0}/${hh}/atmos/gdas.t${hh}z.sfluxgrbf000.grib2 ${odir}/gfs.${date0}.t${hh}z.sfcanl.grib2
      mv sfluxgrb${hprep}.puvflx.grib2 ${odir}/gfs.${date0}.t${hh}z.puvflx.grib2
      ncks -h -M -m -O -C -d pfull,126 -v delz ./gdas.${date0}/${hh}/atmos/gdas.t${hh}z.atmf000.nc gdas.t${hh}z.atmf000.delz1.nc
      mv gdas.t${hh}z.atmf000.delz1.nc ${odir}/gfs.${date0}.t${hh}z.atmf000.delz1.nc
    else
      echo "Primary file not found. Trying gdas extraction..."
      flux_gdas0=${rdir}/rh${yy}/${ym}/${date0}/com.gdas_v16.3_gdas.${date0}_${hh}.gdas_flux.tar
      flux_gdasb=${rdir}/rh${yyb}/${ymb}/${datb}/com.gdas_v16.3_gdas.${datb}_${hhb}.gdas_flux.tar
      flux_gdasnc=${rdir}/rh${yy}/${ym}/${date0}/com.gdas_v16.3_gdas.${date0}_${hh}.gdas_nc.tar

      htar -xvf ${flux_gdas0} ./gdas.${date0}/${hh}/gdas.t${hh}z.sfluxgrbf000.grib2
      htar -xvf ${flux_gdasb} ./gdas.${datb}/${hhb}/gdas.t${hhb}z.sfluxgrb${hprep}.grib2
      htar -xvf ${flux_gdasnc} ./gdas.${date0}/${hh}/gdas.t${hh}z.atmf000.nc
      echo "./gdas.${date0}/${hh}/gdas.t${hh}z.sfluxgrbf000.grib2"
      echo " ./gdas.${datb}/${hhb}/gdas.t${hhb}z.sfluxgrb${hprep}.grib2"
      wgrib2 ./gdas.${datb}/${hhb}/gdas.t${hhb}z.sfluxgrb${hprep}.grib2 -s \
         | egrep ':PRATE:|:UFLX:|:VFLX:|:NBDSF:|:NDDSF:|:VBDSF:|:VDDSF:' \
         | wgrib2 -i ./gdas.${datb}/${hhb}/gdas.t${hhb}z.sfluxgrb${hprep}.grib2 -grib sfluxgrb${hprep}.puvflx.grib2

      mv ./gdas.${date0}/${hh}/gdas.t${hh}z.sfluxgrbf000.grib2 ${odir}/gfs.${date0}.t${hh}z.sfcanl.grib2
      mv sfluxgrb${hprep}.puvflx.grib2 ${odir}/gfs.${date0}.t${hh}z.puvflx.grib2
      ncks -h -M -m -O -C -d pfull,126 -v delz ./gdas.${date0}/${hh}/gdas.t${hh}z.atmf000.nc gfs.t${hh}z.atmf000.delz1.nc
      mv gdas.t${hh}z.atmf000.delz1.nc ${odir}/gfs.${date0}.t${hh}z.atmf000.delz1.nc
    fi

    if [[ ! -f ${odir}/gfs.${date0}.t${hh}z.sfcanl.grib2 ]]; then
      echo "ERROR: Missing output file: gfs.${date0}.t${hh}z.sfcanl.grib2"
      exit 1
    fi

    if [ ! -f ${odir}/gfs.${date0}.t${hh}z.sfcanl.grib2 ]; then
      echo "Cannot find : gfs.${date0}.t${hh}z.sfcanl.grib2"
      exit 1
    fi
  done

  # Advance to next day
  date0=$(date -d "${date0} +1 day" +%Y%m%d)
done

echo "All Done"
exit 0


