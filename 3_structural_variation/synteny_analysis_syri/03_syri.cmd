#!/bin/bash -eu
#SBATCH --nodes=1				# min (and max, when only one value is listed) numbers of clusters that the job will consider (can also specifiy by name instead)
#SBATCH --ntasks=1				# max numbers of concurrent tasks
#SBATCH --cpus-per-task=16			# CPUs requested per task
#SBATCH --mem=150000MB				# RAM allocation (per array job)
#SBATCH --partition=main			# node group (small-jobs or main)
#SBATCH --array 1-12%12				# job array setup, with IDs 1 to 10 and 1 job running at a time
#SBATCH --job-name=03_syri				# job name to be used for logs, etc.
#SBATCH --mail-type=BEGIN,FAIL,END		# when to send emails
#SBATCH --mail-user=
#SBATCH --output slurm_logs/%A_%x/%x%a.out	# output log location (A = job id, x = job name, a = array id)
#SBATCH --error slurm_logs/%A_%x/%x%a.err	# error log location

# note for array jobs: one per mapping

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: running ${0##*/} with the following slurm setup:"
echo "Name:		$SLURM_JOB_NAME"
echo "ID:		$SLURM_JOB_ID"
echo "Active directory: $SLURM_SUBMIT_DIR"
echo "Partition:	$SLURM_JOB_PARTITION"
echo "Tasks:		$SLURM_NTASKS"
echo "CPUs:		$SLURM_CPUS_PER_TASK"
echo "Memory:		$SLURM_MEM_PER_NODE"

ASM=('results/filtered_assemblies/vpTaxBacc_B23-6_hap1_filtered.fa' 'results/filtered_assemblies/vpTaxBacc_B23-6_hap2_filtered.fa' 'results/filtered_assemblies/vpTaxBacc_B34-6_hap1_filtered.fa' 'results/filtered_assemblies/vpTaxBacc_B34-6_hap2_filtered.fa')
REF=${ASM[$(( ( $SLURM_ARRAY_TASK_ID - 1 ) / 3 ))]}
QUERY=${ASM[(( ( ($SLURM_ARRAY_TASK_ID % 4) + (($SLURM_ARRAY_TASK_ID - 1) / 4)) % 4  )) ]}

module load syri/1.7.0

mkdir -p results/syri
syri -c results/mappings/ref_$(basename -s .fa $REF)_with_query_$(basename -s .fa $QUERY).paf -r $REF -q $QUERY --dir results/syri/ --prefix $(basename -s .fa ${QUERY})_vs_$(basename -s .fa ${REF})_  -k -F P

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: all scripts finished for ${0##*/}"
