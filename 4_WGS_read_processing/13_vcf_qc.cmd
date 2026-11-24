#!/bin/bash -eu
#SBATCH --nodes=1				# min (and max, when only one value is listed) numbers of clusters that the job will consider (can also specifiy by name instead)
#SBATCH --ntasks=1				# max numbers of concurrent tasks
#SBATCH --cpus-per-task=1			# CPUs requested per task
#SBATCH --mem=15000MB				# RAM allocation (per array job)
#SBATCH --partition=main			# node group (small-jobs or main)
#SBATCH --array 1-1%1			 	# job array setup, with IDs 1 to 10 and 1 job running at a time
#SBATCH --job-name=13_vcf_qc		# job name to be used for logs, etc.
#SBATCH --mail-type=BEGIN,FAIL,END		# when to send emails
#SBATCH --mail-user=daniel.bross@thuenen.de	# where to send emails
#SBATCH --output slurm_logs/%A_%x/%x_%a.out	# output log location (A = job id, x = job name, a = array id)
#SBATCH --error slurm_logs/%A_%x/%x_%a.err	# error log locationSBATCH --error slurm_logs/%A_%x/%x_%a.err       # error log location

# note for array jobs: one job

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: running ${0##*/} with the following slurm setup:"
echo "Name:		$SLURM_JOB_NAME"
echo "ID:		$SLURM_JOB_ID"
echo "Active directory: $SLURM_SUBMIT_DIR"
echo "Partition:	$SLURM_JOB_PARTITION"
echo "Tasks:		$SLURM_NTASKS"
echo "CPUs:		$SLURM_CPUS_PER_TASK"
echo "Memory:		$SLURM_MEM_PER_NODE"

module load bcftools/1.21
module load R/4.5.0

FNAME=$(basename -s .vcf.gz $1)
mkdir -p results/11_vcf_stats/${FNAME}/

bcftools view --header-only $1 > results/11_vcf_stats/${FNAME}/${FNAME}.vcf
bcftools view --no-header $1 | awk 'BEGIN{srand()}{if(rand() < 0.001) print $0}' >> results/11_vcf_stats/${FNAME}/${FNAME}.vcf

FMT='%ID\t%QUAL\t%INFO/DP\t%INFO/AD\t%INFO/VDB\t%INFO/SGB\t%INFO/RPBZ\t%INFO/MQBZ\t%INFO/MQSBZ\t%INFO/BQBZ\t%INFO/SCBZ\t%INFO/FS\t%INFO/MQ0F\t%INFO/AC\t%INFO/AN\t%INFO/DP4\t%INFO/MQ\n'
bcftools query -H -f ${FMT} $1 -o results/11_vcf_stats/${FNAME}/${FNAME}_stats.tsv

Rscript -e '
args <- commandArgs(trailingOnly=TRUE)

# Define packages to load
packages = c("tidyverse","data.table","viridis")
package.check <- lapply(packages, FUN = function(x) {library(x, character.only = TRUE)})

outdir <- paste0("results/11_vcf_stats/",args[1],"/")

dt <- fread(paste0("results/11_vcf_stats/",args[1],"/",args[1],"_stats.tsv"))

# calculate mode of DP distribution
d <- density(dt$`[3]DP`)
dmode <- d$x[which.max(d$y)] 

# generate histograms from INFO fields
colnames(dt) <- colnames(dt) %>% gsub("#{0,1}\\[\\d{1,}\\]{1}","\\1",.)

dplotcols <- c("QUAL", "DP", "SGB", "RPBZ", "MQBZ", "MQSBZ", "BQBZ", "SCBZ", "FS", "MQ0F", "AN", "MQ")
dp4plotcols <- c("DP4")

for (i in dplotcols) {
	var <- i
	try(df <- dt[, ..var] %>% as_tibble())
	plot <- ggplot(df, aes(x=!! rlang::sym(i))) +
		geom_histogram(bins = 100) +
		theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)) +
		labs(title=paste0(args[1], ": ", i))
	ggsave(paste0("plot_",i,".pdf"), plot, device = "pdf", width = 15, height = 9, path = file.path(outdir))
}

dp4dt <- dt %>% select(DP4) %>% separate_wider_delim(DP4, delim=",", names= c("ref-for", "ref-rev", "alt-for", "alt-rev")) %>% pivot_longer(everything(),names_to= "type", values_to="count") %>% arrange(type) %>% mutate(type = as.factor(type), count = as.numeric(count)) %>% group_by(type)

for (i in dp4plotcols) {
	plot <- ggplot(dp4dt, aes(count, fill=type)) +
		geom_density() +
		theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)) +
		scale_colour_viridis_d("magma") +
		xlim(0,1000) +
		labs(title=paste0(args[1], ": ", i))
	ggsave(paste0("plot_",i,".pdf"), plot, device = "pdf", width = 15, height = 9, path = file.path(outdir))
}

' ${FNAME}

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: all scripts finished for ${0##*/}"
