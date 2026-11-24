#!/bin/bash -eu
#SBATCH --nodes=1				# min (and max, when only one value is listed) numbers of clusters that the job will consider (can also specifiy by name instead)
#SBATCH --ntasks=1				# max numbers of concurrent tasks
#SBATCH --cpus-per-task=5			# CPUs requested per task
#SBATCH --mem=10000MB				# RAM allocation (per array job)
#SBATCH --partition=main			# node group (small-jobs or main)
#SBATCH --array 1-1%1			 	# job array setup, with IDs 1 to 10 and 1 job running at a time
#SBATCH --job-name=14_filter_variants		# job name to be used for logs, etc.
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

mkdir -p results/12_filtersets/
NAME=$(basename -s .fa data/ref/*fa)

# filter for population structure (LD-pruning will be done later), once with all 103 samples and once with 100
# the awk expression corresponds to GATK's QD, setting a minimum of 5
bcftools view -m 2 -M 2 --threads ${SLURM_CPUS_PER_TASK} \
-e 'INFO/FS < 0.000001 || INFO/MQ < 40 || INFO/MQBZ < -12.5 || INFO/RPBZ < -4 || F_PASS(GT="mis") > 0.1 ' \
results/10_split_vcf/${NAME}_SNPs.vcf.gz | \
    awk '$1 ~ /^#/{print $0; next}
    {       
        d = 0
        for (i=10; i<= NF; i++) {
            if($i !~ /^0\/0/) {
                split($i,a,":")
                d += a[3]
            }
        }
        if (d == 0) {
            next
        }
        if ($6 / d >= 5) {
            print $0
        }
    }'  | bcftools view --threads ${SLURM_CPUS_PER_TASK} -o results/12_filtersets/${NAME}_103s_popstruct.vcf.gz -O z -W -

bcftools view --threads ${SLURM_CPUS_PER_TASK} -s "^S142233,S142242,S142260" -o results/12_filtersets/${NAME}_100s_popstruct.vcf.gz -O z -W results/12_filtersets/${NAME}_103s_popstruct.vcf.gz

# filter for analyses
bcftools view -s "^S142233,S142242,S142260" -m 2 -M 2 -O z -W --threads ${SLURM_CPUS_PER_TASK} \
-e 'MAF < 0.1 | (COUNT(GT="RA")+COUNT(GT="mis"))=N_SAMPLES | (COUNT(GT="AA")+COUNT(GT="mis"))=N_SAMPLES | (COUNT(GT="RR")+COUNT(GT="mis"))=N_SAMPLES | F_PASS(GT="mis") > 0.1 | MEDIAN(FORMAT/AD[GT]) < 4 | MEDIAN(FORMAT/AD[GT]) > 64' \
-o results/12_filtersets/${NAME}_100s_sdr.vcf.gz results/10_split_vcf/${NAME}_SNPs.vcf.gz

printf '[%(%Y-%m-%d %H:%M:%S)T] ' && echo "INFO: all scripts finished for ${0##*/}"
