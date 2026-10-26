#!/bin/bash -eu
#SBATCH --nodes=1				# min (and max, when only one value is listed) numbers of clusters that the job will consider (can also specifiy by name instead)
#SBATCH --ntasks=1				# max numbers of concurrent tasks
#SBATCH --cpus-per-task=1			# CPUs requested per task
#SBATCH --mem=40000MB				# RAM allocation (per array job)
#SBATCH --partition=main			# node group (small-jobs or main)
#SBATCH --array 1-4%4				# job array setup, with IDs 1 to 10 and 1 job running at a time
#SBATCH --job-name=01_prep_intervals		# job name to be used for logs, etc.
#SBATCH --mail-type=BEGIN,FAIL,END		# when to send emails
#SBATCH --mail-user=
#SBATCH --output slurm_logs/%A_%x/%x%a.out	# output log location (A = job id, x = job name, a = array id)
#SBATCH --error slurm_logs/%A_%x/%x%a.err	# error log location

# note for array jobs: one per haplotype

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: running ${0##*/} with the following slurm setup:"
echo "Name:		$SLURM_JOB_NAME"
echo "ID:		$SLURM_JOB_ID"
echo "Active directory: $SLURM_SUBMIT_DIR"
echo "Partition:	$SLURM_JOB_PARTITION"
echo "Tasks:		$SLURM_NTASKS"
echo "CPUs:		$SLURM_CPUS_PER_TASK"
echo "Memory:		$SLURM_MEM_PER_NODE"

mkdir -p results/genome_sizes/
mkdir -p results/features/
mkdir -p results/structural_variants/

module load bedtools/2.31.1  

HAPS=('vpTaxBacc_B23-6_hap1' 'vpTaxBacc_B23-6_hap2' 'vpTaxBacc_B34-6_hap1' 'vpTaxBacc_B34-6_hap2')
CODES=('fh1' 'fh2' 'mh1' 'mh2')
HAP=${HAPS[$(($SLURM_ARRAY_TASK_ID - 1))]}
CODE=${CODES[$(($SLURM_ARRAY_TASK_ID - 1))]}
ASM=$(echo $HAP | cut -d_ -f 2-3 | sed "s/-6_hap/6-h/")
awk -v OFS="\t" '{print $1, $3}' data/${HAP}.bed > results/genome_sizes/${HAP}.gs

awk -v OFS="\t" '$3 == "gene" {print $1, $4 - 1, $5, $9, $6, $7}' data/${CODE}_tsebra_combined_renamed.gtf | bedtools sort -i stdin -g results/genome_sizes/${HAP}.gs > results/features/${HAP}_genes.bed
awk -v OFS="\t" '$3 == "exon" && $10 ~ /.t1"/ {print $1, $4 - 1, $5}' data/${CODE}_tsebra_combined_renamed.gtf | bedtools sort -i stdin -g results/genome_sizes/${HAP}.gs > results/features/${HAP}_exons.bed
awk -v OFS="\t" '$3 == "intron" && $10 ~ /.t1"/ {print $1, $4 - 1, $5}' data/${CODE}_tsebra_combined_renamed.gtf | bedtools sort -i stdin -g results/genome_sizes/${HAP}.gs > results/features/${HAP}_introns.bed
bedtools flank -s -l 5000 -r 0 -i results/features/${HAP}_genes.bed -g results/genome_sizes/${HAP}.gs | bedtools sort -i stdin -g results/genome_sizes/${HAP}.gs | bedtools subtract -a stdin -b results/features/${HAP}_genes.bed  | bedtools sort -i stdin -g results/genome_sizes/${HAP}.gs > results/features/${HAP}_promotor.bed
bedtools slop -s -l 5000 -r 0 -i results/features/${HAP}_genes.bed -g results/genome_sizes/${HAP}.gs | bedtools sort -i stdin -g results/genome_sizes/${HAP}.gs | bedtools complement -i stdin -g results/genome_sizes/${HAP}.gs > results/features/${HAP}_intergenic.bed

awk -v OFS="\t" -v NAME=${ASM} '$7 == "SNP" && $1 ~ NAME {print $1, $2 - 1, $3}' data/combined_SVs.txt | bedtools sort -i stdin -g results/genome_sizes/${HAP}.gs > results/structural_variants/${HAP}_snps.bed
awk -v OFS="\t" -v NAME=${ASM} '$7 != "SNP" && $1 ~ NAME && ($3 - $2 + 1) <= 50 {print $1, $2 - 1, $3}' data/combined_SVs.txt | bedtools sort -i stdin -g results/genome_sizes/${HAP}.gs > results/structural_variants/${HAP}_small_svs.bed
awk -v OFS="\t" -v NAME=${ASM} '$1 ~ NAME && ($3 - $2 + 1) > 50 {print $1, $2 - 1, $3}' data/combined_SVs.txt | bedtools sort -i stdin -g results/genome_sizes/${HAP}.gs > results/structural_variants/${HAP}_large_svs.bed

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: all scripts finished for ${0##*/}"
