#!/bin/bash -eu
set -o pipefail

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: running ${0##*/}"

# set directories, e.g. BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)
BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)

# script

A=${BASEDIR}results/braker-sr/braker.gtf
B=${BASEDIR}results/braker-lr/braker.gtf

bedtools intersect -u -sorted \
	-a  <(awk '/^[^#]/ {if ($3 == "gene") printf("%s\t%d\t%s\t%s\n",$1,int($4)-1,$5,$0);}' $A  | sort -t $'\t' -k1,1 -k2,2n ) \
	-b  <(awk '/^[^#]/ {if ($3 == "gene") printf("%s\t%d\t%s\t%s\n",$1,int($4)-1,$5,$0);}' $B  | sort -t $'\t' -k1,1 -k2,2n ) > ${BASEDIR}results/gtf_intersect_braker_genes_sr_lr.gtf

#module purge
printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: finished running ${0##*/}"
