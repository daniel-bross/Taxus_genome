#!/bin/bash -eu
#SBATCH --nodes=1                               # min (and max, when only one value is listed) numbers of clusters that the job will consider (can also specifiy by name instead)
#SBATCH --ntasks=1                              # max numbers of concurrent tasks
#SBATCH --cpus-per-task=1                       # CPUs requested per task
#SBATCH --mem=10000MB                          # RAM allocation (per array job)
#SBATCH --partition=main                        # node group (small-jobs or main)
#SBATCH --array 1-4%4	                        # job array setup, with IDs 1 to 10 and 1 job running at a time
#SBATCH --job-name=02_plot_circos                   # job name to be used for logs, etc.
#SBATCH --mail-type=BEGIN,FAIL,END              # when to send emails
#SBATCH --mail-user=                             # where to send emails
#SBATCH --output slurm_logs/%A_%x/%x_%a.out      # output log location (A = job id, x = job name, a = array id)
#SBATCH --error slurm_logs/%A_%x/%x_%a.err       # error log location

# note for array jobs: one per haplotype that should be plotted

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

module load  R/4.5.0

mkdir -p results/plots

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

df <- read_tsv(paste0("results/plots/",args,"_data.tsv"))
genome_bed <- df %>% select(1:3) %>% group_by(chr) %>% filter(end == max(end)) %>% mutate(start = 0) %>% unique()
gene_counts <- df %>% select(1:3, 9)
repeat_frac_c <- df %>% select(1:3, 5)
repeat_frac_g <- df %>% select(1:3, 6)
large_sv_fractions <- df %>% select(1:3, 8)
small_sv_counts <- df %>% select(1:3, 7)
snp_counts <- df %>% select(1:3, 4)

# prepare legend
lgd <- Legend(labels = c("Gene count","Copia fraction","Gypsy fraction","Large SV fraction","Small SV count","SNP count"), legend_gp = gpar(fill = colors), title_position = "topleft", title = "Tracks")

# draw circos plot
pdf(paste0("results/plots/",args,"_circos.pdf"), width=7, height=7, compress=FALSE)
circos.clear()
circos.par(start.degree=90, track.height=0.10)
circos.genomicInitialize(genome_bed, sector.names = genome_bed$chr %>% str_replace("B236", "Tb_female") %>% str_replace("B346", "Tb_male"), labels.cex = 0.7*par("cex"))
circos.genomicTrackPlotRegion(gene_counts, ylim=c(0,max(gene_counts$gene_count)), panel.fun = function(region, value, ...) {circos.genomicLines(region, value, col=colors[1], border=colors[1], area=TRUE, baseline = get.cell.meta.data("cell.ylim")[1], ...)})
circos.genomicTrackPlotRegion(repeat_frac_c, ylim=c(0,1), panel.fun = function(region, value, ...) {circos.genomicLines(region, value, col=colors[2], border=colors[2], area=TRUE, baseline = get.cell.meta.data("cell.ylim")[1], ...)}) 
circos.genomicTrackPlotRegion(repeat_frac_g, ylim=c(0,1), panel.fun = function(region, value, ...) {circos.genomicLines(region, value, col=colors[3], border=colors[3], area=TRUE, baseline = get.cell.meta.data("cell.ylim")[1], ...)})
circos.genomicTrackPlotRegion(large_sv_fractions, ylim=c(0,max(large_sv_fractions$large_sv_frac)), panel.fun = function(region, value, ...) {circos.genomicLines(region, value, col=colors[4], border=colors[4], area=TRUE, baseline = get.cell.meta.data("cell.ylim")[1], ...)})
circos.genomicTrackPlotRegion(small_sv_counts, ylim=c(0,max(small_sv_counts$small_sv_count)), panel.fun = function(region, value, ...) {circos.genomicLines(region, value, col=colors[5], border=colors[5], area=TRUE, baseline = get.cell.meta.data("cell.ylim")[1], ...)})
circos.genomicTrackPlotRegion(snp_counts,ylim=c(0,max(snp_counts$snp_count)), panel.fun = function(region, value, ...) {circos.genomicLines(region, value, col=colors[6], border=colors[6], area=TRUE, baseline = get.cell.meta.data("cell.ylim")[1], ...)})
draw(lgd, x = unit(4, "mm"), y = unit(4, "mm"), just = c("left", "bottom"))

dev.off()

' $HAP

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: all scripts finished for ${0##*/}"