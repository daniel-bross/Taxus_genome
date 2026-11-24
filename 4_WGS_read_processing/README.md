# Pipeline to perform trimming, read mapping and variant calling for WGS

0. prepare `data/` directory
- gzipped fastq files with WGS reads in `data/fastq/` (.fastq.gz)
- uncompressed reference assembly in `data/ref/` (.fa)
- metadata for each fastq file in `data/ReSeq_Meta_for_RG.txt` (included in repo)
- Illumina adapters for trimming in `data/adapters.fa` (see https://github.com/usadellab/Trimmomatic/blob/main/adapters/TruSeq3-PE-2.fa)

1. `01_initqc.cmd` generates fastqc reports for each fastq file.

Results were summarized with multiqc:
```
module load multiqc/1.27.1
multiqc -f -o results/01_initial_fastqc/multiqc/ results/01_initial_fastqc/
```

2. `02_trimming.cmd` trims WGS reads with trimmomatic

3. `03_trimqc.cmd` generates fastqc reports for each trimmed fastq file.

Results were summarized with multiqc:
```
module load multiqc/1.27.1
multiqc -f -o results/03_trim_fastqc/multiqc/ results/03_trim_fastqc/
```

### The following steps were seprately performed once for each of the four haplotype assemblies.

4. `04_prep_mapping.cmd` builds a bwa2 index for the reference assembly in `data/ref`

5. `05_bwa_mapping.cmd` maps all trimmed fastq (only "surviving pairs") onto the reference

6. `06_qualimap.cmd` generated mapping QC reports for each run

Results were summarized with multiqc:
```
module load multiqc/1.27.1
multiqc -f -o results/05_qualimap/multiqc/ results/05_qualimap/
```

7. `07_merge_bam.cmd` concatenates all mapping files belonding to one sample into one .bam file

8. `08_mark_duplicates.cmd` flags duplicate reads

9. `09_prep_calling.cmd` generates an index for the assembly .fa file, writes a genome .bed file and collects the .bam file paths in a text file

10. `10_bcftools_calling.cmd` performs variant calling with BCFtools (on a per-scaffold basis for better parallelization)

11. `11_concat_vcf.cmd` concatenates the .vcf files into one

12. `12_split_variants.cmd` generates two .vcf files, one with SNPs and one with indels

13. `13_vcf_qc.cmd <input vcf>` generates overview plots of some metrics in the given vcf 

14. `14_filter_variants.cmd` filters the SNP .vcf in two ways, one for population structure analyses (PCA etc.) and one for SDR-related analyses (GWAS etc.)
