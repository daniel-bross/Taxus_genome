#!/bin/bash -eu
#SBATCH --nodes=1				# min (and max, when only one value is listed) numbers of clusters that the job will consider (can also specifiy by name instead)
#SBATCH --ntasks=1				# max numbers of concurrent tasks
#SBATCH --cpus-per-task=1			# CPUs requested per task
#SBATCH --mem=50000MB				# RAM allocation (per array job)
#SBATCH --partition=main			# node group (small-jobs or main)
#SBATCH --array 1-60%60				# job array setup, with IDs 1 to 10 and 1 job running at a time
#SBATCH --job-name=02_find_overlaps		# job name to be used for logs, etc.
#SBATCH --mail-type=BEGIN,FAIL,END		# when to send emails
#SBATCH --mail-user=
#SBATCH --output slurm_logs/%A_%x/%x%a.out	# output log location (A = job id, x = job name, a = array id)
#SBATCH --error slurm_logs/%A_%x/%x%a.err	# error log location

# note for array jobs: one for each combination of haplotype X feature X SV

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: running ${0##*/} with the following slurm setup:"
echo "Name:		$SLURM_JOB_NAME"
echo "ID:		$SLURM_JOB_ID"
echo "Active directory: $SLURM_SUBMIT_DIR"
echo "Partition:	$SLURM_JOB_PARTITION"
echo "Tasks:		$SLURM_NTASKS"
echo "CPUs:		$SLURM_CPUS_PER_TASK"
echo "Memory:		$SLURM_MEM_PER_NODE"

mkdir -p results/overlaps/
module load bedtools/2.31.1  

HAPS=('vpTaxBacc_B23-6_hap1' 'vpTaxBacc_B23-6_hap2' 'vpTaxBacc_B34-6_hap1' 'vpTaxBacc_B34-6_hap2')
FEATURES=('genes' 'introns' 'exons' 'promotor' 'intergenic')
SVS=('snps' 'small_svs' 'large_svs')

i=$(( SLURM_ARRAY_TASK_ID - 1 ))
hap=${HAPS[$(( i % ${#HAPS[@]} ))]}
feat=${FEATURES[$(( (i / ${#HAPS[@]}) % ${#FEATURES[@]} ))]}
sv=${SVS[$(( i / (${#HAPS[@]} * ${#FEATURES[@]}) ))]}

bedtools intersect -sorted -g results/genome_sizes/${hap}.gs -c \
-a results/features/${hap}_${feat}.bed \
-b results/structural_variants/${hap}_${sv}.bed \
> results/overlaps/${hap}_${feat}_${sv}_overlap_count.bed

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: all scripts finished for ${0##*/}"
