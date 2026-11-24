#!/bin/bash -eu
#SBATCH --nodes=1				# min (and max, when only one value is listed) numbers of clusters that the job will consider (can also specifiy by name instead)
#SBATCH --ntasks=1				# max numbers of concurrent tasks
#SBATCH --cpus-per-task=3			# CPUs requested per task
#SBATCH --mem=3000MB				# RAM allocation (per array job)
#SBATCH --partition=main			# node group (small-jobs or main)
#SBATCH --array 1-2%2			 	# job array setup, with IDs 1 to 10 and 1 job running at a time
#SBATCH --job-name=02_trimming		# job name to be used for logs, etc.
#SBATCH --mail-type=BEGIN,FAIL,END		# when to send emails
#SBATCH --mail-user=daniel.bross@thuenen.de	# where to send emails
#SBATCH --output slurm_logs/%A_%x/%x_%a.out	# output log location (A = job id, x = job name, a = array id)
#SBATCH --error slurm_logs/%A_%x/%x_%a.err	# error log locationSBATCH --error slurm_logs/%A_%x/%x_%a.err       # error log location

# note for array jobs: one job per run

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: running ${0##*/} with the following slurm setup:"
echo "Name:		$SLURM_JOB_NAME"
echo "ID:		$SLURM_JOB_ID"
echo "Active directory: $SLURM_SUBMIT_DIR"
echo "Partition:	$SLURM_JOB_PARTITION"
echo "Tasks:		$SLURM_NTASKS"
echo "CPUs:		$SLURM_CPUS_PER_TASK"
echo "Memory:		$SLURM_MEM_PER_NODE"

module load trimmomatic/0.39 

mkdir -p results/02_trim/
RUN=$(awk 'NR>1{print $1}' data/ReSeq_Meta_for_RG.txt | cut -d '_' -f1,2 | uniq | head -n ${SLURM_ARRAY_TASK_ID} | tail -1)
echo "Processing ${RUN}..."

java -jar /package/software/Bioinformatics/trimmomatic/0.39/bin/trimmomatic-0.39.jar PE \
	-threads ${SLURM_CPUS_PER_TASK} -phred33 \
	data/fastq/${RUN}_R1.fastq.gz data/fastq/${RUN}_R2.fastq.gz \
	results/02_trim/${RUN}_R1.fastq.gz results/02_trim/${RUN}_R1U.fastq.gz \
	results/02_trim/${RUN}_R2.fastq.gz results/02_trim/${RUN}_R2U.fastq.gz \
	ILLUMINACLIP:data/adapters.fa:2:30:10:1:true SLIDINGWINDOW:4:15 MINLEN:60

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: all scripts finished for ${0##*/}"
