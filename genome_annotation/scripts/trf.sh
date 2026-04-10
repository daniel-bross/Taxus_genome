#!/bin/bash -eu
set -o pipefail

# set directories, e.g. BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)
BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)
THREADS=$(grep '^THREADS=' config.cfg | cut -d= -f2)
NAME=$(grep '^NAME=' config.cfg | cut -d= -f2)
C_TETOOLS=$(grep '^C_TETOOLS=' config.cfg | cut -d= -f2)
CONDAPATH=$(grep '^CONDAPATH=' config.cfg | cut -d= -f2)
CENVNAME=$(grep '^CENVNAME=' config.cfg | cut -d= -f2)

# script
INPUT=${BASEDIR}results/${NAME}_purified.fa.masked
TRFDIR=${BASEDIR}results/trf/

echo [$(date)] Starting trf.sh...

cd ${BASEDIR}
source $CONDAPATH
conda activate $CENVNAME

mkdir -p $TRFDIR
scripts/splitMfasta.pl --minsize=25000000 --outputpath=$TRFDIR $INPUT

cd ${TRFDIR}

# Running TRF
ls ${TRFDIR}${NAME}_purified.fa.masked.split.*.fa | parallel singularity exec --bind ${BASEDIR}:${BASEDIR} $C_TETOOLS 'trf {} 2 7 7 80 10 50 500 -d -m -h'

cd ${BASEDIR}

# Parsing TRF output
# The script parseTrfOutput.py is from https://github.com/gatech-genemark/BRAKER2-exp
ls ${TRFDIR}${NAME}_purified.fa.masked.split.*.fa.2.7.7.80.10.50.500.dat | parallel "${BASEDIR}scripts/parseTrfOutput.py {} --minCopies 1 --statistics {}.STATS > {}.raw.gff 2> {}.parsedLog"

# Sorting parsed output..."
ls ${TRFDIR}${NAME}_purified.fa.masked.split.*.fa.2.7.7.80.10.50.500.dat.raw.gff | parallel 'sort -k1,1 -k4,4n -k5,5n {} > {}.sorted 2> {}.sortLog'

# Merging gff...
FILES=${TRFDIR}${NAME}_purified.fa.masked.split.*.fa.2.7.7.80.10.50.500.dat.raw.gff.sorted

for f in $FILES
do
    bedtools merge -i $f | awk 'BEGIN{OFS="\t"} {print $1,"trf","repeat",$2+1,$3,".",".",".","."}' > $f.merged.gff 2> $f.bedtools_merge.log
done

# Masking FASTA chunk
ls ${TRFDIR}${NAME}_purified.fa.masked.split.*.fa | parallel 'bedtools maskfasta -fi {} -bed {}.2.7.7.80.10.50.500.dat.raw.gff.sorted.merged.gff -fo {}.combined.masked -soft &> {}.bedools_mask.log'

# Concatenate split genome
cat ${TRFDIR}${NAME}_purified.fa.masked.split.*.fa.combined.masked > ${BASEDIR}results/${NAME}.fa.combined.masked

conda deactivate

printf "\n"
echo [$(date)] ... done!
