#!/bin/bash -eu
set -o pipefail

# set directories, e.g. BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)
BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)
NAME=$(grep '^NAME=' config.cfg | cut -d= -f2)
C_TETOOLS=$(grep '^C_TETOOLS=' config.cfg | cut -d= -f2)

# script
INPUT=${BASEDIR}results/${NAME}_purified.fa

echo "[$(date)] Starting rmo_database.sh..."

cd $BASEDIR
mkdir -p results/rmo_db/

singularity exec --bind ${BASEDIR}:${BASEDIR} $C_TETOOLS BuildDatabase \
	-name results/rmo_db/${NAME}_db $INPUT

printf "\n"
echo "[$(date)] ... done!"
