#!/bin/bash -eu
#SBATCH --nodes=1				# min (and max, when only one value is listed) numbers of clusters that the job will consider (can also specifiy by name instead)
#SBATCH --ntasks=1				# max numbers of concurrent tasks
#SBATCH --cpus-per-task=6			# CPUs requested per task
#SBATCH --mem=60000MB				# RAM allocation (per array job)
#SBATCH --partition=main			# node group (small-jobs or main)
#SBATCH --array 1-4%4				# job array setup, with IDs 1 to 10 and 1 job running at a time
#SBATCH --job-name=01_prep_wga			# job name to be used for logs, etc.
#SBATCH --mail-type=BEGIN,FAIL,END		# when to send emails
#SBATCH --mail-user=
#SBATCH --output slurm_logs/%A_%x/%x%a.out	# output log location (A = job id, x = job name, a = array id)
#SBATCH --error slurm_logs/%A_%x/%x%a.err	# error log location

# note for array jobs: one per assembly

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: running ${0##*/} with the following slurm setup:"
echo "Name:		$SLURM_JOB_NAME"
echo "ID:		$SLURM_JOB_ID"
echo "Active directory: $SLURM_SUBMIT_DIR"
echo "Partition:	$SLURM_JOB_PARTITION"
echo "Tasks:		$SLURM_NTASKS"
echo "CPUs:		$SLURM_CPUS_PER_TASK"
echo "Memory:		$SLURM_MEM_PER_NODE"

ASM=('results/filtered_assemblies/vpTaxBacc_B23-6_hap1_filtered.fa' 'results/filtered_assemblies/vpTaxBacc_B23-6_hap2_filtered.fa' 'results/filtered_assemblies/vpTaxBacc_B34-6_hap1_filtered.fa' 'results/filtered_assemblies/vpTaxBacc_B34-6_hap2_filtered.fa')
REF=${ASM[$(($SLURM_ARRAY_TASK_ID - 1))]}

mkdir -p results/mm2_indices/

# load mm2plus module
ml minimap2/2.31

minimap2 -t $SLURM_CPUS_PER_TASK -x asm5 -k 28 -I 11G -d results/mm2_indices/$(basename -s .fa $REF).mmi $REF

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: all scripts finished for ${0##*/}"
