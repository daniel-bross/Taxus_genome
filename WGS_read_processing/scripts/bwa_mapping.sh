#!/bin/bash -eu
set -o pipefail

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: running ${0##*/}"

module purge
module load BWA/2.2.1_7aa5ff6
module load samtools/1.21

BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)
REF=$(grep '^REF=' config.cfg | cut -d= -f2)
METAFILE=$(grep '^METAFILE' config.cfg | cut -d= -f2)
INPUTDIR=${BASEDIR}results/02_trim/
OUTPUTDIR=${BASEDIR}results/04_mapping/

mkdir -p ${OUTPUTDIR}

NAME=$(basename ${REF} .fasta)
INDEX=${BASEDIR}data/bwa2_index/${NAME}
ID=$1

lscpu
printf "\n"

FILE=$(basename --suffix=.fastq.gz ${INPUTDIR}* | cut -d '_' -f1,2 | uniq | head -n $ID | tail -1)
THREADS=$2

RGID=$(awk 'NR!=1 {print $1}' ${METAFILE} |  head -n $ID | tail -1 )
RGBC=$(awk 'NR!=1 {print $2}' ${METAFILE} |  head -n $ID | tail -1 )
RGCN=$(awk 'NR!=1 {print $3}' ${METAFILE} |  head -n $ID | tail -1 )
RGDS=$(awk 'NR!=1 {print $4}' ${METAFILE} |  head -n $ID | tail -1 )
RGLB=$(awk 'NR!=1 {print $5}' ${METAFILE} |  head -n $ID | tail -1 )
RGPL=$(awk 'NR!=1 {print $6}' ${METAFILE} |  head -n $ID | tail -1 )
RGPM=$(awk 'NR!=1 {print $7}' ${METAFILE} |  head -n $ID | tail -1 )
RGPU=$(awk 'NR!=1 {print $8}' ${METAFILE} |  head -n $ID | tail -1 )
RGSM=$(awk 'NR!=1 {print $9}' ${METAFILE} |  head -n $ID | tail -1 )
TAG="@RG\\tID:${RGID}\\tBC:${RGBC}\\tCN:${RGCN}\\tDS:${RGDS}\\tLB:${RGLB}\\tPL:${RGPL}\\tPM:${RGPM}\\tPU:${RGPU}\\tSM:${RGSM}"

echo "Processing ${FILE}..."

bwa-mem2 mem -t ${THREADS} ${INDEX} ${INPUTDIR}${FILE}_R1.fastq.gz ${INPUTDIR}${FILE}_R2.fastq.gz -R ${TAG} | samtools fixmate -@ ${THREADS} -m - - | samtools sort -@ ${THREADS} -o ${OUTPUTDIR}${FILE}_sorted.bam -

# check if output mapping has the expected number of reads
COUNT_B=$(samtools view -@ $THREADS -c -F 0x900 ${OUTPUTDIR}${FILE}_sorted.bam)
COUNT_F=$(zcat ${INPUTDIR}${FILE}_R1.fastq.gz | echo $((`wc -l`/2)) ) # should be /4 and *2 later, this assuemes that both FASTQ PE files contain the same number of sequences, which they should!

if [[ $COUNT_B == $COUNT_F ]]; then
	printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: confirmed that the output .bam file containing the same number of sequences as the input fastq files"
elif [[ $COUNT_B != $COUNT_F ]]; then
	printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "WARNING: output .bam file does not contain the same number of sequences as the input fastq files "
fi

module purge

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: finished running ${0##*/}"

