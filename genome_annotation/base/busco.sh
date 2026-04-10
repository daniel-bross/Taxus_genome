#!/bin/bash
# (or other, specifiy in first line)

# set directories, e.g. BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)
BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)
THREADS=$(grep '^THREADS=' config.cfg | cut -d= -f2)
DBPATH=$(grep '^DBPATH=' config.cfg | cut -d= -f2)
NAME=$(grep '^NAME=' config.cfg | cut -d= -f2)
C_BUSCO=$(grep '^C_BUSCO=' config.cfg | cut -d= -f2)

# script
INPUT=${BASEDIR}results/${NAME}_purified.fa
OUTPUT=results/${NAME}_busco_report/

echo "[$(date)] Starting busco.sh..."

cd $BASEDIR

singularity exec --bind ${BASEDIR}:${BASEDIR} $C_BUSCO busco \
	-i $INPUT -m genome -o $OUTPUT -l $DBPATH -c $THREADS

echo "[$(date)] ... done!"
