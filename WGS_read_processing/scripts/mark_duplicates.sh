#!/bin/bash -eu
set -o pipefail

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: running ${0##*/}"

module purge
module load picard/3.3.0
module load samtools/1.21

BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)
METAFILE=$(grep '^METAFILE=' config.cfg | cut -d= -f2)
INPUTDIR=${BASEDIR}results/06_merge_bam/
OUTPUTDIR=${BASEDIR}results/07_mark_duplicates/
TMP=${BASEDIR}results/tmp/
ID=$1

FILE=$(awk 'NR>1{print $1}' $METAFILE | cut -d '_' -f1 | uniq | head -n $ID | tail -1)

mkdir -p ${OUTPUTDIR}

lscpu
printf "\n"

echo "Processing ${FILE}..."

# --OPTICAL_DUPLICATE_PIXEL_DISTANCE 2500 corresponds to flow cell type. Defualt (100) is for unpatterned flow cells, 2500 is recommended for patterned cells like the NovaSeq S4
picard MarkDuplicates -I ${INPUTDIR}${FILE}_merged.bam -O ${OUTPUTDIR}${FILE}_MKDUP.bam -M ${OUTPUTDIR}${FILE}_dup_metrics.txt -TMP_DIR ${TMP}${FILE}/ --OPTICAL_DUPLICATE_PIXEL_DISTANCE 2500
samtools index -c ${OUTPUTDIR}${FILE}_MKDUP.bam

a=$(samtools view -c -F 0x900 ${INPUTDIR}${FILE}* )
b=$(samtools view -c -F 0x900 ${OUTPUTDIR}${FILE}_MKDUP.bam )

echo $a
echo $b

# delete input files if output contains the expected number of reads
if [[ $a == $b && -n $a ]]; then
        printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: confirmed output read count matches input. Deleting merged mappings"
        rm ${INPUTDIR}${FILE}_merged.bam
else
        printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "WARNING: reads in output .bam does not match input files"
fi

rm -r ${TMP}${FILE}

module purge

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: finished running ${0##*/}"
