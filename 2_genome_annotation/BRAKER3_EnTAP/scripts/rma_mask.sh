#!/bin/bash -eu
set -o pipefail

# set directories, e.g. BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)
BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)
THREADS=$(grep '^THREADS=' config.cfg | cut -d= -f2)
NAME=$(grep '^NAME=' config.cfg | cut -d= -f2)
C_TETOOLS=$(grep '^C_TETOOLS=' config.cfg | cut -d= -f2)

# script
INPUT=${BASEDIR}results/${NAME}_purified.fa
DB=${BASEDIR}results/rmo_db/${NAME}_db-families.fa

echo [$(date)] Starting rma_mask.sh...

cd $BASEDIR

singularity exec --bind ${BASEDIR}:${BASEDIR} $C_TETOOLS RepeatMasker \
	-lib $DB $INPUT -pa $THREADS -xsmall

printf "\n"
echo [$(date)] ... done!
