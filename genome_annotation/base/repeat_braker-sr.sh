#!/bin/bash
# (or other, specifiy in first line)

# set directories, e.g. BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)
BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)
THREADS=$(grep '^THREADS=' config.cfg | cut -d= -f2)
NAME=$(grep '^NAME=' config.cfg | cut -d= -f2)
C_BRAKERsr=$(grep '^C_BRAKERsr=' config.cfg | cut -d= -f2)

INPUT=${BASEDIR}results/${NAME}.fa.combined.masked
BRAKERDIR=${BASEDIR}results/braker-sr/
RNADIR=${BASEDIR}data/rnaseq-sr/
RNANAMES=$(cat ${BASEDIR}data/rna_id_list.txt)
#BAMFILES=$(cat ${BASEDIR}data/rna_bam_list.txt) # these have been generated in a previous braker run
PROTDB=${BASEDIR}data/protdb_Viridiplantae_uniprotpe3_clean.fa

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: starting ${0##*/}..."

cd $BASEDIR
mkdir -p $BRAKERDIR

singularity exec --bind ${BASEDIR}:${BASEDIR} $C_BRAKERsr braker.pl \
	--workingdir=$BRAKERDIR \
	--genome=$INPUT \
        --rnaseq_sets_ids=$RNANAMES \
        --rnaseq_sets_dirs=$RNADIR \
        --prot_seq=$PROTDB \
	--threads $THREADS \
	--gff3 \
	--nocleanup \
	--AUGUSTUS_ab_initio \
	--verbosity=4 \
	--species="taxus_baccata-sr" \
	--useexisting


printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: ${0##*/} finished"
