#!/bin/bash -x

if [ $# -ne 2 ]; then
  echo USAGE: sh repeating_FRB.sh ObsID CHUNK
  exit
fi

echo "  - Processing of $1 starting, "; date

OBS=$1
CHUNK=$2
INDIR=/data1/Daniele/FRB121102/test/${OBS}
OUTDIR=/data1/Daniele/FRB121102/test/${OBS}

#Print to log files
exec 3>&1 4>&2
exec 1>${OUTDIR}/meta_data/${OBS}_${i}.log
exec 2>${OUTDIR}/meta_data/${OBS}_${i}.err

WORKDIR=`mktemp -d --tmpdir=/dev/shm`
cd ${WORKDIR}

FIL=${OBS}_p00${CHUNK}.fil  #_SAP000_B000_cDM051.00.fil
cp ${INDIR}/meta_data/${FIL} .

rfifind -o ${OBS}_${CHUNK} -filterbank -noweights -noscales -nooffsets -clip 6.0 -zerodm -time 1.0 -rfips ${FIL}


# Durations from 0.000652 to 0.0978 s (downfactor 4 to 4*150)
# prepsubband -o d1_${OBS} -noweights -noscales -nooffsets -clip 6.0 -zerodm -runavg -numout 1200000 -lodm 50.0 -dmstep 0.1 -numdms 20 -nsub 1600 -downsamp 4 -mask ${OBS}_rfifind.mask ${FIL}
prepsubband -o d1_${OBS} -noweights -noscales -nooffsets -clip 6.0 -zerodm -runavg -numout 6250000 -lodm 554.0 -dmstep 0.005 -numdms 2000 -nsub 3200 -downsamp 4 -mask ${OBS}_rfifind.mask ${FIL}
single_pulse_search.py -m 0.1 -p -t 8 -b *.dat

cat *.singlepulse | head -n 1 > ${OBS}_${CHUNK}.sp
tail --lines=+2 -q  *.singlepulse >> ${OBS}_${CHUNK}.sp
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
awk '$NF=$NF*128' sp.tmp >> ${OBS}_${CHUNK}.sp
rm sp.tmp

rm *.dat *.inf

mkdir output
mv *_rfifind.ps output
mv ${OBS}_${CHUNK}.sp output
cp output/* ${OUTDIR}/meta_data
  
cd ${OUTDIR}
rm -rf ${WORKDIR}

#Print back to console
exec 1>&3 2>&4
echo "  - Processing of $1 completed, "; date
