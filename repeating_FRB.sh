#!/bin/bash -x

if [ $# -ne 2 ]; then
  echo USAGE: sh repeating_FRB.sh ObsID CHUNK
  exit
fi

echo "  - Processing of $1 starting"

WORKDIR=`mktemp -d --tmpdir=/dev/shm`
cd ${WORKDIR}

OBS=$1
CHUNK=$2
INDIR=/data1/Daniele/FRB121102/test
OUTDIR=/data1/Daniele/FRB121102/test

mkdir ${OUTDIR}/${OBS}


FIL=${OBS}_p00${CHUNK}.fil  #_SAP000_B000_cDM051.00.fil
cp ${INDIR}/${FIL} .

rfifind -o ${OBS} -filterbank -noweights -noscales -nooffsets -clip 6.0 -zerodm -time 1.0 -rfips ${FIL}


# Durations from 0.000652 to 0.0978 s (downfactor 4 to 4*150)
# prepsubband -o d1_${OBS} -noweights -noscales -nooffsets -clip 6.0 -zerodm -runavg -numout 1200000 -lodm 50.0 -dmstep 0.1 -numdms 20 -nsub 1600 -downsamp 4 -mask ${OBS}_rfifind.mask ${FIL}
prepsubband -o d1_${OBS} -noweights -noscales -nooffsets -clip 6.0 -zerodm -runavg -numout 6250000 -lodm 554.0 -dmstep 0.005 -numdms 2000 -nsub 3200 -downsamp 4 -mask ${OBS}_rfifind.mask ${FIL}
single_pulse_search.py -m 0.1 -p -t 8 -b *.dat

cat *.singlepulse | head -n 1 > ${OBS}.sp
tail --lines=+2 -q  *.singlepulse >> ${OBS}.sp
rm *.singlepulse

# Durations from 0.083456 to 12.5184 s (downfactor 4*128 to 4*128*150)
for i in `ls d1_*.dat`; do 
  base_name=`basename ${i} .dat`
  file_name=${base_name##d1_}
  prepdata -o d2_${file_name} -downsamp 128 $i
  rm $i
  rm ${base_name}.inf
done
single_pulse_search.py -m 13.0 -p -t 8 -b *.dat

tail --lines=+2 -q  *.singlepulse > sp.tmp
rm *.singlepulse
awk '$NF=$NF*128' sp.tmp >> rm *.singlepulse
rm sp.tmp

rm *.dat *.inf

mkdir output
mv *_rfifind.ps output
mv ${OBS}.sp output
mkdir ${OUTDIR}/${OBS}/${CHUNK}
cp output/* ${OUTDIR}/${OBS}/${CHUNK}
  
cd ${OUTDIR}
rm -rf ${WORKDIR}

