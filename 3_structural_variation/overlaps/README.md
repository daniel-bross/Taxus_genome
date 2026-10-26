# Generate distribution statistics of SVs in genomic features in Taxus genome assemblies

### 0. prepare `data/` directory
- complete genome BED file (including unlocalized scaffolds)
- SyRI output summary file (`combined_SVs.txt`)
- structural annotation GTFs

### 1. Prepare BED files of SVs and gneomic freatures (bedtools/2.31.1)
- SVs: SNPs, short SVs, large SVs
- genomic features: exon, intron, promotor (up to 5kbp upstream), intergenic (the rest)

run `01_prep_intervals.cmd`

### 2. get overlap coordinates (bedtools/2.31.1)

run `02_find_overlaps.cmd`

Note that the area calculation can report multiple lines for the same genomic feature, so the overlaps file may have more total lines than the underlying feature file

### 3. Calculate count and area stats (R/4.5.0)

run `03_get_overlap_stats.cmd`

### Reviewer Qeustion: what fraction of the assembly is affected by a particular SV type?
```
parallel '
asm={1}
sv={2}
size=$(awk "{sum += \$2} END{print sum}" results/genome_sizes/${asm}.gs)
sum=$(awk "{sum += \$3 - \$2} END{print sum}" results/structural_variants/${asm}_${sv}.bed)
ratio=$(bc -l <<< "$sum / $size")
echo $asm $sv $ratio
' ::: "vpTaxBacc_B23-6_hap1" "vpTaxBacc_B23-6_hap2" "vpTaxBacc_B34-6_hap1" "vpTaxBacc_B34-6_hap2" ::: "large_svs" "small_svs" "snps" 
```
- vpTaxBacc_B23-6_hap1 large_svs .29833672364719543531
- vpTaxBacc_B34-6_hap1 large_svs .27829609367195714468
- vpTaxBacc_B23-6_hap2 large_svs .30247287299450256144
- vpTaxBacc_B34-6_hap2 large_svs .30748049433172604067
- vpTaxBacc_B23-6_hap2 small_svs .00153704886102369888
- vpTaxBacc_B34-6_hap1 small_svs .00158019366390384185
- vpTaxBacc_B23-6_hap1 small_svs .00161045382723322693
- vpTaxBacc_B34-6_hap2 small_svs .00166172925691953648
- vpTaxBacc_B23-6_hap2 snps .01052316268402652836
- vpTaxBacc_B34-6_hap1 snps .01074446231478644627
- vpTaxBacc_B23-6_hap1 snps .01108874314186233951
- vpTaxBacc_B34-6_hap2 snps .01139796188345893552