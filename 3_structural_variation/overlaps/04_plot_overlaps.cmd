#!/bin/bash -eu
#SBATCH --nodes=1				# min (and max, when only one value is listed) numbers of clusters that the job will consider (can also specifiy by name instead)
#SBATCH --ntasks=1				# max numbers of concurrent tasks
#SBATCH --cpus-per-task=1			# CPUs requested per task
#SBATCH --mem=30000MB				# RAM allocation (per array job)
#SBATCH --partition=main			# node group (small-jobs or main)
#SBATCH --array 1-4%4				# job array setup, with IDs 1 to 10 and 1 job running at a time
#SBATCH --job-name=04_plot_overlap		# job name to be used for logs, etc.
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

hap <- commandArgs(trailingOnly = TRUE)

df <- read_tsv(paste0("results/plots/",hap,"_gene_sv_overlaps.tsv")) %>% mutate(sv = factor(sv, levels = c("snps", "small_svs", "large_svs")))

feature_levels <- c("genes", "introns", "exons", "promotor", "intergenic")
sv_levels <- c("snps","small_svs","large_svs")
facet_labels <- df %>% mutate(label = paste0(gsub("_", " ", sv), "\n(n = ", format(count, big.mark = ",", trim = TRUE), ")")) %>% select(sv, label) %>% deframe()

plot <- ggplot(df %>% filter(name == "fraction"), aes(x = factor(feature, levels = feature_levels), y = value, fill = feature)) +
    geom_col() +
    facet_wrap(vars(factor(sv, levels = sv_levels)), scales = "free_y", labeller = as_labeller(facet_labels)) +
    labs(x = "Genomic Feature", y = "Fraction of affected features") +
    scale_fill_viridis_d(option = "viridis", begin = 0.2, end = 0.8) +
    scale_y_continuous(limits = c(0, 1)) +
    theme_classic(base_size = 7) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = "none")
ggsave(paste0("results/plots/",hap,"_","fraction_of_affected_features.pdf"), plot, width = 3, height = 2)

' ${HAP}

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: all scripts finished for ${0##*/}"
