#!/bin/bash -eu
set -o pipefail

# compare GTF coordinates in TSEBRA output and transcript assembly to check for multiexonic genes in the transcript assembly which are listed as multiple monoexonic genes in the TSEBRA file

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: running ${0##*/}"

# set directories, e.g. BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)
BASEDIR=$(grep '^BASEDIR=' config.cfg | cut -d= -f2)
OUT=${BASEDIR}results/fragmented_genes_analysis/report.txt

#module load bedtools
# script

mkdir -p ${BASEDIR}results/fragmented_genes_analysis/

# extract the annotation's gene spaces
awk '$3=="gene"{print $0}' ${BASEDIR}results/tsebra/tsebra_combined.gtf > ${BASEDIR}results/fragmented_genes_analysis/tsebra_genes.gtf

# extract, sort and then merge all multiexonic transcripts from merged StringTie2 hints into gene spaces
arr=('sr' 'lr')
for i in "${arr[@]}"; do
	awk -f ${BASEDIR}scripts/get_multiexonic_transcripts.awk ${BASEDIR}results/braker-${i}/GeneMark-ETP/rnaseq/stringtie/transcripts_merged.gff | sort -k1,1 -k4,4n | bedtools merge -i stdin > ${BASEDIR}results/fragmented_genes_analysis/${i}_genespaces.bed
	declare -i ${i}_count=$(bedtools intersect -c -a ${BASEDIR}results/fragmented_genes_analysis/${i}_genespaces.bed -b ${BASEDIR}results/fragmented_genes_analysis/tsebra_genes.gtf | awk '$4 > 1 {print $0}' | wc -l)
	declare -i ${i}_sum=$(bedtools intersect -c -a ${BASEDIR}results/fragmented_genes_analysis/${i}_genespaces.bed -b ${BASEDIR}results/fragmented_genes_analysis/tsebra_genes.gtf | awk '$4 > 1 {sum += $4} END{print sum}')
done 

# get the same stats from the combined set
cat ${BASEDIR}results/fragmented_genes_analysis/sr_genespaces.bed ${BASEDIR}results/fragmented_genes_analysis/lr_genespaces.bed | sort -k1,1 -k2,2n | bedtools merge -i stdin > ${BASEDIR}results/fragmented_genes_analysis/merged_genespaces.bed
merged_count=$(bedtools intersect -c -a ${BASEDIR}results/fragmented_genes_analysis/merged_genespaces.bed -b ${BASEDIR}results/fragmented_genes_analysis/tsebra_genes.gtf | awk '$4 > 1 {print $0}' | wc -l)
merged_sum=$(bedtools intersect -c -a ${BASEDIR}results/fragmented_genes_analysis/merged_genespaces.bed -b ${BASEDIR}results/fragmented_genes_analysis/tsebra_genes.gtf | awk '$4 > 1 {sum += $4} END{print sum}')

# read out mono:multi-exonic gene ratio in annotation
awk -f ${BASEDIR}scripts/get_gtf_stats.awk ${BASEDIR}results/tsebra/tsebra_combined.gtf > ${BASEDIR}results/fragmented_genes_analysis/tsebra_stats.txt
mono_count=$(awk '$1=="23"{print $NF}' ${BASEDIR}results/fragmented_genes_analysis/tsebra_stats.txt)
multi_count=$(awk '$1=="24"{print $NF}' ${BASEDIR}results/fragmented_genes_analysis/tsebra_stats.txt)
primary_ratio=$(awk '$1=="25"{print $NF}' ${BASEDIR}results/fragmented_genes_analysis/tsebra_stats.txt)

# calculate changed ratios if mono:mult
sr_ratio=$( awk -v a=$mono_count -v b=$sr_sum -v c=$multi_count, -v d=$sr_count 'BEGIN{print (a - b) / (c + d)}')
lr_ratio=$( awk -v a=$mono_count -v b=$lr_sum -v c=$multi_count, -v d=$lr_count 'BEGIN{print (a - b) / (c + d)}')
merged_ratio=$( awk -v a=$mono_count -v b=$merged_sum -v c=$multi_count, -v d=$merged_count 'BEGIN{print (a - b) / (c + d)}')

cat > $OUT <<-EOL
Fragmented Genes Analysis results

1. Illumina short read dataset:
number of genes in the RNAseq data being intersected by more than one annotation: ${sr_count}
sum of intersections: ${sr_sum}
=> ${sr_count} genes may have been "fragmented" to look like ${sr_sum} genes in the annotation output
=> Correcting this would change the mono:mult ratio from $primary_ratio to $sr_ratio

2. PacBio IsoSeq dataset:
number of genes in the RNAseq data being intersected by more than one annotation: ${lr_count}
sum of intersections: ${lr_sum}
=> ${lr_count} genes may have been "fragmented" to look like ${lr_sum} genes in the annotation output
=> Correcting this would change the mono:mult ratio from $primary_ratio to $lr_ratio

3. combined set
number of genes in the RNAseq data being intersected by more than one annotation: ${merged_count}
sum of intersections: ${merged_sum}
=> ${merged_count} genes may have been "fragmented" to look like ${merged_sum} genes in the annotation output
=> Correcting this would change the mono:mult ratio from $primary_ratio to $merged_ratio

EOL

# generate filterset without these annotations
bedtools intersect -wa -wb -a ${BASEDIR}results/fragmented_genes_analysis/merged_genespaces.bed -b ${BASEDIR}results/fragmented_genes_analysis/tsebra_genes.gtf | awk '{print $1,$2,$3}' | uniq -c | awk 'BEGIN{OFS="\t"} $1>1{print $2,$3,$4}' > ${BASEDIR}results/fragmented_genes_analysis/exclude.bed
bedtools intersect -wa -wb -a ${BASEDIR}results/fragmented_genes_analysis/merged_genespaces.bed -b ${BASEDIR}results/fragmented_genes_analysis/tsebra_genes.gtf | sort -k1,1 -k2,2n -k3,3n | uniq -uw 20 | awk 'BEGIN{OFS="\t"}{print $1, $2, $3}' > ${BASEDIR}results/fragmented_genes_analysis/merged_unique_genespaces.bed
grep -v -f ${BASEDIR}results/fragmented_genes_analysis/merged_unique_genespaces.bed ${BASEDIR}results/fragmented_genes_analysis/merged_genespaces.bed > ${BASEDIR}results/fragmented_genes_analysis/merged_dup_genespaces.bed

# v1 (remove all genes that overlap with transcript regions that contain fragmented genes)
bedtools intersect -v -a ${BASEDIR}results/tsebra/tsebra_combined.gtf -b ${BASEDIR}results/fragmented_genes_analysis/merged_dup_genespaces.bed > ${BASEDIR}results/fragmented_genes_analysis/tsebra_fragfiltered.gtf


#module purge
printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: finished running ${0##*/}"
