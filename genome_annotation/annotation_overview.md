# Genome annotations
The four assemblies (B236-h1, B236-h2, B346-h1, B346-h2) were annotated independently of each other by the following steps:

## 0. Prepare tools and work environment
### 0.1. Containers
The container images were prepared using [Singluarity CE](https://sylabs.io/singularity/), e.g.: `singularity build braker3_v3.0.7.6.sif docker://teambraker/braker3:v3.0.7.6`. The absolute paths to the images are set in `config.cfg` and used by the scripts. The following containers were used for the annotations:
- [BRAKER3 v3.0.7.6](https://hub.docker.com/layers/teambraker/braker3/v3.0.7.6/images/sha256-5f8b3c508a9fe1bbc2e9a74dcc013eeed82f91dd5945adca7823514d9c8aecf8): `docker://teambraker/braker3:v3.0.7.6`
- [BRAKER3 isoseq](https://hub.docker.com/layers/teambraker/braker3/isoseq/images/sha256-e2d0bd1f4cc721198136cec50177076263e3f502b9ea64d728813e32c80bbeb8): `docker://teambraker/braker3:isoseq`
- [BUSCO v5.8.2_cv1](https://hub.docker.com/layers/ezlabgva/busco/v5.8.2_cv1/images/sha256-b5d9debf1cda84c9f388a36e14a8553a7750ec2c2efaca41778e431600be1629): `docker://ezlabgva/busco:v5.8.2_cv1`
- [TETools v1.90](https://hub.docker.com/layers/dfam/tetools/1.90/images/sha256-b41c16b0eed6b6946dc013cf27bdc792e27e07ee1824537b050dbe8005c16c02): `docker://dfam/tetools:1.90`
- [EnTAP v2.2.0](https://hub.docker.com/layers/plantgenomics/entap/2.2.0/images/sha256-e73fdd711f769f20c5a89913c50812bddb226c0f6daff0553b680c8001a7b834): `plantgenomics/entap:2.2.0`

### 0.2. Conda environment
The conda location and environment name can be set in config.cfg. The following packages were used:
- `bioconda::samtools==1.10`
- `bioconda::gaas==1.2.0`
- `bioconda::bedtools==2.31.1`
- `bioconda::ucsc-bedtogenepred==469`
- `bioconda::ucsc-genepredtogtf==469`

### 0.3. Directory structure
The scripts assume the presence of a `data/` subdirectory containing the following items:
- the target assembly as an uncompressed FASTA file (file suffix `.fa` required)
- a subdirectory `rnaseq-sr/` containing all short read RNA files (FASTQ format) to be used in the annotation
- a subdirectory `isoseq/` containing all assembled isoseq RNA files (FASTA format) to be used in the annotation
- a FASTA file containing protein evidence to be used in the annotation

TODO: ADD INFO ABOUT WHERE TO FIND THOSE
TODO: ADD PROTEIN FILE PROCESSING INFO (sanitizing)
1. download protein evidence FASTA files:
- [Orthodb Viridiplantae v12](https://bioinf.uni-greifswald.de/bioinf/partitioned_odb12/)
- [a filtered Uniprot dataset](https://www.uniprot.org/uniprotkb?query=%28taxonomy_id%3A25628%29+AND+%28existence%3A3%29)
Combine the (unzipped) files with `cat` into one "database".
2. Sanitize the protein input file by changing whitespaces and "|" to underscores, e.g. `sed -i -E 's/\s|\|/_/g' protdb.fa > protdb_clean.fa`

## 1. Preprocessing
1. run `scripts/sanitize.sh`

## 2. Repeatmasking
1. run `scripts/rmo_database.sh` to generate a database for RepeatModeler
2. run `scripts/rmo_model.sh` to generate a repeat library
3. run `scripts/rma_mask.sh` to mask repeats in the genome assembly
4. run `scripts/trf.sh` to further mask repeats with Tandem Repeat Finder

## 3. BRAKER
### 3.1. prepare braker input
1. run `ls data/rnaseq-sr/ | sed 's/_R*.\.fastq.*$//' | uniq | tr '\n' ',' | sed 's/.$//' > data/rna_id_list.txt`
2. map isoseq data to genome with `scripts/minimap2_mapping.sh`
3. run `ls results/minimap2/*.bam | tr '\n' ',' | sed 's/.$//' > data/rna_isoseq_bam_list.txt`

### 3.2. BRAKER
1. run `scripts/braker-sr.sh` 
2. run `scripts/braker-lr.sh`
3. run `scripts/tsebra.sh` to combine the output GTFs of the two runs, yielding the final gene set.

The final structural annotaion is stored in `results/tsebra/`. Note that some BRAKER3 steps involve a small degree of randomness, so small deviations compared to the published annotation are to be expected.

### 3.3. generate annotation statistics
- run `scripts/summarize_braker_output.sh braker-sr`
- generate complementary statistics with `awk -f get_gtf_stats.awk <gtf_file>`


## 4. EnTAP
1. EnTAP setup
2. run `scripts/entap.sh`
the final functional annotation is located in `results/entap_annotation/final_results/annotated_without_contam.tsv`

