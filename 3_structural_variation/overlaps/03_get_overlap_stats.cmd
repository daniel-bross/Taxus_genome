#!/bin/bash -eu
#SBATCH --nodes=1				# min (and max, when only one value is listed) numbers of clusters that the job will consider (can also specifiy by name instead)
#SBATCH --ntasks=1				# max numbers of concurrent tasks
#SBATCH --cpus-per-task=1			# CPUs requested per task
#SBATCH --mem=1000MB				# RAM allocation (per array job)
#SBATCH --partition=main			# node group (small-jobs or main)
#SBATCH --array 1-4%4				# job array setup, with IDs 1 to 10 and 1 job running at a time
#SBATCH --job-name=03_get_overlap_stats		# job name to be used for logs, etc.
#SBATCH --mail-type=BEGIN,FAIL,END		# when to send emails
#SBATCH --mail-user=
#SBATCH --output slurm_logs/%A_%x/%x%a.out	# output log location (A = job id, x = job name, a = array id)
#SBATCH --error slurm_logs/%A_%x/%x%a.err	# error log location

# note for array jobs: one per haploypte

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: running ${0##*/} with the following slurm setup:"
echo "Name:		$SLURM_JOB_NAME"
echo "ID:		$SLURM_JOB_ID"
echo "Active directory: $SLURM_SUBMIT_DIR"
echo "Partition:	$SLURM_JOB_PARTITION"
echo "Tasks:		$SLURM_NTASKS"
echo "CPUs:		$SLURM_CPUS_PER_TASK"
echo "Memory:		$SLURM_MEM_PER_NODE"

mkdir -p results/plots/
module load R/4.5.0  

HAPS=('vpTaxBacc_B23-6_hap1' 'vpTaxBacc_B23-6_hap2' 'vpTaxBacc_B34-6_hap1' 'vpTaxBacc_B34-6_hap2')
HAP=${HAPS[$(($SLURM_ARRAY_TASK_ID - 1))]}

Rscript -e '
library(tidyverse)
library(R.utils)

hap <- commandArgs(trailingOnly = TRUE)
features <- c("genes", "introns", "exons", "promotor", "intergenic")
svs <- c("snps", "small_svs", "large_svs")

get_fraction <- function(file) {
    dat <- read_tsv(file, col_names = FALSE, progress = FALSE, show_col_types = FALSE) %>% pull(-1)
    length(which(dat != 0)) / length(dat)
}

df <- crossing(feature = features, sv = svs) %>%
    mutate(prefix = paste0("results/overlaps/", hap, "_", feature, "_", tolower(sv)), count = map_dbl(paste0("results/structural_variants/",hap,"_",tolower(sv),".bed"), countLines), fraction = map_dbl(paste0(prefix, "_overlap_count.bed"), get_fraction)) %>%
    pivot_longer(cols = c("fraction")) %>% select(!prefix)

write_tsv(df, paste0("results/plots/",hap,"_gene_sv_overlaps.tsv"))

' ${HAP}

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: all scripts finished for ${0##*/}"
