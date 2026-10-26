#!/bin/bash -eu
#SBATCH --nodes=1				# min (and max, when only one value is listed) numbers of clusters that the job will consider (can also specifiy by name instead)
#SBATCH --ntasks=1				# max numbers of concurrent tasks
#SBATCH --cpus-per-task=1			# CPUs requested per task
#SBATCH --mem=30000MB				# RAM allocation (per array job)
#SBATCH --partition=main			# node group (small-jobs or main)
#SBATCH --array 1-4%4				# job array setup, with IDs 1 to 10 and 1 job running at a time
#SBATCH --job-name=upset_plot		# job name to be used for logs, etc.
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
library(UpSetR)

input <- commandArgs(trailingOnly = TRUE)
targets=c('vpTaxBacc_B23-6_hap1', 'vpTaxBacc_B23-6_hap2', 'vpTaxBacc_B34-6_hap1', 'vpTaxBacc_B34-6_hap2')
valid_targets <- setdiff(targets, input)

gene_sets <- list()

# Read input annotation file
input_file <- paste0("results/source_data/",input, "_annotation_list_genes.renamed.txt")
gene_sets[[input]] <- readLines(input_file)

# Read comparison files
for (target in valid_targets) {
  file <- paste0("source_data/sorted_", input, "_vs_", target, "_mapped.genes.list.txt")
  key <- target
  gene_sets[[key]] <- readLines(file)
}

# Create binary matrix
binary_matrix <- fromList(gene_sets)
names(binary_matrix)[names(binary_matrix) == 'f1'] <- 'Tb_female-h1'
names(binary_matrix)[names(binary_matrix) == 'f2'] <- 'Tb_female-h2'
names(binary_matrix)[names(binary_matrix) == 'm1'] <- 'Tb_male-h1'
names(binary_matrix)[names(binary_matrix) == 'm2'] <- 'Tb_male-h2'
  
# Plot regular scale
pdf(paste0("results/upset/",input,"upset_1.pdf"), width = 6, height = 3, compress = FALSE)
print(upset(binary_matrix, sets = c("Tb_female-h1", "Tb_female-h2", "Tb_male-h1", "Tb_male-h2"), order.by = "freq", mainbar.y.label = "Gene set size"))
dev.off()

pdf(paste0("results/upset/",input,"upset_2.pdf"), width = 6, height = 3, compress = FALSE)
print(upset(binary_matrix, sets = c("Tb_female-h1", "Tb_female-h2", "Tb_male-h1", "Tb_male-h2"), order.by = "freq", mainbar.y.label = "Gene set size", mainbar.y.max = 1000))
dev.off()

' ${HAP}