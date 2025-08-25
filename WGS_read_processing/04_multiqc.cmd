#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem=6GB
#SBATCH --partition=main
#SBATCH --job-name=read_mqc
#SBATCH --mail-type=BEGIN,FAIL,END
#SBATCH --mail-user=
#SBATCH --output slurm_logs/%A_%x/std.out
#SBATCH --error slurm_logs/%A_%x/std.err

cd ${SLURM_SUBMIT_DIR}

# target directory, e.g. "results/03_trimqc/"
INPUT=$1

bash scripts/multiqc.sh $INPUT
