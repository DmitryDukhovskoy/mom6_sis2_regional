#!/bin/bash 
# 
# Use xml template to generate an XML for specific forecast
# usage: ./create_seasfcst_xml.sh YRSTART MOSTART
# Day start: assumed day = 1 of the month
set -u 

export DAWK=/home/Dmitry.Dukhovskoy/scripts/awk_utils
export DXML=/work/Dmitry.Dukhovskoy/NEP_xml
export DOUT=/work/Dmitry.Dukhovskoy/xml_tmp
export XMLTMP=NEPphys_seasfcst_template.xml

if [[ $# < 2 ]]; then
  echo "ERROR start year months not specified"
  echo "usage: ./create_seasfcst_xml.sh YRSTART MOSTART"
  exit 1
fi

ystart=$1
MOS=$2
mstart=$(echo $MOS | awk '{printf("%02d", $1)}')

echo "Creating XML for ${ystart}-${mstart}" 

# Determine time span, need last day of the last month in a 1 year fcst
/bin/cp $DAWK/dates.awk .

# Find year day to end the simulation, which is 365( or 366)-1 days forward in time
dnmb_now=$( echo "DATE2HYCOM" | awk -f dates.awk YR=$ystart MM=$mstart DD=1 )
dnmb_next=$( echo "DATE2HYCOM" | awk -f dates.awk YR=$(( ystart+1)) MM=$mstart DD=1 )
nadd=$(( dnmb_next-dnmb_now-1 ))
#echo "nadd=$nadd"

yrE=$( echo "ADD DAYS" | awk -f dates.awk yr1=$ystart mo1=$mstart d1=1 ndays=$nadd | \
       awk '{printf("%d",$1)}') 
moE=$( echo "ADD DAYS" | awk -f dates.awk yr1=$ystart mo1=$mstart d1=1 ndays=$nadd | \
       awk '{printf("%02d",$2)}')
dayE=$( echo "ADD DAYS" | awk -f dates.awk yr1=$ystart mo1=$mstart d1=1 ndays=$nadd | \
       awk '{printf("%02d",$3)}')


jdayS=$(echo "YRMO START DAY" | awk -f dates.awk y01=2004 MM=04 dd=1 | awk '{printf("%02d",$1)}')

atmosspan=${ystart}${mstart}01-${yrE}${moE}${dayE}

echo "atmosspan = ${atmosspan}"

cd $DOUT
pwd
/bin/rm $XMLTMP
/bin/cp $DXML/$XMLTMP .
ls -l

bnm=$( echo $XMLTMP | cut -d "_" -f-2 )
#echo $bnm
flout=${bnm}_${ystart}_${mstart}.xml

/bin/rm -f $flout
sed -e 's|<property name="ystart" value=.*|<property name="ystart" value="'"${ystart}"'"/>|'\
    -e 's|<property name="mstart" value=.*|<property name="mstart" value="'"${mstart}"'"/>|'\
    -e 's|<property name="atmosspan" value=.*|<property name="atmosspan" value="'"${atmosspan}"'"/>|' $XMLTMP > $flout

chmod 750 $flout

exit 0
