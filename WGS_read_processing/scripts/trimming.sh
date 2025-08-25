#!/bin/bash -eu
set -o pipefail

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: running ${0##*/}"

module purge
module load trimmomatic/0.39 #only makes sense with a shell script wrapper. Just loads java for now.

BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)
INPUTDIR=${BASEDIR}data/fastq/
OUTPUTDIR=${BASEDIR}results/02_trim/
THREADS=$2

ADAPTER_SEQ="${BASEDIR}data/seq/adapters.fa"

mkdir -p ${BASEDIR}results/02_trim/

FILE=$(basename --suffix=.fastq.gz ${INPUTDIR}* | cut -d '_' -f1,2 | uniq | head -$1 | tail -1)

lscpu
printf "\n"

echo "Processing ${FILE}..."

time java -jar /package/software/Bioinformatics/trimmomatic/0.39/bin/trimmomatic-0.39.jar PE \
	-threads ${THREADS} -phred33 \
	${INPUTDIR}${FILE}_R1.fastq.gz ${INPUTDIR}${FILE}_R2.fastq.gz \
	${OUTPUTDIR}${FILE}_R1.fastq.gz ${OUTPUTDIR}${FILE}_R1U.fastq.gz ${OUTPUTDIR}${FILE}_R2.fastq.gz ${OUTPUTDIR}${FILE}_R2U.fastq.gz \
	ILLUMINACLIP:${ADAPTER_SEQ}:2:30:10:1:true SLIDINGWINDOW:4:15 MINLEN:60

module purge

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: finished running ${0##*/}"
