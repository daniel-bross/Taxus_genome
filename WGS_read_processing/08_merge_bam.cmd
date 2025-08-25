#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem=40GB
#SBATCH --partition=main
#SBATCH --array 1-103%1
#SBATCH --job-name=merge_bam
#SBATCH --mail-type=BEGIN,FAIL,END
#SBATCH --mail-user=
#SBATCH --output slurm_logs/%A_%x/%x_%a.out
#SBATCH --error slurm_logs/%A_%x/%x_%a.err

# Arrays: one job per individual sample

cd ${SLURM_SUBMIT_DIR}

echo "Execution dir is: $SLURM_SUBMIT_DIR"
echo "Job id: " $SLURM_JOB_ID
echo "Job name: " $SLURM_JOB_NAME
echo "Job runs on: "  $SLURM_JOB_PARTITION
echo "Job # of tasks: " $SLURM_NTASKS
echo "Job mem allocation: " $SLURM_MEM_PER_NODE

bash scripts/merge_bam.sh ${SLURM_ARRAY_TASK_ID}
