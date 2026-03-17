#!/usr/bin/env Rscript

library("tidyverse")

# adapted from https://danielroelfs.com/posts/how-i-create-manhattan-plots-using-ggplot/

colors = c("#0A0A0A","#B6BD2FA5")
# read gwas input
gwas <- read_table(paste0("source_data/fh1_gwas.txt"), col_type="cin") %>%
        mutate(chr = case_when(
                               grepl("unloc", chr) ~ str_extract(chr, "[[:digit:]]+(\\n|_)") %>% str_extract(., "[[:digit:]]+"), # handle unlocalized contigs
                               grepl("tg", chr) ~ "NA", # handle unassembled contigs in female haplotypes
                               grepl("scaff", chr) ~ "NA", # handle unassembled contigs in male haplotypes
                               .default = chr %>% str_extract(., "\\d+(?![^\\r\\n\\d]*\\d)")) # handle pseudochromosomes
        ) %>%
        mutate(chr = factor(chr,level=c("1","2","3","4","5","6","7","8","9","10","11","12","NA")) ) %>% # convert chr names  
	rename(bp=ps, p=p_lrt)

sig <- 0.05 / nrow(gwas) # calculate bonferroni threshold
sig_data <- gwas |> subset(p < 0.05)
notsig_data <- gwas |> subset(p >= 0.05) |> group_by(chr) |> sample_frac(0.1)
gwas <- bind_rows(sig_data, notsig_data) %>% arrange(chr,bp)

data_cum <- gwas |> group_by(chr) |> summarise(max_bp = as.numeric(max(bp))) |> mutate(bp_add = lag(cumsum(max_bp), default = 0)) |> select(chr, bp_add)
gwas <- gwas |> inner_join(data_cum, by = "chr") |> mutate(bp_cum = bp + bp_add)

axis_set <- gwas |> group_by(chr) |> summarize(center = mean(bp_cum))

plot <- ggplot(gwas, aes( x = bp_cum, y = -log10(p), color = as_factor(chr))) +
  geom_hline(yintercept = -log10(sig), color = "grey40", linetype = "dashed" ) +
  geom_point(size = 2, alpha = 0.75) +
  scale_x_continuous(label = axis_set$chr, breaks = axis_set$center) +
  scale_color_manual(values = rep_len(colors, nrow(axis_set))) +
  guides(color="none") +
  theme_classic(base_size = 7) +
  labs(x = "Chromosome", y = expression('-log'[10]*'P'))
saveRDS(plot, file = "results/manhattan_fig2.rds")

