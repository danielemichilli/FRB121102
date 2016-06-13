#!/bin/bash -x

if [ $# -ne 1 ]; then
  echo "USAGE: sh launcher.sh ObsID"
  exit
fi

OBS=$1
INDIR=`pwd`
FIL=${OBS}_SAP000_B000_cDM558.00.fil
if [ ! -e ${OBS} ]; do
  echo "Obervation to process must be present in this folder"
  exit
fi

echo "============================="
echo "  - Processing of $1 starting"

TMP_NAME=`date -I`
mkdir ${TMP_NAME}

/data1/Daniele/FRB121102/software/splitfil -o ${TMP_NAME}/${OBS} ${FIL}

for i in `seq 0 3`; do
  sh /data1/Daniele/FRB121102/software/repeating_FRB.sh ${OBS} $i > ${OBS}_${i}.log &
done
wait

for i in `seq 4 8`; do
  sh /data1/Daniele/FRB121102/software/repeating_FRB.sh ${OBS} $i > ${OBS}_${i}.log &
done
wait

python repeating_FRB_diagnostic.py ${WORKDIR} ${OBS}.sp ${FIL} ${WORKDIR}/output/diagnostic_plots

# rm -r TMP_NAME

echo "  - Processing of $1 finished"
echo "============================="
