#!/usr/bin/env Rscript

packages = c("tidyverse","viridis","gridExtra","GGally")
package.check <- lapply(
  packages, FUN = function(x) {
      library(x, character.only = TRUE)
  }
)

input <- "data/setcollection.tsv"

df <- read_table(input, col_type="-cc-d--") %>% rename(set = Category, sex = Zielgruppe, count = Kmers_Phase2) %>% filter(set != "Random_8vs8") %>% group_by(sex) %>%
	mutate(sex = case_when(grepl("f", sex) ~ "female" , .default = "male"))
dup <- df %>% mutate(set="combined")
df2 <- bind_rows(df,dup) %>% mutate(set = factor(set, levels = c("Random_6vs6","Population","combined")))

kmersets <- ggplot(df2, aes(x = set, y = count, fill = sex)) +
  geom_boxplot(outliers = TRUE) +
  scale_fill_manual(values = c("#3B62FF", "#F09B39")) +
  theme_classic(base_size = 6) +
  scale_x_discrete(labels=c("random sets","population sets","combined")) +
  stat_summary(aes(group = sex), fun = mean, geom = 'point', position = position_dodge(width = 0.75), shape = 23, fill = "white") +
  theme(legend.position = "inside", legend.position.inside = c(.05, .95), legend.justification = c("left", "top"), legend.box.just = "right", legend.margin = margin(6, 6, 6, 6),legend.background = element_rect(fill = "grey95"))

saveRDS(kmersets, file = "results/kmer_sets.rds")
ggsave(paste0("results/kmer_set_sizes.pdf"), kmersets, device = "pdf", width = 80, height = 90, unit = "mm", compress = FALSE)
