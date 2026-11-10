#!/bin/bash -eu
#SBATCH --nodes=1				# min (and max, when only one value is listed) numbers of clusters that the job will consider (can also specifiy by name instead)
#SBATCH --ntasks=1				# max numbers of concurrent tasks
#SBATCH --cpus-per-task=5			# CPUs requested per task
#SBATCH --mem=5000MB				# RAM allocation (per array job)
#SBATCH --partition=main			# node group (small-jobs or main)
#SBATCH --job-name=03_plotsr			# job name to be used for logs, etc.
#SBATCH --mail-type=BEGIN,FAIL,END		# when to send emails
#SBATCH --mail-user=
#SBATCH --output slurm_logs/%A_%x/%x%a.out	# output log location (A = job id, x = job name, a = array id)
#SBATCH --error slurm_logs/%A_%x/%x%a.err	# error log location

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: running ${0##*/} with the following slurm setup:"
echo "Name:		$SLURM_JOB_NAME"
echo "ID:		$SLURM_JOB_ID"
echo "Active directory: $SLURM_SUBMIT_DIR"
echo "Partition:	$SLURM_JOB_PARTITION"
echo "Tasks:		$SLURM_NTASKS"
echo "CPUs:		$SLURM_CPUS_PER_TASK"
echo "Memory:		$SLURM_MEM_PER_NODE"

module load plotsr/1.1.5

mkdir -p results/plotsr

plotsr --sr results/syri/vpTaxBacc_B23-6_hap2_filtered_vs_vpTaxBacc_B23-6_hap1_filtered_syri.out --sr results/syri/vpTaxBacc_B34-6_hap1_filtered_vs_vpTaxBacc_B23-6_hap2_filtered_syri.out --sr results/syri/vpTaxBacc_B34-6_hap2_filtered_vs_vpTaxBacc_B34-6_hap1_filtered_syri.out \
--genomes data/genomes.txt --cfg data/base.cfg \
-o results/plotsr/fig1_plot.pdf --lf results/plotsr/fig1_plot.log \
-S 0.5 -W 7 -H 10 -f 8 \
--chr chr_1 --chr chr_2 --chr chr_3 --chr chr_4 --chr chr_5 --chr chr_6 --chr chr_7 --chr chr_8 --chr chr_9 --chr chr_10 --chr chr_11 --chr chr_12

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: all scripts finished for ${0##*/}"
