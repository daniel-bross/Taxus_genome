#!/bin/bash -eu
set -o pipefail

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: running ${0##*/}"

# set directories, e.g. BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)
BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)
THREADS=$(grep '^THREADS=' config.cfg | cut -d= -f2)
NAME=$(grep '^NAME=' config.cfg | cut -d= -f2)
CONTAINER=/home/bross/singularity_cache/braker3_v3.0.7.6.sif

mkdir -p ${BASEDIR}results/tsebra

singularity exec --bind ${BASEDIR}:${BASEDIR} $CONTAINER tsebra.py \
	--filter_single_exon_genes \
	-c /opt/TSEBRA/config/default.cfg \
	-g ${BASEDIR}results/braker-sr/braker.gtf,${BASEDIR}results/braker-lr/braker.gtf \
	-e ${BASEDIR}results/braker-sr/hintsfile.gff,${BASEDIR}results/braker-lr/hintsfile.gff \
	-o ${BASEDIR}results/tsebra/tsebra_combined.gtf

singularity exec --bind ${BASEDIR}:${BASEDIR} $CONTAINER rename_gtf.py \
	--gtf ${BASEDIR}results/tsebra/tsebra_combined.gtf \
	--out ${BASEDIR}results/tsebra/tsebra_combined_renamed.gtf \
	--translation_tab ${BASEDIR}results/tsebra/tsebra_combined_rename_translation.tbl

singularity exec --cleanenv --bind ${BASEDIR}:${BASEDIR} $CONTAINER python /opt/Augustus/scripts/getAnnoFastaFromJoingenes.py \
	-g ${BASEDIR}results/braker-sr/GeneMark-ETP/data/genome.fasta \
	-f ${BASEDIR}results/tsebra/tsebra_combined_renamed.gtf \
	-o ${BASEDIR}results/tsebra/tsebra_combined_renamed
		

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: finished running ${0##*/}"
