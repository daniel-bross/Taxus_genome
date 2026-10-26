#!/bin/bash -eu
#SBATCH --nodes=1				# min (and max, when only one value is listed) numbers of clusters that the job will consider (can also specifiy by name instead)
#SBATCH --ntasks=1				# max numbers of concurrent tasks
#SBATCH --cpus-per-task=1			# CPUs requested per task
#SBATCH --mem=30000MB				# RAM allocation (per array job)
#SBATCH --partition=main			# node group (small-jobs or main)
#SBATCH --array 1-4%4				# job array setup, with IDs 1 to 10 and 1 job running at a time
#SBATCH --job-name=plot_feature_sv_overlaps		# job name to be used for logs, etc.
#SBATCH --mail-type=BEGIN,FAIL,END		# when to send emails
#SBATCH --mail-user=daniel.bross@thuenen.de	# where to send emails
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
features <- c("genes", "introns", "exons", "promotor", "intergenic")
svs <- c("snps", "small_svs", "large_svs")

get_frac <- function(file) {
    dat <- read_tsv(file, col_names = FALSE, progress = FALSE, show_col_types = FALSE) %>% pull(-1)
    length(which(dat != 0)) / length(dat)
}
get_area <- function(file) {
    dat <- read_tsv(file, col_names = FALSE, progress = FALSE, show_col_types = FALSE) %>% pull(-1) %>% sum()
}

df <- crossing(feature = features, sv = svs) %>%
    mutate(prefix = paste0("data/feature_sv_overlaps/", hap, "_", feature, "_", tolower(sv)), frac = map_dbl(paste0(prefix, "_overlap_count.bed"), get_frac), area = map_dbl(paste0(prefix, "_overlap_area.bed"), get_area)) %>%
    pivot_longer(cols = c("area","frac"))

write_tsv(df, paste0("results/source_data/",hap,"_feature_sv_overlaps.tsv"))
#df <- read_tsv(paste0("results/source_data/",hap,"_feature_sv_overlaps.tsv"))

plot <- ggplot(df %>% filter(name == "frac"), aes(x = factor(feature, levels = features), y = value, fill = feature)) +
    geom_col() +
    facet_wrap(vars(factor(sv, levels = svs)), scales = "free_y") +
    labs(x = "Genomic Feature", y = "Fraction of affected features") +
    scale_fill_viridis_d(option = "viridis", begin = 0.2, end = 0.8) +
    scale_y_continuous(limits = c(0, 1)) +
    theme_classic(base_size = 7) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = "none")
ggsave(paste0("results/plots/",hap,"_","fraction_of_affected_features.pdf"), plot, width = 4, height = 3, units = "in")

plot <- ggplot(df %>% filter(name == "area"), aes(x = factor(feature, levels = features), y = value, fill = feature)) +
    geom_col() +
    facet_wrap(vars(factor(sv, levels = svs)), scales = "free_y") +
    labs(x = "Genomic Feature", y = "Affected area (bp)") +
    scale_fill_viridis_d(option = "viridis", begin = 0.2, end = 0.8) +
    theme_classic(base_size = 7) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = "none")
ggsave(paste0("results/plots/",hap,"_areas.pdf"), plot, width = 4, height = 3, units = "in")

' ${HAP}

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: all scripts finished for ${0##*/}"
