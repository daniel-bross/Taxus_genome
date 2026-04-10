#!/bin/bash -eu
set -o pipefail

# set directories, e.g. BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)
BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)
THREADS=$(grep '^THREADS=' config.cfg | cut -d= -f2)
NAME=$(grep '^NAME=' config.cfg | cut -d= -f2)

# script
INPUT=${BASEDIR}data/${NAME}.fa
UP=${BASEDIR}results/${NAME}_uppercase.fa
OUTPUT=${BASEDIR}results/${NAME}_purified.fa
REPORT=${BASEDIR}results/${NAME}_purify_report

echo "[$(date)] Starting sanitize.sh..."

cd $BASEDIR

echo "[$(date)] printing uppercase fasta file..."
awk '{ if ($0 !~ />/) {print toupper($0)} else {print $0} }' $INPUT > $UP

echo "[$(date)] Starting gaas_fasta_purify.pl..."
gaas_fasta_purify.pl --infile $UP --output $REPORT

echo "[$(date)] moving purified file to output destination..."
mv ${BASEDIR}results/${NAME}_purify_report/${NAME}_uppercase_purified.fa $OUTPUT

echo "[$(date)] ...done!"
