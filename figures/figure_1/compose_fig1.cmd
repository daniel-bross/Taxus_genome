#!/bin/bash -eu
#SBATCH --nodes=1				# min (and max, when only one value is listed) numbers of clusters that the job will consider (can also specifiy by name instead)
#SBATCH --ntasks=1				# max numbers of concurrent tasks
#SBATCH --cpus-per-task=1			# CPUs requested per task
#SBATCH --mem=30000MB				# RAM allocation (per array job)
#SBATCH --partition=main			# node group (small-jobs or main)
#SBATCH --array 1-1%1				# job array setup, with IDs 1 to 10 and 1 job running at a time
#SBATCH --job-name=compose_fig1 		# job name to be used for logs, etc.
#SBATCH --mail-type=BEGIN,FAIL,END		# when to send emails
#SBATCH --mail-user=daniel.bross@thuenen.de	# where to send emails
#SBATCH --output slurm_logs/%A_%x/%x%a.out	# output log location (A = job id, x = job name, a = array id)
#SBATCH --error slurm_logs/%A_%x/%x%a.err	# error log location

# note for array jobs: -

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

Rscript -e '
library("tidyverse")
library("patchwork")

# load data
circos_path <- "results/plots/fh1_circos.pdf"
asm_bars <- read_tsv("")
upset_path <- 

# plot raster images
design <- "112\n112\n334\n555"

plot_vector <- pca + kmer_set_sizes +
        (free(kmer_consistency_random + kmer_consistency_population, side = "r")) + qq + manhattan +
        plot_layout(design = design, heights = c(1,1,1,0.75)) + plot_annotation(tag_levels = 'a')

ggsave("results/fig1.pdf", plot_vector, device = "pdf",  height = 210, width = 180, unit = "mm", compress = TRUE)