#!/bin/bash -eu
#SBATCH --nodes=1                               # min (and max, when only one value is listed) numbers of clusters that the job will consider (can also specifiy by name instead)
#SBATCH --ntasks=1                              # max numbers of concurrent tasks
#SBATCH --cpus-per-task=1                       # CPUs requested per task
#SBATCH --mem=50000MB                          # RAM allocation (per array job)
#SBATCH --partition=main                        # node group (small-jobs or main)
#SBATCH --array 1-4%4	                        # job array setup, with IDs 1 to 10 and 1 job running at a time
#SBATCH --job-name=01_prep_circos_data                   # job name to be used for logs, etc.
#SBATCH --mail-type=BEGIN,FAIL,END              # when to send emails
#SBATCH --mail-user=                           # where to send emails
#SBATCH --output slurm_logs/%A_%x/%x_%a.out      # output log location (A = job id, x = job name, a = array id)
#SBATCH --error slurm_logs/%A_%x/%x_%a.err       # error log location

# note for array jobs: one per haplotype

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: running ${0##*/} with the following slurm setup:"
echo "Name:             $SLURM_JOB_NAME"
echo "ID:               $SLURM_JOB_ID"
echo "Active directory: $SLURM_SUBMIT_DIR"
echo "Partition:        $SLURM_JOB_PARTITION"
echo "Tasks:            $SLURM_NTASKS"
echo "CPUs:             $SLURM_CPUS_PER_TASK"
echo "Memory:           $SLURM_MEM_PER_NODE"

HAPS=('vpTaxBacc_B23-6_hap1' 'vpTaxBacc_B23-6_hap2' 'vpTaxBacc_B34-6_hap1' 'vpTaxBacc_B34-6_hap2')
HAP=${HAPS[$(($SLURM_ARRAY_TASK_ID - 1))]}

ml bedtools/2.31.1
ml pyfaidx/0.8.1.3
ml bcftools/1.23.1
ml R/4.5.0

mkdir -p results/filtered_assembly_bed
mkdir -p results/window_bed

faidx -i bed -g ^B[23][34]6-h[12]-[0-9]+$ data/${HAP}.fa  > results/filtered_assembly_bed/${HAP}.bed
bedtools makewindows -b results/filtered_assembly_bed/${HAP}.bed -w 5000000 -s 2500000 > results/window_bed/${HAP}_windows.bed

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: Windows generated. Now preparing repeat elements"
mkdir -p results/repeat_elements

# prepare RE BED
awk -v OFS='\t' 'NR>3 && $5 !~ /unloc/ && $5 !~ /tg/ && $5 !~ /scaff/ {print $5, $6 - 1, $7, $11}' data/${HAP}_purified.fa.out | sort -k1,1V -k2,2n > results/repeat_elements/${HAP}_re.bed
# all TE
awk '{print $0}' results/repeat_elements/${HAP}_re.bed | \
bedtools coverage -sorted -a results/window_bed/${HAP}_windows.bed -b stdin | awk -v OFS='\t' '{print $1, $2, $3, $7}' > results/repeat_elements/${HAP}_re_fraction.bed
# only Gypsy
awk '$4 ~ /Gypsy/ {print $0}' results/repeat_elements/${HAP}_re.bed | \
bedtools coverage -sorted -a results/window_bed/${HAP}_windows.bed -b stdin | awk -v OFS='\t' '{print $1, $2, $3, $7}' > results/repeat_elements/${HAP}_re_fraction_gypsy.bed
# only Copia
awk '$4 ~ /Copia/ {print $0}' results/repeat_elements/${HAP}_re.bed | \
bedtools coverage -sorted -a results/window_bed/${HAP}_windows.bed -b stdin | awk -v OFS='\t' '{print $1, $2, $3, $7}' > results/repeat_elements/${HAP}_re_fraction_copia.bed

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: Repeat elements prepared. Now preparing structural variants"
mkdir -p results/structural_variants

ASM=$(echo ${HAP} | cut -d_ -f 2-3 | sed 's/-6_hap/6-h/')

awk -v OFS='\t' -v NAME=${ASM} '$7 == "SNP" && $1 ~ NAME {print $1, $2 - 1, $3}' data/combined_SVs.txt | \
bedtools coverage -a results/window_bed/${HAP}_windows.bed -b stdin > results/structural_variants/${HAP}_snp_counts.bed

awk -v OFS='\t' -v NAME=${ASM} '$7 != "SNP" && $1 ~ NAME && ($3 - $2 + 1) <= 50 {print $1, $2 - 1, $3}' data/combined_SVs.txt | \
bedtools coverage -a results/window_bed/${HAP}_windows.bed -b stdin > results/structural_variants/${HAP}_small_sv_counts.bed

awk -v OFS='\t' -v NAME=${ASM} '$7 != "SNP" && $1 ~ NAME && ($3 - $2 + 1) > 50 {print $1, $2 - 1, $3}' data/combined_SVs.txt | \
bedtools coverage -a results/window_bed/${HAP}_windows.bed -b stdin > results/structural_variants/${HAP}_large_sv_fractions.bed

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: Structural variants prepared. Now preparing gene counts"
mkdir -p results/gene_counts

awk -v OFS='\t' '$3 == "gene" {print $1, $4 - 1, $5}' data/${HAP}_tsebra_combined_renamed.gtf | \
bedtools coverage -a results/window_bed/${HAP}_windows.bed -b stdin -counts > results/gene_counts/${HAP}_gene_counts.bed

Rscript -e '
args <- commandArgs(trailingOnly=TRUE)

packages = c("tools","tidyverse","circlize","viridis","ComplexHeatmap")

package.check <- lapply(
  packages,
  FUN = function(x) {
      library(x, character.only = TRUE)
  }
)

colors <- cividis(6, alpha = 1, begin = 0.1, end = 0.9)

# read input argss
genome_bed <- read_table(paste0("results/filtered_assembly_bed/",args,".bed"), col_names = c("chr","start","end"))
repeat_frac_c <- read_table(paste0("results/repeat_elements/",args,"_re_fraction_copia.bed"), col_names = c("chr","start","end","copia_fraction"))
repeat_frac_g <- read_table(paste0("results/repeat_elements/",args,"_re_fraction_gypsy.bed"), col_names = c("chr","start","end","gypsy_fraction"))
snp_counts <- read_table(paste0("results/structural_variants/",args,"_snp_counts.bed"), col_types = "ciii---", col_names = c("chr","start","end","snp_count"))
small_sv_counts <- read_table(paste0("results/structural_variants/",args,"_small_sv_counts.bed"), col_types = "ciii---", col_names = c("chr","start","end","small_sv_count"))
large_sv_fractions <- read_table(paste0("results/structural_variants/",args,"_large_sv_fractions.bed"), col_types = "cii---d", col_names = c("chr","start","end","large_sv_frac"))
gene_counts <- read_table(paste0("results/gene_counts/",args,"_gene_counts.bed"), col_names = c("chr","start","end","gene_count"))

# save as source data table
dflist <- list(snp_counts, repeat_frac_c, repeat_frac_g, small_sv_counts, large_sv_fractions, gene_counts)
df <- dflist %>% reduce(full_join, by = c("chr","start","end"))
write_tsv(df, paste0("results/plots/",args,"_data.tsv"))

' $HAP

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: all scripts finished for ${0##*/}"