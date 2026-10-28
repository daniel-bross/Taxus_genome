## Circos plots for assemblies

0. prepare data/ directory:
- indexed FASTA files of assemblies
- RepeatMasker output tables
- SyRI output summary file
- indexed VCF files containing SNPs
- structural annotation GTFs (rename the prefix, e.g., `rename "s/fh1/vpTaxBacc_B23-6_hap1/ data/fh1.gtf"`)

1. Collect various statistics in 5 Mb sliding windows (2.5 Mb steps)
Run `01_prep_circos_data.cmd`

2. 
Run `02_plot_circos.cmd`

The final output is located in `results/plots/`