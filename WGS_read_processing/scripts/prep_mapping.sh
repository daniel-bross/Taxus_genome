#!/bin/bash -eu
set -o pipefail

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: running ${0##*/}"

module purge
module load BWA/2.2.1

BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)
REF=${BASEDIR}$(grep '^REF=' config.cfg | cut -d= -f2)

lscpu
printf "\n"

mkdir -p ${BASEDIR}data/bwa2_index/

NAME=$(basename ${REF} .fasta)
bwa-mem2 index -p ${BASEDIR}data/bwa2_index/${NAME} $REF

module purge

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: finished running ${0##*/}"
