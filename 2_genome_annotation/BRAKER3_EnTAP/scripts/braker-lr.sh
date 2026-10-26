#!/bin/bash -eu
set -o pipefail

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: running ${0##*/}"

# set directories, e.g. BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)

BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)
THREADS=$(grep '^THREADS=' config.cfg | cut -d= -f2)
NAME=$(grep '^NAME=' config.cfg | cut -d= -f2)
C_BRAKERlr=$(grep '^C_BRAKERlr=' config.cfg | cut -d= -f2)
DBPATH=$(grep '^DBPATH=' config.cfg | cut -d= -f2)
AUG_SPECIES_LR=$(grep '^AUG_SPECIES_LR=' config.cfg | cut -d= -f2)

INPUT=${BASEDIR}results/${NAME}.fa.combined.masked
BRAKERDIR=${BASEDIR}results/braker-lr/
BAMFILES=$(cat ${BASEDIR}data/isoseq_bam_list.txt) # comma separated list of paths
PROTDB=${BASEDIR}data/protdb_Viridiplantae_uniprotpe3_clean.fa

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: starting braker.sh..."

cd $BASEDIR
mkdir -p $BRAKERDIR

singularity exec --cleanenv --bind ${BASEDIR}:${BASEDIR} $C_BRAKERlr braker.pl \
        --workingdir=$BRAKERDIR \
        --genome=$INPUT \
        --bam=$BAMFILES \
        --prot_seq=$PROTDB \
        --threads $THREADS \
        --gff3 \
        --nocleanup \
        --AUGUSTUS_ab_initio \
        --verbosity=4 \
        --species=$AUG_SPECIES_LR \
	--useexisting


printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: finished running ${0##*/}"
