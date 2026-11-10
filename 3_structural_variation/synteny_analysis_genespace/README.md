## documentation for GENESPACE analysis

1. Install GENESPACE v1.2.3 and its dependencies according to https://github.com/jtlovell/GENESPACE
adapt paths at the top in genespace.R accordingly

2. prepare peptide and annotation files
    - For peptide files, the .aa annotation output files from BRAKER3 can be used, but the file suffix must be .fa instead. Place these in `peptide/`
    - For annotation bed files, use following awk line on annotation .gtf files from BRAKER3: `awk -v OFS="\t" '$3=="transcript"{print $1, $4, $5, $9}'`. Place these in `bed/`

3. run `genespace.R` in R 4.5.0
The final result is `riparian_plot.pdf`