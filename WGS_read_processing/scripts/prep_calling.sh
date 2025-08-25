#!/bin/bash -eu
set -o pipefail

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: running ${0##*/}"

module purge
module load samtools/1.21
module load pyfaidx/0.8.1.3

BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)
REFNAME=$(grep -i '^REFNAME=' config.cfg | cut -d= -f2)

lscpu
printf "\n"

samtools faidx ${BASEDIR}data/ref/${REFNAME}.fa &&\
faidx --transform bed ${BASEDIR}data/ref/${REFNAME}.fa | sed -e 's/\t/:/' | sed -e 's/\t/-/' | sed -e 's/:0-/:1-/g' > ${BASEDIR}data/ref/${REFNAME}.bed &&\

ls ${BASEDIR}results/07_mark_duplicates/*.bam > ${BASEDIR}data/bam_files.txt

module purge

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: finished running ${0##*/}"
