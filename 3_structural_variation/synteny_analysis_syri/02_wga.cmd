#!/bin/bash -eu
#SBATCH --nodes=1				# min (and max, when only one value is listed) numbers of clusters that the job will consider (can also specifiy by name instead)
#SBATCH --ntasks=1				# max numbers of concurrent tasks
#SBATCH --cpus-per-task=6			# CPUs requested per task
#SBATCH --mem=150000MB				# RAM allocation (per array job)
#SBATCH --partition=main			# node group (small-jobs or main)
#SBATCH --array 1-12%12				# job array setup, with IDs 1 to 10 and 1 job running at a time
#SBATCH --job-name=02_wga			# job name to be used for logs, etc.
#SBATCH --mail-type=BEGIN,FAIL,END		# when to send emails
#SBATCH --mail-user=
#SBATCH --output slurm_logs/%A_%x/%x%a.out	# output log location (A = job id, x = job name, a = array id)
#SBATCH --error slurm_logs/%A_%x/%x%a.err	# error log location

# note for array jobs: one per mapping: three per assembly * four assemblies = 12

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: running ${0##*/} with the following slurm setup:"
echo "Name:		$SLURM_JOB_NAME"
echo "ID:		$SLURM_JOB_ID"
echo "Active directory: $SLURM_SUBMIT_DIR"
echo "Partition:	$SLURM_JOB_PARTITION"
echo "Tasks:		$SLURM_NTASKS"
echo "CPUs:		$SLURM_CPUS_PER_TASK"
echo "Memory:		$SLURM_MEM_PER_NODE"

ASM=('results/mm2_indices/vpTaxBacc_B23-6_hap1_filtered.mmi' 'results/mm2_indices/vpTaxBacc_B23-6_hap2_filtered.mmi' 'results/mm2_indices/vpTaxBacc_B34-6_hap1_filtered.mmi' 'results/mm2_indices/vpTaxBacc_B34-6_hap2_filtered.mmi')
REF=${ASM[$(( ( $SLURM_ARRAY_TASK_ID - 1 ) / 3 ))]}
QUERY=${ASM[(( ( ($SLURM_ARRAY_TASK_ID % 4) + (($SLURM_ARRAY_TASK_ID - 1) / 4)) % 4  )) ]}

mkdir -p results/mappings

# load mm2plus module
ml minimap2/2.31

minimap2 -t $SLURM_CPUS_PER_TASK -c --eqx $REF results/filtered_assemblies/$(basename -s .mmi $QUERY).fa > results/mappings/ref_$(basename -s .mmi $REF)_with_query_$(basename -s .mmi $QUERY).paf

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: all scripts finished for ${0##*/}"
