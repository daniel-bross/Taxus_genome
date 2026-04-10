#!/bin/bash -eu
set -o pipefail


# set directories, e.g. BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)
BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)
THREADS=$(grep '^THREADS=' config.cfg | cut -d= -f2)
NAME=$(grep '^NAME=' config.cfg | cut -d= -f2)
C_TETOOLS=$(grep '^C_TETOOLS=' config.cfg | cut -d= -f2)

e_val=1e-30

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: running ${0##*/}"

# script

mkdir -p ${BASEDIR}results/prot_all_vs_all/blastdb

for i in braker-sr braker-lr; do
	singularity exec --bind ${BASEDIR}:${BASEDIR} $C_TETOOLS makeblastdb -in ${BASEDIR}results/${i}/braker.aa -title $i -dbtype prot -out ${BASEDIR}results/prot_all_vs_all/blastdb/${i}/$i
	singularity exec --bind ${BASEDIR}:${BASEDIR} $C_TETOOLS blastp -query ${BASEDIR}results/${i}/braker.aa -db ${BASEDIR}results/prot_all_vs_all/blastdb/${i}/$i -out ${BASEDIR}results/prot_all_vs_all/${i}_blastp_$e_val.bla -evalue $e_val -outfmt "6 qseqid sseqid qlen slen length pident qstart qend sstart send evalue bitscore"
	# filter out hits against the same gene
	awk '{split($1, a, "."); g1 = a[1]; split($2, b, "."); g2 = b[1]; if (g1 != g2) print $0}' ${BASEDIR}results/prot_all_vs_all/${i}_blastp_$e_val.bla > ${BASEDIR}results/prot_all_vs_all/${i}_blastp_${e_val}_filtered.bla
done

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: finished running ${0##*/}"
