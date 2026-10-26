#!/usr/bin/env Rscript

library("tidyverse")
library("ggridges")
library("legendry")

input <- "data/setcollection.tsv"
colors <- c("#6A9AD9","#E85845")

# load input
df <- read_table(input, col_type="-ff-n--") %>%
	rename(set = Category, sex = Zielgruppe, count = Kmers_Phase2) %>%
	filter(set != "Random_8vs8") %>% group_by(sex) %>%
	mutate(sex = factor(case_when(grepl("f", sex) ~ "female" , .default = "male"))) %>%
	mutate(group = factor(interaction(set, sex, drop = TRUE))) %>%
	mutate(group = factor(group, levels = sort(levels(group), decreasing = TRUE)))

# ridgeplot 
plot <-  ggplot(df, aes(x = count, y = group, fill = sex)) + 
  geom_density_ridges(lwd = 0.5, scale = 0.99) +
  stat_summary(fun = mean, geom = "crossbar", aes(x = count, y = as.integer(group) + 0.25), width = 0.5) +
  scale_fill_manual(values = alpha(colors, 0.7)) +
  scale_x_continuous(name = "Number of distinct sex-specific k-mers") +
  scale_y_discrete(name = "Set", labels = c("Male", "Female","Male","Female")) +
  guides(fill = "none", x = guide_axis_nested(key = key_range_manual(start = c(1,3), end = c(2,4), name = c("Random", "Population")))) +
  theme_classic(base_size = 7) +
  coord_flip()

saveRDS(plot, file = "results/kmer_sets.rds")
