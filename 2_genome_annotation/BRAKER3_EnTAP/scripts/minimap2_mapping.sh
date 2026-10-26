#!/bin/bash -eu
set -o pipefail

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: running ${0##*/}"

# set directories, e.g. BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)
BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)
THREADS=$(grep '^THREADS=' config.cfg | cut -d= -f2)
NAME=$(grep '^NAME=' config.cfg | cut -d= -f2)
C_MINIMAP=$(grep '^C_MINIMAP=' config.cfg | cut -d= -f2)
CONDAPATH=$(grep '^CONDAPATH=' config.cfg | cut -d= -f2)
CENVNAME=$(grep '^CENVNAME=' config.cfg | cut -d= -f2)

GENOME=${BASEDIR}results/${NAME}.fa.combined.masked

cd $BASEDIR
mkdir -p ${BASEDIR}results/minimap2/
source $CONDAPATH
conda activate $CENVNAME

# generate minizer index, if it does not exist already
if [[ ! -e ${BASEDIR}results/minimap2/${NAME}.mmi ]]; then
singularity exec --bind ${BASEDIR}:${BASEDIR} $C_MINIMAP minimap2 \
	-t $THREADS -d ${BASEDIR}results/minimap2/${NAME}.mmi $GENOME
fi

# run minimap2 fpr every isoseq file
for i in $(ls ${BASEDIR}data/isoseq/); do
	FNAME=$(basename -s .fasta $i)
	singularity exec --bind ${BASEDIR}:${BASEDIR} $C_MINIMAP minimap2 \
	-t $THREADS --split-prefix=tmp_$i -G 500k -ax splice:hq -uf ${BASEDIR}results/minimap2/${NAME}.mmi ${BASEDIR}data/isoseq/$i > ${BASEDIR}results/minimap2/$FNAME.sam
	samtools view -bS --threads $THREADS ${BASEDIR}results/minimap2/$FNAME.sam -o ${BASEDIR}results/minimap2/$FNAME.bam
done

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: finished running ${0##*/}"
