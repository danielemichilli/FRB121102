#!/bin/bash -x

if [ $# -ne 1 ]; then
  echo USAGE: sh repeating_FRB.sh ObsID
  exit
fi

echo Processing starting

WORKDIR=`mktemp -d --tmpdir=/dev/shm`
cd ${WORKDIR}

OBS=$1
INDIR=/path/${OBS}
OUTDIR=/path

mkdir ${OUTDIR}/${OBS}


#Parallelize!!!
for BEAM in `ls ${INDIR}`; do  #check that directory only contains beam folders, otherwise  #{0,1,2,3,4,5,6}
  mkdir ${BEAM}
  cd ${BEAM}
  FITS=file.fits
  NAME=${OBS}_${BEAM}
  mkdir ${NAME}
  
  cp ${INDIR}/${BEAM}/${FITS} .
  
  rfifind -o ${NAME} -noweights -noscales -nooffsets -clip -zerodm -rfips ${FITS}
  prepsubband -o ${NAME} -noweights -noscales -nooffsets -clip -zerodm -runavg -numout ?? -lodm ?? -dmstep ?? -numdms ?? -nsub ?? -mask ${NAME}_rfifind.mask ${FITS}
  prepsubband -o ${NAME} -noweights -noscales -nooffsets -clip -zerodm -runavg -numout ?? -lodm ?? -dmstep ?? -numdms ?? -nsub ?? -mask ${NAME}_rfifind.mask -downsamp 128 ${FITS}
  
  single_pulse_search.py -m 60 -p -t ?? *.dat
  
  rm *.dat *.inf
  
  cat *.singlepulse | head -n 1 > ${NAME}.sp
  tail --lines=+2 -q  *.txt >> ${NAME}.sp
  
  rm *.singlepulse
  
  mkdir output
  
  python repeating_FRB_diagnostic.py ${WORKDIR} ${NAME}.sp ${FITS} output
  
  cp output ${OUTDIR}/${OBS}/${NAME}
  
done




#Parallel
for BEAM in `ls ${INDIR}`; do
  mkdir ${BEAM}
  NAME=${OBS}_${BEAM}
done

for BEAM in `ls ${INDIR}`; do
  FITS=file.fits
  cp ${INDIR}/${BEAM}/${FITS} ${BEAM} &
done
wait

for BEAM in `ls ${INDIR}`; do
  FITS=${BEAM}/file.fits
  NAME=${BEAM}/${OBS}_${BEAM}
  rfifind -o ${NAME} -noweights -noscales -nooffsets -clip -zerodm -rfips ${FITS} &
done
wait

for BEAM in `ls ${INDIR}`; do
  FITS=${BEAM}/file.fits
  NAME=${BEAM}/${OBS}_${BEAM}
  prepsubband -o ${NAME} -noweights -noscales -nooffsets -clip -zerodm -runavg -numout ?? -lodm ?? -dmstep ?? -numdms ?? -nsub ?? -mask ${NAME}_rfifind.mask ${FITS} &
  prepsubband -o ${NAME}_d128 -noweights -noscales -nooffsets -clip -zerodm -runavg -numout ?? -lodm ?? -dmstep ?? -numdms ?? -nsub ?? -mask ${NAME}_rfifind.mask -downsamp 128 ${FITS} &
done
wait
  
for BEAM in `ls ${INDIR}`; do
  single_pulse_search.py -m 60 -p -t ?? ${BEAM}/*.dat &
done
wait

for BEAM in `ls ${INDIR}`; do
  rm *.dat *.inf
  cat *.singlepulse | head -n 1 > ${NAME}.sp
  tail --lines=+2 -q  *.txt >> ${NAME}.sp
  rm *.singlepulse
  mkdir output
done

  
  rm *.dat *.inf
  
  cat *.singlepulse | head -n 1 > ${NAME}.sp
  tail --lines=+2 -q  *.txt >> ${NAME}.sp
  
  rm *.singlepulse
  
  mkdir output
  
  python repeating_FRB_diagnostic.py ${WORKDIR} ${NAME}.sp ${FITS} output
  
  cp output ${OUTDIR}/${OBS}/${NAME}
  
done
