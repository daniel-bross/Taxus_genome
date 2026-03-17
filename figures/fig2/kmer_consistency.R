#!/usr/bin/env Rscript

library("tidyverse")

# load data
df <- rbind(read_csv("data/W_kmer_consistency_full.csv", col_types = "-n--") %>%
	count(obs_freq) %>%
	add_row(obs_freq = (nrow(.)+1):12, n = 0) %>%
	mutate(sex = "Female", set = "Random"),
  read_csv("data/Y_kmer_consistency_full.csv", col_types = "-n--") %>%
        count(obs_freq) %>%
        add_row(obs_freq = (nrow(.)+1):12, n = 0) %>%
        mutate(sex = "Male", set = "Random"),
  read_csv("data/Mapping_Pops_W_kmer_consistency_full.csv", col_types = "-n--") %>%
        count(obs_freq) %>%
        add_row(obs_freq = (nrow(.)+1):6, n = 0) %>%
        mutate(sex = "Female", set = "Population"),
  read_csv("data/Mapping_Pops_Y_kmer_consistency_full.csv", col_types = "-n--") %>%
        count(obs_freq) %>%
        add_row(obs_freq = (nrow(.)+1):6, n = 0) %>%
        mutate(sex = "Male", set = "Population")) %>%
	mutate(set = factor(set, levels = c("Random", "Population")))

colors <- c("#E85845","#6A9AD9")

# plot
plot <- ggplot(df %>% filter(set == "Random"), aes(x = n, y = factor(obs_freq), color = sex)) +
  geom_segment(aes(x = 0, xend = n, y = factor(obs_freq)), position = position_dodge(width = 0.6), linewidth = 0.6, color = "grey70") +
  geom_point(data = df %>% filter(set == "Random") %>% group_by(obs_freq) %>% filter(sum(n) > 0), aes(size = ifelse(n == 0, NA , 2)), position = position_dodge(width = 0.6)) +
  scale_color_manual(values = colors) +
  scale_size_continuous(range = c(1.5,1.5), limits = c(1.5,1.5)) +
  scale_y_discrete() +
  scale_x_log10() +  
  labs(x = "Sex-specific k-mers", y = "Consistency", color = "Sex" ) +
  theme_classic(base_size = 7) +
  guides(size = "none", color = "none") +
  theme(strip.text = element_blank())
saveRDS(plot, file = "results/kmer_consistency_random.rds")

plot <- ggplot(df %>% filter(set == "Population"), aes(x = n, y = factor(obs_freq), color = sex)) +
  geom_segment(aes(x = 0, xend = n, y = factor(obs_freq)), position = position_dodge(width = 0.6), linewidth = 0.6, color = "grey70") +
  geom_point(data = df %>% filter(set == "Population") %>% group_by(obs_freq) %>% filter(sum(n) > 0), aes(size = ifelse(n == 0, NA , 2)), position = position_dodge(width = 0.6)) +
  scale_color_manual(values = colors) +
  scale_size_continuous(range = c(1.5,1.5), limits = c(1.5,1.5)) +
  scale_y_discrete() +
  scale_x_log10() +
  labs(x = "Sex-specific k-mers", y = "Consistency", color = "Sex" ) +
  theme_classic(base_size = 7) +
  guides(size = "none", color = "none") +
  theme(strip.text = element_blank())
saveRDS(plot, file = "results/kmer_consistency_population.rds")
