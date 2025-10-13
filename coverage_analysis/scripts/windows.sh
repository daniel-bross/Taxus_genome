#!/bin/bash -eu
set -o pipefail

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: running ${0##*/}"

# set directories, e.g. BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)
BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)
BED=$(grep '^BED=' config.cfg | cut -d= -f2)
WIN_SIZE=$(grep '^WIN_SIZE=' config.cfg | cut -d= -f2)
STEP=$(grep '^STEP=' config.cfg | cut -d= -f2)

OUTDIR=$BASEDIR/results/01_winbed/

mkdir -p $OUTDIR

# load modules
module load bedtools

# script
bedtools makewindows -b ${BASEDIR}${BED} -w $WIN_SIZE -s $STEP | split -a 3 --additional-suffix=.bed -d -l 500000 - ${OUTDIR}winpart


module purge
printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: finished running ${0##*/}"
