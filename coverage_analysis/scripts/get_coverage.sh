#!/bin/bash
set -o pipefail

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: running ${0##*/}"

module load samtools/1.21

# Declare mapping file paths in files
BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)
INPUTDIR=${BASEDIR}results/01_winbed/
OUTPUTDIR=${BASEDIR}results/02_coverages/
FMAPS=${BASEDIR}data/female_mappings.txt
MMAPS=${BASEDIR}data/male_mappings.txt
ID=$1
DB=${OUTPUTDIR}coverages.db
BEDFILE=$(ls ${INPUTDIR} | head -n ${ID} | tail -n 1 )

mkdir -p ${OUTPUTDIR}

samtools bedcov -Q 20 ${INPUTDIR}${BEDFILE} $(cat ${FMAPS} ${MMAPS}) > ${OUTPUTDIR}tmp_$$.txt


printf "\n"
date

module purge
