#!/usr/bin/env Rscript

library("tidyverse")
library("ggh4x")
library("ggpubr")

df <- rbind(read_csv("data/W_kmer_consistency_full.csv", col_types = "-n--") %>% mutate(sex = "female", set = "random sets"), read_csv("data/Y_kmer_consistency_full.csv", col_types = "-n--") %>% mutate(sex = "male", set = "random sets"), read_csv("data/Mapping_Pops_W_kmer_consistency_full.csv", col_types = "-n--") %>% mutate(sex = "female", set = "population sets"), read_csv("data/Mapping_Pops_Y_kmer_consistency_full.csv", col_types = "-n--") %>% mutate(sex = "male", set = "population sets"))

counts <- df %>% count(sex, set, obs_freq) %>% mutate(set = factor(set, levels = c("random sets","population sets")))

plot <- ggplot(counts, aes(obs_freq, n, fill = sex)) +
  geom_bar(position="dodge", stat = "identity") +
  scale_y_continuous(trans = 'log10') +
  scale_fill_manual(values = c("#3B62FF", "#F09B39")) +
  theme_classic(base_size = 6) +
  labs(x = "observation count across replicates", y = "count") +
  theme(legend.position = "inside", legend.position.inside = c(.99, .5), legend.justification = c("right","center"), legend.box.just = "right", legend.margin = margin(6, 6, 6, 6),legend.background = element_rect(fill = "grey95"), legend.key.size = unit(5, "mm"))

f <- facet(plot, facet.by = "set", scales = "free_x") +
	facetted_pos_scales(x = list(scale_x_continuous(breaks = c(1:12), lim = c(0.8,12)), scale_x_continuous(breaks = c(1:6), lim = c(0.8,6)))) +
	force_panelsizes(cols = c(2,1), respect = TRUE) +
	theme(panel.spacing = unit(2, "mm"))
saveRDS(f, file = "results/kmer_consistency.pdf")
ggsave("results/kmer_consistency.pdf", f, device = "pdf", width = 130, height = 50, units = "mm")

