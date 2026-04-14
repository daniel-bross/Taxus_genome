#!/bin/bash

module purge
module load bcftools/1.21

BASEDIR=$(grep 'BASEDIR=' config.cfg | cut -d= -f2)
OUTPUTDIR=${BASEDIR}results/12_filtersets/
THREADS=$2

# Set filter name
SET="100s"
INPUT=$1
OUTPUT=${OUTPUTDIR}$(basename -s .vcf.gz $INPUT )_${SET}.vcf.gz

date
printf "\n"

mkdir -p ${OUTPUTDIR}

bcftools view --samples-file ${BASEDIR}scripts/vcf_filters/100_samples.txt -e 'COUNT(GT="RR") + COUNT(GT="mis") = N_SAMPLES' --threads ${THREADS} -o ${OUTPUT} -Oz --write-index ${INPUT}

module purge

printf "\n"
date

