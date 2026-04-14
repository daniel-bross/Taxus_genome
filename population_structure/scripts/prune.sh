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

printf "Config:\nbasedir: %s\nphenotype file: %s\nfilter: %s\n" $BASEDIR $PHENO $FILTER

INPUTFILE=${BASEDIR}results/${FILTER}/${FILTER}_filtered
plink --bfile ${INPUTFILE} --indep-pairwise 100 20 0.2 --memory ${MEMO} --pheno $PHENO --mpheno 2 --keep $PHENO --allow-extra-chr --out ${INPUTFILE}_pr && \
plink --bfile ${INPUTFILE} --extract ${INPUTFILE}_pr.prune.in --memory ${MEMO} --pheno $PHENO --mpheno 2 --keep $PHENO --allow-extra-chr --make-bed --out ${INPUTFILE}_pruned

module purge
printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: finished running ${0##*/}"
