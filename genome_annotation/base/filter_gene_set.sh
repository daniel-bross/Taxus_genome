#!/bin/bash -eu
set -o pipefail

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: running ${0##*/}"

# set directories, e.g. BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)
BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)

#module load bedtools
# script

mkdir -p ${BASEDIR}results/geneset_filter/

awk '{
switch ($3) {
	case "exon":
		if ($5 - $4 >= 19) {print $0}
	case "CDS":
		if ($5 - $4 >= 19) {print $0}
	default:
		print $0	
	}

}' ${BASEDIR}results/tsebra/tsebra_combined.gtf > ${BASEDIR}results/geneset_filter/tsebra_exonl_min_20bp.gtf

awk '{
switch ($3) {
        case "intron":
                if ($5 - $4 >= 19) {print $0}
        default:
                print $0        
        }
}' ${BASEDIR}results/tsebra/tsebra_combined.gtf > ${BASEDIR}results/geneset_filter/tsebra_intronl_min_20bp.gtf



#module purge
printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: finished running ${0##*/}"
