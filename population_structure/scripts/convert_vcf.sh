#!/bin/bash -eu
set -o pipefail

# set directories, e.g. BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)
BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)
PHENO=$(grep '^PHENO=' config.cfg | cut -d= -f2)
FILTER=$(grep '^FILTER=' config.cfg | cut -d= -f2)

THREADS=$1
MEMO=$2

# load modules
module load plink/1.90b7

# check config file
if [[ -z $BASEDIR || -z $PHENO || -z $FILTER ]]; then
	echo config file invalid
	exit
fi

mkdir -p ${BASEDIR}results/${FILTER}/

printf "Config:\nbasedir: %s\nphenotype file: %s\nfilter: %s\n" $BASEDIR $PHENO $FILTER

INPUT=${BASEDIR}data/${FILTER}/*.vcf.gz
plink --vcf ${INPUT} --threads $THREADS --memory $MEMO --allow-no-sex --double-id --allow-extra-chr --out ${BASEDIR}results/${FILTER}/${FILTER}_pre && \
plink --bfile ${BASEDIR}results/${FILTER}/${FILTER}_pre --threads $THREADS --memory $MEMO --allow-no-sex --pheno $PHENO --mpheno 2 --keep $PHENO --allow-extra-chr --make-bed --out ${BASEDIR}results/${FILTER}/${FILTER} && \
awk 'NR==FNR{a[$1]=$3;next} {print $1, $2, $3, $4, a[$1], $6}' $PHENO ${BASEDIR}results/${FILTER}/${FILTER}.fam > ${BASEDIR}results/${FILTER}/famfile  && \
mv ${BASEDIR}results/${FILTER}/famfile ${BASEDIR}results/${FILTER}/${FILTER}.fam && \
rm ${BASEDIR}results/${FILTER}/${FILTER}_pre*

module purge
