#!/bin/bash -eu
#SBATCH --nodes=1				# min (and max, when only one value is listed) numbers of clusters that the job will consider (can also specifiy by name instead)
#SBATCH --ntasks=1				# max numbers of concurrent tasks
#SBATCH --cpus-per-task=$SLURM_CPUS_PER_TASK			# CPUs requested per task
#SBATCH --mem=40000MB				# RAM allocation (per array job)
#SBATCH --partition=main			# node group (small-jobs or main)
#SBATCH --array 1-1%1				# job array setup, with IDs 1 to $SLURM_CPUS_PER_TASK and 1 job running at a time
#SBATCH --job-name=liftoff		# job name to be used for logs, etc.
#SBATCH --mail-type=BEGIN,FAIL,END		# when to send emails
#SBATCH --mail-user=
#SBATCH --output slurm_logs/%A_%x/%x%a.out	# output log location (A = job id, x = job name, a = array id)
#SBATCH --error slurm_logs/%A_%x/%x%a.err	# error log location

module load mamba
mamba activate liftoff

mkdir -p results/liftover/

liftoff -g data/vpTaxBacc_B23-6_hap1_tsebra_combined_renamed.gtf -o results/liftover/f1_vs_f2.gff -p $SLURM_CPUS_PER_TASK -u results/liftover/unmapped_features.f1.vs.f2.txt -exclude_partial -dir f1_vs_f2.0.5 data/vpTaxBacc_B23-6_hap2.fa data/vpTaxBacc_B23-6_hap1.fa
liftoff -g data/vpTaxBacc_B23-6_hap1_tsebra_combined_renamed.gtf -o results/liftover/f1_vs_m1.gff -p $SLURM_CPUS_PER_TASK -u results/liftover/unmapped_features.f1.vs.m1.txt -exclude_partial -dir f1_vs_m1.0.5 data/vpTaxBacc_B34-6_hap1.fa data/vpTaxBacc_B23-6_hap1.fa
liftoff -g data/vpTaxBacc_B23-6_hap1_tsebra_combined_renamed.gtf -o results/liftover/f1_vs_m2.gff -p $SLURM_CPUS_PER_TASK -u results/liftover/unmapped_features.f1.vs.m2.txt -exclude_partial -dir f1_vs_m2.0.5 data/vpTaxBacc_B34-6_hap2.fa data/vpTaxBacc_B23-6_hap1.fa

liftoff -g data/vpTaxBacc_B23-6_hap2_tsebra_combined_renamed.gtf -o results/liftover/f2_vs_f1.gff -p $SLURM_CPUS_PER_TASK -u results/liftover/unmapped_features.f2.vs.f1.txt -exclude_partial -dir f2_vs_f1.0.5 data/vpTaxBacc_B23-6_hap1.fa data/vpTaxBacc_B23-6_hap2.fa
liftoff -g data/vpTaxBacc_B23-6_hap2_tsebra_combined_renamed.gtf -o results/liftover/f2_vs_m1.gff -p $SLURM_CPUS_PER_TASK -u results/liftover/unmapped_features.f2.vs.m1.txt -exclude_partial -dir f2_vs_m1.0.5 data/vpTaxBacc_B34-6_hap1.fa data/vpTaxBacc_B23-6_hap2.fa
liftoff -g data/vpTaxBacc_B23-6_hap2_tsebra_combined_renamed.gtf -o results/liftover/f2_vs_m2.gff -p $SLURM_CPUS_PER_TASK -u results/liftover/unmapped_features.f2.vs.m2.txt -exclude_partial -dir f2_vs_m2.0.5 data/vpTaxBacc_B34-6_hap2.fa data/vpTaxBacc_B23-6_hap2.fa

liftoff -g data/vpTaxBacc_B34-6_hap1_tsebra_combined_renamed.gtf -o results/liftover/m1_vs_f1.gff -p $SLURM_CPUS_PER_TASK -u results/liftover/unmapped_features.m1.vs.f1.txt -exclude_partial -dir m1_vs_f1.0.5 data/vpTaxBacc_B23-6_hap1.fa data/vpTaxBacc_B34-6_hap1.fa
liftoff -g data/vpTaxBacc_B34-6_hap1_tsebra_combined_renamed.gtf -o results/liftover/m1_vs_f2.gff -p $SLURM_CPUS_PER_TASK -u results/liftover/unmapped_features.m1.vs.f2.txt -exclude_partial -dir m1_vs_f2.0.5 data/vpTaxBacc_B23-6_hap2.fa data/vpTaxBacc_B34-6_hap1.fa
liftoff -g data/vpTaxBacc_B34-6_hap1_tsebra_combined_renamed.gtf -o results/liftover/m1_vs_m2.gff -p $SLURM_CPUS_PER_TASK -u results/liftover/unmapped_features.m1.vs.m2.txt -exclude_partial -dir m1_vs_m2.0.5 data/vpTaxBacc_B34-6_hap2.fa data/vpTaxBacc_B34-6_hap1.fa

liftoff -g data/vpTaxBacc_B34-6_hap2_tsebra_combined_renamed.gtf -o results/liftover/m2_vs_f1.gff -p $SLURM_CPUS_PER_TASK -u results/liftover/unmapped_features.m2.vs.f1.txt -exclude_partial -dir m2_vs_f1.0.5 data/vpTaxBacc_B23-6_hap1.fa data/vpTaxBacc_B34-6_hap2.fa
liftoff -g data/vpTaxBacc_B34-6_hap2_tsebra_combined_renamed.gtf -o results/liftover/m2_vs_f2.gff -p $SLURM_CPUS_PER_TASK -u results/liftover/unmapped_features.m2.vs.f2.txt -exclude_partial -dir m2_vs_f2.0.5 data/vpTaxBacc_B23-6_hap2.fa data/vpTaxBacc_B34-6_hap2.fa
liftoff -g data/vpTaxBacc_B34-6_hap2_tsebra_combined_renamed.gtf -o results/liftover/m2_vs_m1.gff -p $SLURM_CPUS_PER_TASK -u results/liftover/unmapped_features.m2.vs.m1.txt -exclude_partial -dir m2_vs_m1.0.5 data/vpTaxBacc_B34-6_hap1.fa data/vpTaxBacc_B34-6_hap2.fa

for i in results/liftover/*.gff; do
    name=$(basename -s .gff ${i})
    awk -F'\t' '
        /^#/ { next }
        $3 == "gene" {
        if (match($9, /gene_id "[^"]+"/)) {
        id = substr($9, RSTART + 9, RLENGTH - 10)
        print id
        }
        }
    ' "$i" | sort -u > results/sorted_${name}_mapped.genes.list.txt
done

mamba deactivate