#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem=5GB
#SBATCH --array=1-50%10
#SBATCH --partition=main
#SBATCH --job-name=04_coverage_sigtest
#SBATCH --mail-type=BEGIN,FAIL,END
#SBATCH --mail-user=
#SBATCH --output slurm_logs/%A_%x/%x%a.out
#SBATCH --error slurm_logs/%A_%x/%x%a.err

# Arrays: Number of jobs according should be the same as in scripts/sigtest.R

echo "Execution dir is: $SLURM_SUBMIT_DIR"
echo "Job id: " $SLURM_JOB_ID
echo "Job name: " $SLURM_JOB_NAME
echo "Job runs on: "  $SLURM_JOB_PARTITION
echo "Job # of tasks: " $SLURM_NTASKS
echo "Job mem allocation: " $SLURM_MEM_PER_NODE

cd $SLURM_SUBMIT_DIR

module load R

Rscript scripts/sigtest.R ${SLURM_ARRAY_TASK_ID}
