#!/bin/bash -eu
set -o pipefail

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: running ${0##*/}"

# set directories, e.g. BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)
BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)
THREADS=$(grep '^THREADS=' config.cfg | cut -d= -f2)
C_ENTAP=$(grep '^C_ENTAP=' config.cfg | cut -d= -f2)

cd $BASEDIR

singularity exec --bind ${BASEDIR}:${BASEDIR} $C_ENTAP EnTAP \
	--run \
	--run-ini ${BASEDIR}entap_run.params \
	--entap-ini ${BASEDIR}data/entap_config.ini \
	--eggnog-map-data ${BASEDIR}results/entap_config/databases\
	--eggnog-map-dmnd ${BASEDIR}results/entap_config/bin/eggnog_proteins.dmnd

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: finished ${0##*/}"
