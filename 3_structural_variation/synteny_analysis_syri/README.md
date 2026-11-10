# Syteny analysis of four Taxus baccata assemblies

### Preprocess FASTA files to use the same names for homologous chromosomes (expected by SyRI) (seqtk)
```
mkdir -p results/filtered_assemblies
ASM=('data/vpTaxBacc_B23-6_hap1.fa.gz' 'data/vpTaxBacc_B23-6_hap2.fa.gz' 'data/vpTaxBacc_B34-6_hap1.fa.gz' 'data/vpTaxBacc_B34-6_hap2.fa.gz')
for i in "${ASM[@]}"; do
    seq 12 | xargs -P1 -I {} "echo" "$(gzip -cd $i | head -n 1 | grep -o 'B[23][34]6-h[12]-'){}" | seqtk subseq $i - | seqtk rename - chr_ > results/filtered_assemblies/$(basename -s .fa.gz $i)_filtered.fa
done
```

### Perform whole-genome-alignment for each combination of assemblies (minimap2)
`01_prep_wga.cmd` builds minimizer indices
`02_wga.cmd` performs the whole genome alignment for each combination

### Run SyRi for every assembly
`03_syri.cmd` performs variant calling for structural variants for each combination
The reports are stored in `results/syri/`

## Plot SyRI results

### Prepare plotsr annotation files (pyfaidx)
- chromosome sizes for each assembly
```
ls results/filtered_assemblies/*_filtered.fa | parallel "faidx -i chromsizes {} > $(basename -s .fa {}).cl"
```
- data/genomes.txt (https://github.com/schneebergerlab/plotsr/blob/master/example/genomes.txt)
- data/base.cfg (https://github.com/schneebergerlab/plotsr/blob/master/example/base.cfg)
- data/tracks.txt (https://github.com/schneebergerlab/plotsr/blob/master/example/tracks.txt)
- data/markers.bed (https://github.com/schneebergerlab/plotsr?tab=readme-ov-file#visualising-markers)

```
cat data/vpTaxBacc_B*_gaps.bed | sed -e 's/B236/Tb_female/g; s/B346/Tb_male/g' | awk -v OFS="\t" '{chr = $1; sub(/^.*-h[12]-/,"chr_",$1); sub(/-[0-9]+$/,"",chr); print $1, $2, $3, chr, "mt:v;mc:black;ms:3"}' > data/assembly_gaps.bed
```

### Generate plot of certain SyRi results with plotsr
`04_plotsr.cmd` generates a plot in `results/plotsr`

## Other analysis steps
1. Generate tables with all SR regions, using only the SRs that are getting plotted according to the source code (https://github.com/schneebergerlab/plotsr/blob/master/plotsr/scripts/func.py)
```
mkdir -p results/summary/
awk -v OFS="\t" '
    ($11 !~ /SYN/ && $11 !~ /AL$/) {
    query = substr(FILENAME, 24,10); sub("-","",query); sub("_hap", "-h", query);
    ref = substr(FILENAME, 57,10); sub("-","",ref); sub("_hap","-h",ref)
    sub(/chr_/,"",$1)
    sub(/chr_/,"",$6)
    print ref "-" $1, $2, $3, query "-" $6, $7, $8,  $11, $12
}' results/syri/*.out > results/summary/combined_SVs.txt
```

2. Generate a list of large SVs that may be interesting for further analysis
```
awk -v OFS="\t" '($3 - $2) > 10000000{print $1, $2, $3, $4, $5, $6, $7, $3 - $2}' results/summary/combined_SVs.txt | sort -r -g -k8,8 > results/summary/large_SVs.bed
```
The top 3 largest SVs can be filtered out manually and stored in `results/summary/top3_largest_SVs.bed`

3. Get proportion of syntenic regions
For each haplotype, check the SyRi output of each comparison (i.e., 3 per haplotype) for syntenic blocks against the same chromosome. Then, divide the combined length of syntenic regions by the total genome size
```
mkdir -p results/syntenic_regions
for i in vpTaxBacc_B23-6_hap1 vpTaxBacc_B23-6_hap2 vpTaxBacc_B34-6_hap1 vpTaxBacc_B34-6_hap2; do
    LEN=$(awk '{sum += $2} END{print sum}' data/${i}.cl)
    FILES=$(ls results/syri/*vs_${i}_filtered_syri.summary)
    parallel -k 'awk -F "\t" -v OFS="\t" -v QUE=$(echo {} | cut -d _ -f 1-3 | cut -d / -f 3) "\$1 ~ /^Syntenic/{print QUE, \$3, \$3 / {2}}" {1} ' ::: $FILES ::: $LEN > results/syntenic_regions/${i}.tsv
done
```
