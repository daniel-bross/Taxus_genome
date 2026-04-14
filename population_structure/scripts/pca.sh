#!/bin/bash -eu
set -o pipefail

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: running ${0##*/}"

# set directories, e.g. BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)
BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)
PHENO=$(grep '^PHENO=' config.cfg | cut -d= -f2)
FILTER=$(grep '^FILTER=' config.cfg | cut -d= -f2)

THREADS=$1
MEMO=$2
# input: relative path to bfile (not extensions)
INPUT=$3

# load modules
module load plink/1.90b7


mkdir -p ${BASEDIR}results/${FILTER}/

printf "Config:\nbasedir: %s\nphenotype file: %s\nfilter: %s\n" $BASEDIR $PHENO $FILTER

plink --bfile $INPUT --pca 999 --threads $THREADS --memory ${MEMO} --allow-extra-chr --out ${INPUT}_pca && Rscript scripts/pca_viz.R ${INPUT}_pca ${MEMO}

module purge
printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: finished running ${0##*/}"
