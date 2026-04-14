# WGS read processing
This directory contains the scripts used for mapping and variant calling.

The scripts rely on [slurm](https://slurm.schedmd.com/overview.html). The `SBATCH` parameters should be adapted by the user depending on the available resources.
Note: The bioinformatics software used in the scripts is loaded via Lmod. Depending on your setup, you may need to change the scripts.

The software used in this analysis is
- Trimmomatic 0.39
- Fastqc 0.12.1
- Multiqc 1.27.1
- bwa-mem2 2.2.1
- Qualimap 2.3
- SAMtools 2.12
- MarkDuplicates 3.1.0
- bcftools 1.21
- ggplot2 4.0.0
- R 4.5.0

Before executing the scripts in order, it is necessarry to set up a `data/` subdirectory that contains the following items:
- a `ref/` directory that contains an uncompressed reference genome FASTA file
- a `fastq/` directory that contains all raw read files to be analyzed as gzipped FASTQ files. The files are expected to end with `fastq.gz`
- a `seq/` directory that contains a file with adapter sequences called `adapters.fa`, downloaded from https://github.com/usadellab/Trimmomatic/blob/main/adapters/TruSeq3-PE-2.fa
- a file with readgroup metadata for each input file (since all input files were seperate sequencing runs in our case), see `config.cfg`
