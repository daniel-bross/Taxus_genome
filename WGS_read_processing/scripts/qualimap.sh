#!/bin/bash -eu
set -o pipefail

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: running ${0##*/}"

module purge
module load qualimap/2.3

BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)
INPUTDIR=${BASEDIR}results/04_mapping/
OUTPUTDIR=${BASEDIR}results/05_qualimap/
ID=$1
THREADS=$2
MEM=$3

FILE=$(basename --suffix=_sorted.bam ${INPUTDIR}* | cut -d '_' -f1,2 | uniq | head -n $ID | tail -1)

mkdir -p ${OUTPUTDIR}${FILE}

unset DISPLAY

lscpu
printf "\n"

echo "Processing ${FILE}..."

qualimap bamqc -bam ${INPUTDIR}${FILE}_sorted.bam -outformat PDF:HTML -outdir ${OUTPUTDIR}${FILE} -outfile ${FILE} -nw 400 -hm 3 -ip -nt ${THREADS} --java-mem-size=${MEM}M

module purge

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: finished running ${0##*/}"
