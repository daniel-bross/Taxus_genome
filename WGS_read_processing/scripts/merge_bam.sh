#!/bin/bash -eu
set -o pipefail

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: running ${0##*/}"

module purge
module load samtools/1.21

BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)
INPUTDIR=${BASEDIR}results/04_mapping/
OUTPUTDIR=${BASEDIR}results/06_merge_bam/
METAFILE=${BASEDIR}data/metadata/ReSeq_Meta_for_RG.txt
ID=$1

FILE=$(awk 'NR>1{print $1}' $METAFILE | cut -d '_' -f1 | uniq | head -n $ID | tail -1)

mkdir -p ${OUTPUTDIR}

lscpu
printf "\n"

echo "Processing libraries ${FILE}..."

LIBS=$(ls ${INPUTDIR}${FILE}*)
samtools merge -f -r -t SQ -o ${OUTPUTDIR}${FILE}_merged.bam ${LIBS}

a=$(parallel 'samtools view -c -F 0x900 {}' ::: $(ls ${INPUTDIR}${FILE}*) | awk '{sum += $1}END{print sum}')
b=$(samtools view -c -F 0x900 ${OUTPUTDIR}${FILE}* )

echo $a
echo $b

if [[ $a == $b && -n $a ]]; then
	printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: confirmed output read count matches input. Deleting raw mappings"
	rm $LIBS
else
	printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "WARNING: reads in output .bam does not match input files"
fi


module purge

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: finished running ${0##*/}"
