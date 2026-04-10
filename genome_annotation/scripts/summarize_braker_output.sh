#!/bin/bash -eu
set -o pipefail

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: running ${0##*/}"

# set directories, e.g. BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)
BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)
THREADS=$(grep '^THREADS=' config.cfg | cut -d= -f2)
DBPATH=$(grep '^DBPATH=' config.cfg | cut -d= -f2)
NAME=$(grep '^NAME=' config.cfg | cut -d= -f2)
BRAKER=/home/bross/singularity_cache/braker3_v3.0.7.6.sif
BUSCO=/home/bross/singularity_cache/busco_v5.8.2_cv1.sif
BDIR=${BASEDIR}results/$1
OUT=${BASEDIR}results/summary_$1/summary.txt

if [[ -z $1 ]]; then
	printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "ERROR: no target braker work-directory selected "
	exit
fi

# script
mkdir -p ${BASEDIR}results/summary_$1/

# get exon analysis
${BASEDIR}scripts/analyze_exons.py -f $BDIR/braker.gtf > $OUT.br
${BASEDIR}scripts/analyze_exons.py -f $BDIR/GeneMark-ETP/genemark.gtf > $OUT.gm
${BASEDIR}scripts/analyze_exons.py -f $BDIR/augustus.hints.gtf > $OUT.au

# get BUSCO analysis
singularity exec --bind ${BASEDIR}:${BASEDIR} $BUSCO busco \
        -i $BDIR/braker.aa -m proteins -l $DBPATH -c $THREADS \
        -o results/summary_$1/busco_braker/

singularity exec --bind ${BASEDIR}:${BASEDIR} $BUSCO busco \
        -i $BDIR/GeneMark-ETP/genemark.aa -m proteins -l $DBPATH -c $THREADS \
        -o results/summary_$1/busco_genemark/

singularity exec --bind ${BASEDIR}:${BASEDIR} $BUSCO busco \
        -i ${BDIR}/augustus.hints.aa -m proteins -l $DBPATH -c $THREADS \
        -o results/summary_$1/busco_augustus/

#write summary
printf "parameter\t\tbraker\tg.mark\taugustus\n" > $OUT
printf "gene count\t\t%d\t%d\t%d\n" $(awk '$3=="gene"{print $1}' results/braker-sr/braker.gtf | wc -l) $(awk '$3=="gene"{print $1}' results/braker-sr/GeneMark-ETP/genemark.gtf | wc -l) $(awk '$3=="gene"{print $1}' results/braker-sr/augustus.hints.gtf | wc -l) >> $OUT
printf "transcript count\t%d\t%d\t%d\t\t(counts all isoforms)\n" $(grep -c '>' $BDIR/braker.aa) $(grep -c '>' $BDIR/GeneMark-ETP/genemark.aa) $(grep -c '>' $BDIR/augustus.hints.aa) >> $OUT
printf "max exon count\t\t%d\t%d\t%d\n" $(grep '^Lar' $OUT.br | cut -d: -f2) $(grep '^Lar' $OUT.gm | cut -d: -f2) $(grep '^Lar' $OUT.au | cut -d: -f2) >> $OUT
printf "monoex. transcripts\t%d\t%d\t%d\n" $(grep '^Monoex' $OUT.br | cut -d: -f2) $(grep '^Monoex' $OUT.gm | cut -d: -f2) $(grep '^Monoex' $OUT.au | cut -d: -f2) >> $OUT
printf "multiex. transcripts\t%d\t%d\t%d\n" $(grep '^Multiex' $OUT.br | cut -d: -f2) $(grep '^Multiex' $OUT.gm | cut -d: -f2) $(grep '^Multiex' $OUT.au | cut -d: -f2) >> $OUT
printf "mono:multi ratio\t%s\t%s\t%s\n" $(grep '^Mono:' $OUT.br | cut -d: -f3) $(grep '^Mono:' $OUT.gm | cut -d: -f3) $(grep '^Mono:' $OUT.au | cut -d: -f3) >> $OUT
printf "BUSCO\t\t\t%s\t%s\t%s\n" $(grep 'C:' results/summary_$1/busco_braker/short*txt) $(grep 'C:' results/summary_$1/busco_genemark/short*txt) $(grep 'C:' results/summary_$1/busco_augustus/short*txt) >> $OUT

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: finished running ${0##*/}"
