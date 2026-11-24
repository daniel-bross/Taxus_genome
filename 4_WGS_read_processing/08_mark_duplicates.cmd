#!/bin/bash -eu
#SBATCH --nodes=1				# min (and max, when only one value is listed) numbers of clusters that the job will consider (can also specifiy by name instead)
#SBATCH --ntasks=1				# max numbers of concurrent tasks
#SBATCH --cpus-per-task=1			# CPUs requested per task
#SBATCH --mem=35000MB				# RAM allocation (per array job)
#SBATCH --partition=main			# node group (small-jobs or main)
#SBATCH --array 1-1%1			 	# job array setup, with IDs 1 to 10 and 1 job running at a time
#SBATCH --job-name=08_mark_duplicates		# job name to be used for logs, etc.
#SBATCH --mail-type=BEGIN,FAIL,END		# when to send emails
#SBATCH --mail-user=daniel.bross@thuenen.de	# where to send emails
#SBATCH --output slurm_logs/%A_%x/%x_%a.out	# output log location (A = job id, x = job name, a = array id)
#SBATCH --error slurm_logs/%A_%x/%x_%a.err	# error log locationSBATCH --error slurm_logs/%A_%x/%x_%a.err       # error log location

# note for array jobs: one per sample

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: running ${0##*/} with the following slurm setup:"
echo "Name:		$SLURM_JOB_NAME"
echo "ID:		$SLURM_JOB_ID"
echo "Active directory: $SLURM_SUBMIT_DIR"
echo "Partition:	$SLURM_JOB_PARTITION"
echo "Tasks:		$SLURM_NTASKS"
echo "CPUs:		$SLURM_CPUS_PER_TASK"
echo "Memory:		$SLURM_MEM_PER_NODE"

module load picard/3.3.0
module load samtools/1.21

SMPL=$(awk 'NR>1{print $1}' data/ReSeq_Meta_for_RG.txt | cut -d _ -f 1 | uniq | head -n ${SLURM_ARRAY_TASK_ID} | tail -1)
echo "Processing ${SMPL}..."

mkdir -p results/07_mark_duplicates/
java -jar /package/software/Bioinformatics/picard/3.1.0/picard.jar MarkDuplicates \
-I results/06_merge_bam/${SMPL}_merged.bam \
-O results/07_mark_duplicates/${SMPL}_MKDUP.bam \
-M results/07_mark_duplicates/${SMPL}_dup_metrics.txt -TMP_DIR results/tmp_${SMPL}/ \
--OPTICAL_DUPLICATE_PIXEL_DISTANCE 2500

samtools index -c results/07_mark_duplicates/${SMPL}_MKDUP.bam

rm -r results/tmp_${SMPL}/

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: all scripts finished for ${0##*/}"
