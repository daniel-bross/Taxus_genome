#!/bin/bash -eu
set -o pipefail

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: running ${0##*/}"

module purge
module load multiqc/1.27.1

BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)
TARGETDIR=$1

if [[ ! -d ${TARGETDIR} ]]; then
  echo "Usage: multiqc.sh [Target directory]"
  exit
fi

lscpu
printf "\n"

multiqc -f -o ${BSEDIR}${TARGETDIR}multiqc/ ${BASEDIR}${TARGETDIR}

module purge

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: finished running ${0##*/}"
