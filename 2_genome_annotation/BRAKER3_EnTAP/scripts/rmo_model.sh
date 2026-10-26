#!/bin/bash -eu
set -o pipefail

# set directories, e.g. BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)
BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)
THREADS=$(grep '^THREADS=' config.cfg | cut -d= -f2)
NAME=$(grep '^NAME=' config.cfg | cut -d= -f2)
C_TETOOLS=$(grep '^C_TETOOLS=' config.cfg | cut -d= -f2)

# script
INPUT=${BASEDIR}results/rmo_db/${NAME}_db

echo [$(date)] Starting rmo_model.sh...

cd $BASEDIR

singularity exec --bind ${BASEDIR}:${BASEDIR} $C_TETOOLS RepeatModeler \
	-database $INPUT -threads $THREADS -LTRStruct
mv RM_* results/

printf "\n"
echo [$(date)] ... done!
