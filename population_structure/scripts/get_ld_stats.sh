#!/bin/bash -eu
set -o pipefail

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: running ${0##*/}"

# set directories, e.g. BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)
BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)
PHENO=$(grep '^PHENO=' config.cfg | cut -d= -f2)
FILTER=$(grep '^FILTER=' config.cfg | cut -d= -f2)

THREADS=$1
MEMO=$2

# load modules
module load plink/1.90b7
module load R

printf "Config:\nbasedir: %s\nphenotype file: %s\nfilter: %s\n" $BASEDIR $PHENO $FILTER

INPUTFILE=${BASEDIR}results/${FILTER}/${FILTER}_filtered
plink --bfile ${INPUTFILE} --r2 --ld-window-r2 0.01 --ld-window 20 --ld-window-kb 5000 --memory ${MEMO} --pheno $PHENO --mpheno 2 --keep $PHENO --allow-extra-chr --out ${INPUTFILE}_r2 && Rscript scripts/r2_viz.R $FILTER

module purge
printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: finished running ${0##*/}"
