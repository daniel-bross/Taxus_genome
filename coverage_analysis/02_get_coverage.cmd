#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem=1GB
#SBATCH --array 1-100%10
#SBATCH --partition=main
#SBATCH --job-name=02_get_coverage
#SBATCH --mail-type=BEGIN,FAIL,END
#SBATCH --mail-user=
#SBATCH --output slurm_logs/%A_%x/%x%a.out
#SBATCH --error slurm_logs/%A_%x/%x%a.err

# Number of arrays: Equal to number of files in the previous output directory under results/01_winbed/

echo "Execution dir is: $SLURM_SUBMIT_DIR"
echo "Job id: " $SLURM_JOB_ID
echo "Job name: " $SLURM_JOB_NAME
echo "Job runs on: "  $SLURM_JOB_PARTITION
echo "Job # of tasks: " $SLURM_NTASKS
echo "Job mem allocation: " $SLURM_MEM_PER_NODE

cd $SLURM_SUBMIT_DIR

bash scripts/get_coverage.sh ${SLURM_ARRAY_TASK_ID} 
