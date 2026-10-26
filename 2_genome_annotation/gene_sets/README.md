### Gene set analysis
This analysis identifies shared gene sequences among the four haplotypes.

## 0. Prepare tools and work environment
### 0.1 prepare a `data/` subdirectory that includes:
- a genome FASTA file for each haplotye (vpTaxBacc_B23-6_hap1.fa etc.)
- a structural genome annotation GTF file (output of the BRAKER3 annotation) for each haplotype (vpTaxBacc_B23-6_hap1_tsebra_combined_renamed.gtf etc.)
### 0.2 prepare a conda environment that includes:
- `bioconda::liftoff==1.6.3` (if the env name is not "liftoff", adapt the name in `01_liftoff.cmd`)

## 1. Genome annotation liftover
run `01_liftoff.cmd`
run `02_upset_plot.cmd`

the final output is located in `results/plots/`