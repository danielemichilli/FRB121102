#!/bin/bash -x

#Print usage and exit
if [ $# -ne 1 ]; then
  echo "USAGE: sh launcher.sh ObsID"
  exit
fi

#Start the processing if filterbank file exists
OBS=$1
INDIR=`pwd`
FIL=${OBS}_SAP000_B000_cDM558.00.fil
if [ ! -e ${FIL} ]; then
  echo "Obervation to process must be present in this folder"
  exit
fi

echo "============================="
echo "Processing of OBS $1 starting"

mkdir meta_data
cd meta_data

#Print to log files
exec 3>&1 4>&2
exec 1>${OBS}.log
exec 2>${OBS}.err

#Split the filterbank file if it has not been done
if [ ! -e ${OBS}_p008.fil ]; then
  /data1/Daniele/FRB121102/software/splitfil -o ${OBS} ${FIL}
fi
  
#Submit the processing for each chunk
for i in `seq 0 3`; do
  sh /data1/Daniele/FRB121102/software/repeating_FRB.sh ${OBS} $i &
done
wait

for i in `seq 4 8`; do
  sh /data1/Daniele/FRB121102/software/repeating_FRB.sh ${OBS} $i &
done
wait

cd ${INDIR}
cat meta_data/*.sp | head -n 1 > ${OBS}.sp
tail --lines=+2 -q  meta_data/*.sp >> ${OBS}.sp

#python repeating_FRB_diagnostic.py ${WORKDIR} ${OBS}.sp ${FIL} ${WORKDIR}/output/diagnostic_plots

#Print back to console
exec 1>&3 2>&4
echo "Processing of OBS $1 completed"
echo "============================="
