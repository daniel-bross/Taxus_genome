#!/bin/bash -eu
set -o pipefail

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: running ${0##*/}"

module purge
module load FastQC/0.12.1
module load multiqc/1.27.1

BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)

if [ "$1" = "--init" ]; then
  INPUTDIR=${BASEDIR}data/fastq/
  OUTPUTDIR=${BASEDIR}results/01_initial_fastqc/
fi

if [ "$1" = "--trim" ]; then
  INPUTDIR=${BASEDIR}results/02_trim/
  OUTPUTDIR=${BASEDIR}results/03_trim_fastqc/
fi


mkdir -pv ${OUTPUTDIR}

lscpu
printf "\n"

FILE=$(ls ${INPUTDIR} | grep -e 'fastq.gz'  | head -$2 | tail -1)
THREADS=$3

echo "Processing ${FILE}..."
fastqc -t ${THREADS} -o ${OUTPUTDIR} ${INPUTDIR}${FILE}

module purge

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: finished running ${0##*/}"
