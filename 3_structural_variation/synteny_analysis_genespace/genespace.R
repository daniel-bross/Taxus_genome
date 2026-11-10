#!/usr/bin/env Rscript

library(GENESPACE)

# paths
genomeRepo <- "~/path/to/store/rawGenomes"
wdpath <- "/path/to/your/workingDirectory"
mcscanxpath <- "/path/to/MCScanX/"

gpar <- init_genespace(
  wdpath = wd, 
  path2mcscanx = mcscanxpath)
out <- run_genespace(gsParam = gpar) 

# write filtered GENESPACE output of syntenic regions from comparison with SyRI
dt <- tibble()
for (i in c("vpTaxBacc_B23-6_hap1","vpTaxBacc_B23-6_hap2","vpTaxBacc_B34-6_hap1","vpTaxBacc_B34-6_hap2")) {
	other_hap <- case_when(
		i == "vpTaxBacc_B23-6_hap1" ~ "vpTaxBacc_B23-6_hap2",
		i == "vpTaxBacc_B23-6_hap2" ~ "vpTaxBacc_B34-6_hap1",
		i == "vpTaxBacc_B34-6_hap1" ~ "vpTaxBacc_B34-6_hap2"
		)
	hap_bed <- read_tsv(paste0("bed/",i,".bed"), col_types = "c---", col_names = c("chr")) %>% as_tibble() %>% unique() %>% mutate(genome = i)
	syn_regs <- query_hits(gsParam, bed = hap_bed, synOnly = TRUE)
	for (j in 1:nrow(hap_bed)) {
		x <- syn_regs[[j]] %>% as_tibble() %>% filter(genome2 == other_hap) %>% select(chr1, start1, end1) %>% unique()
		dt <- rbind(dt, x)
	}
}
write_tsv(dt, "results/genespace_syntenic_regions_for_syri_comparsion.tsv", col_names = FALSE)

# plot output
ripd <- plot_riparian(
  gsParam = out,
  refGenome = "vpTaxBacc_B23-6_hap1", 
  useRegions = FALSE, inversionColor = "green", palette = colorRampPalette(c("grey")))
ggsave(paste0("riparian_plot.pdf"), ripd$plotData$ggplotObj, device = pdf, width=180, height=90, units="mm", compress = TRUE)
