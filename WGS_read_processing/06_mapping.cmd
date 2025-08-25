#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=5
#SBATCH --mem=54GB
#SBATCH --partition=main
#SBATCH --array 1-275%1
#SBATCH --job-name=mapping
#SBATCH --mail-type=BEGIN,FAIL,END
#SBATCH --mail-user=
#SBATCH --output slurm_logs/%A_%x/%x_%a.out
#SBATCH --error slurm_logs/%A_%x/%x_%a.err

# Arrays: one job per sequencing track / read pair

cd ${SLURM_SUBMIT_DIR}

echo "Execution dir is: $SLURM_SUBMIT_DIR"
echo "Job id: " $SLURM_JOB_ID
echo "Job name: " $SLURM_JOB_NAME
echo "Job runs on: "  $SLURM_JOB_PARTITION
echo "Job # of tasks: " $SLURM_NTASKS
echo "Job mem allocation: " $SLURM_MEM_PER_NODE

bash scripts/bwa_mapping.sh ${SLURM_ARRAY_TASK_ID} ${SLURM_NTASKS}
