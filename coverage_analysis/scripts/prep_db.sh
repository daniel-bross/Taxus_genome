#!/bin/bash
set -o pipefail

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: running ${0##*/}"

module load libmysql++/3.3.0

# Declare mapping file paths in files
BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)
COVDIR=${BASEDIR}results/02_coverages/
FEMALE_MAPPINGS=${BASEDIR}data/female_mappings.txt
MALE_MAPPINGS=${BASEDIR}data/male_mappings.txt

DB=${COVDIR}coverages.db
FCOUNT=$(cat ${FEMALE_MAPPINGS} | wc -l)
MCOUNT=$(cat ${MALE_MAPPINGS} | wc -l)

# create sqlite database table with header
sqlite3 -batch ${DB} "CREATE TABLE t1(chr TEXT, start INT, end INT $(for i in $(seq 1 ${FCOUNT}); do echo -n , f_$i INT ;done) $(for i in $(seq 1 ${MCOUNT}); do echo -n , m_$i INT ;done));"

# import coverage data into database table
for i in $(ls ${COVDIR}*.txt); do
sqlite3 -batch ${DB} << EOF
.mode tabs
.import $i t1
EOF
done

printf "\n"
date

module purge
