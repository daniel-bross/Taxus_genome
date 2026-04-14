# Population structure analysis
This directory contains the scripts used for population structure analysis

The scripts rely on [slurm](https://slurm.schedmd.com/overview.html). The `SBATCH` parameters should be adapted by the user depending on the available resources. If `slurm` is not available, diretly use the scripts inside `scripts/`
Note: The bioinformatics software used in the scripts is loaded via Lmod. Depending on your setup, you may need to change the scripts.

The software used in this analysis is
- plink 1.90b7
- R 4.5.0

Before executing the scripts in the order indicated by the script names, it is necessarry to complete the `data/` directory with the following items:
- a directory that contains a  VCF file that is the subject of the analysis, and its csi index. The directory name should be used in `config.cfg`

In addtition, the `config.cfg` text file needs to be completed

The final output is located in `results/<filter>/` and consists of multiple files starting with `<filter>_filtered_pruned_pca`.
