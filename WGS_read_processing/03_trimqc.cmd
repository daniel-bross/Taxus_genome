#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem=5GB
#SBATCH --partition=main
#SBATCH --array 1-550%1
#SBATCH --job-name=trim_qc
#SBATCH --mail-type=BEGIN,FAIL,END
#SBATCH --mail-user=
#SBATCH --output slurm_logs/%A_%x/%x_%a.out
#SBATCH --error slurm_logs/%A_%x/%x_%a.err

# Arrays: one job per .fastq file (trimming.sh produced files of unpaired reads, so it's double the original number of files)

cd ${SLURM_SUBMIT_DIR}

echo "Execution dir is: $SLURM_SUBMIT_DIR"
echo "Job id: " $SLURM_JOB_ID
echo "Job name: " $SLURM_JOB_NAME
echo "Job runs on: "  $SLURM_JOB_PARTITION
echo "Job # of tasks: " $SLURM_NTASKS
echo "Job mem allocation: " $SLURM_MEM_PER_NODE

bash scripts/fastqc.sh --trim ${SLURM_ARRAY_TASK_ID} ${SLURM_NPROCS}
