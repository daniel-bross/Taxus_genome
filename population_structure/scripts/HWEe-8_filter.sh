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
module load R/4.5.0

printf "Config:\nbasedir: %s\nphenotype file: %s\nfilter: %s\n" $BASEDIR $PHENO $FILTER

INPUTFILE=${BASEDIR}results/${FILTER}/$FILTER
plink --bfile ${INPUTFILE} --hwe 0.00000001 --make-bed --memory ${MEMO} --pheno $PHENO --mpheno 2 --keep $PHENO --allow-extra-chr --out ${BASEDIR}results/${FILTER}/${FILTER}_filtered

# create missing statstics as a final check
plink --bfile ${BASEDIR}results/${FILTER}/${FILTER}_filtered --missing --memory ${MEMO} --pheno $PHENO --mpheno 2 --keep $PHENO --allow-extra-chr --out ${BASEDIR}results/${FILTER}/${FILTER}_filtered_missing
plink --bfile ${BASEDIR}results/${FILTER}/${FILTER}_filtered --het --memory ${MEMO} --pheno $PHENO --mpheno 2 --keep $PHENO --allow-extra-chr --out ${BASEDIR}results/${FILTER}/${FILTER}_filtered_het
Rscript scripts/qcplot.R $FILTER

module purge
printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: finished running ${0##*/}"
