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
echo "  - Processing of $1 starting"

#Split the filterbank file if it has not been done
if [ ! -e ${OBS}_p006.fil ]; then
  /data1/Daniele/FRB121102/software/splitfil -o ${OBS} ${FIL}
fi
  
#Submit the processing for each chunk
for i in `seq 0 3`; do
  sh /data1/Daniele/FRB121102/software/repeating_FRB.sh ${OBS} $i > ${OBS}_${i}.log ${OBS}_${i}.err &
done
wait

for i in `seq 4 8`; do
  sh /data1/Daniele/FRB121102/software/repeating_FRB.sh ${OBS} $i > ${OBS}_${i}.log ${OBS}_${i}.err &
done
wait

#python repeating_FRB_diagnostic.py ${WORKDIR} ${OBS}.sp ${FIL} ${WORKDIR}/output/diagnostic_plots

echo "  - Processing of $1 finished"
echo "============================="
