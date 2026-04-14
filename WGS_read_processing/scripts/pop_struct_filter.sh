#!/bin/bash

module purge
module load bcftools/1.21

BASEDIR=$(grep 'BASEDIR=' config.cfg | cut -d= -f2)
OUTPUTDIR=${BASEDIR}results/12_filtersets/
THREADS=$2

# Set filter name
SET="pop_struct_filter"
INPUT=$1
OUTPUT=${OUTPUTDIR}$(basename -s .vcf.gz $INPUT )_${SET}.vcf.gz

date
printf "\n"

mkdir -p ${OUTPUTDIR}

bcftools view -m 2 -M 2 -e ' INFO/FS < 0.000001 || INFO/MQ < 40 || INFO/MQBZ < -12.5 || INFO/RPBZ < -4 || COUNT(GT="mis") > 0.1 * N_SAMPLES ' --threads ${THREADS} ${INPUT} | \
        awk '$1 ~ /^#/{print $0; next}
        {       
                d = 0
                for (i=10; i<= NF; i++) {
                        if($i !~ /^0\/0/) {
                                split($i,a,":")
                                d += a[3]
                        }
                }
                if (d == 0) {
                        next
                }
                if ($6 / d >= 5) {
                        print $0
                }
        }'  | \
        bcftools view --threads ${THREADS} - -o ${OUTPUT} -Oz --write-index

module purge

printf "\n"
date

