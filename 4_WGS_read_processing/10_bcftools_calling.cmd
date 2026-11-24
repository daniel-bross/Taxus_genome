#!/bin/bash -eu
#SBATCH --nodes=1				# min (and max, when only one value is listed) numbers of clusters that the job will consider (can also specifiy by name instead)
#SBATCH --ntasks=1				# max numbers of concurrent tasks
#SBATCH --cpus-per-task=1			# CPUs requested per task
#SBATCH --mem=10000MB				# RAM allocation (per array job)
#SBATCH --partition=main			# node group (small-jobs or main)
#SBATCH --array 1-1%1			 	# job array setup, with IDs 1 to 10 and 1 job running at a time
#SBATCH --job-name=10_bcftools_calling		# job name to be used for logs, etc.
#SBATCH --mail-type=BEGIN,FAIL,END		# when to send emails
#SBATCH --mail-user=daniel.bross@thuenen.de	# where to send emails
#SBATCH --output slurm_logs/%A_%x/%x_%a.out	# output log location (A = job id, x = job name, a = array id)
#SBATCH --error slurm_logs/%A_%x/%x_%a.err	# error log locationSBATCH --error slurm_logs/%A_%x/%x_%a.err       # error log location

# note for array jobs: one per scaffold

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: running ${0##*/} with the following slurm setup:"
echo "Name:		$SLURM_JOB_NAME"
echo "ID:		$SLURM_JOB_ID"
echo "Active directory: $SLURM_SUBMIT_DIR"
echo "Partition:	$SLURM_JOB_PARTITION"
echo "Tasks:		$SLURM_NTASKS"
echo "CPUs:		$SLURM_CPUS_PER_TASK"
echo "Memory:		$SLURM_MEM_PER_NODE"

module load bcftools/1.21

mkdir -p results/08_bcftools_vcf/
NAME=$(basename -s .fa data/ref/*fa)
REG=$(awk '{print $0}' data/ref/${NAME}.bed | head -n ${SLURM_ARRAY_TASK_ID} | tail -n 1 |  sed -e 's/\t/:/' -e 's/\t/-/' -e 's/:0-/:1-/g')

bcftools mpileup -O u -a AD,DP,INFO/FS,INFO/AD -f data/ref/${NAME}.fa -b data/bam_files.txt -r ${REG} | \
bcftools call --ploidy 2 -mv -O v -o results/08_bcftools_vcf/${REG}.vcf

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: all scripts finished for ${0##*/}"
