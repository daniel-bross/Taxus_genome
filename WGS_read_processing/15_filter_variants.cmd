#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=5
#SBATCH --mem=30GB
#SBATCH --partition=main
#SBATCH --job-name=filter_variants
#SBATCH --mail-type=BEGIN,FAIL,END
#SBATCH --mail-user=
#SBATCH --output slurm_logs/%A_%x/std.out
#SBATCH --error slurm_logs/%A_%x/std.err

cd ${SLURM_SUBMIT_DIR}

echo "Execution dir is: $SLURM_SUBMIT_DIR"
echo "Job id: " $SLURM_JOB_ID
echo "Job name: " $SLURM_JOB_NAME
echo "Job runs on: "  $SLURM_JOB_PARTITION
echo "Job # of tasks: " $SLURM_NTASKS
echo "Job mem allocation: " $SLURM_MEM_PER_NODE

FILTER=$1
INPUT=$2

echo "Input file:	" $2
echo "Filter script:	" $1
printf "\n"

bash $1 $2 ${SLURM_NTASKS}
