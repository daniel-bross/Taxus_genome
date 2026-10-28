# Filtering of the combined HiC contact map cooler into haplotype-specific coolers to generate new contact map figures

1. get chromsize info
```
cooler dump -t chroms vpTaxBacc.dups.cool | grep "B236" > B236.chroms
cooler dump -t chroms vpTaxBacc.dups.cool | grep "B346" > B346.chroms
```

2. filter cooler
```
RESOLUTION=$(cooler info vpTaxBacc.dups.cool | grep bin-size | awk '{print $2}' | tr -d ",")

# individuals
cooler dump -t pixels --join vpTaxBacc.dups.cool | awk '$1 ~ /B236/ && $4 ~ /B236/' | cooler load -f bg2 B236.chroms:$RESOLUTION - B236.cool
cooler dump -t pixels --join vpTaxBacc.dups.cool | awk '$1 ~ /B346/ && $4 ~ /B346/' | cooler load -f bg2 B346.chroms:$RESOLUTION - B346.cool
```

3. rebalance coolers
```
for i in B236 B346; do
    cooler balance $i.cool
done
```

4. zoomify coolers
```
for i in B236 B346; do
    cooler zoomify --resolutions 50000,100000,1000000,2000000 $i.cool
done
```

5. plot with R/4.5.0
```
library(HiContacts)
library(ggplot2)

for (i in c("B236","B346")) {
    hic <- import(paste0(i,".mcool"), resolution=2000000)
    plot <- plotMatrix(hic, dpi = 600, chrom_lines = FALSE, show_grid = TRUE)
    ggsave(paste0(i,"_hic_contacts_2000000.png"), plot)
}

```
