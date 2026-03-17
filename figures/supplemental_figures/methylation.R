#!/usr/bin/env Rscript

library("data.table")
library("tidyverse")
library("patchwork")

# load source data
dt <- fread("source_data/candidate_gene_methylation.tsv")

struct_annot <- fread("source_data/fh1_tsebra_combined_renamed.gtf")[V3 == "gene",.(V1,V4,V5,V7,V9)]
setnames(struct_annot, c("V1","V4","V5","V7","V9"), c("chr","begin","end","strand","gene_id"))

dt <- dt[struct_annot, on = c("gene_id"), nomatch = NULL]

# plot
colors <- c("#E85845","#6A9AD9") # red, blue

df1 <- dt %>% filter(gene_id == "g16126")
df2 <- dt %>% filter(gene_id == "g4483")

plot_g16126 <- ggplot(df1, aes(x = begin, y = score, colour = sex)) +
        	geom_point(aes(alpha = ifelse(padj < 0.05, 1, 0.5))) +
                geom_smooth(aes(ymin = 0, ymax = 100)) +
                geom_segment(x = df1$i.begin[1], xend = df1$i.end[1], y = 5,yend = 5, color = "black") +
                guides(alpha = "none") +
                theme_classic() +
                scale_color_manual(values = colors) +
		lims(x = c(df1$i.begin[1] - 5000, df1$i.end[1] + 5000),y = c(0,100)) +
                labs(x = paste0("position on chromosome ", df1$chr[1] ," [bp]"), y = "methylation rate")

plot_g4483 <- ggplot(df2, aes(x = begin, y = score, colour = sex)) +
                geom_point(aes(alpha = ifelse(padj < 0.05, 1, 0.5))) +
                geom_smooth(aes(ymin = 0, ymax = 100)) +
                geom_segment(x = df2$i.begin[1], xend = df2$i.end[1], y = 5,yend = 5, color = "black") +
                guides(alpha = "none") +
                theme_classic() +
                scale_color_manual(values = colors) +
		lims(x = c(df2$i.begin[1] - 5000, df2$i.end[1] + 5000),y = c(0,100)) +
                labs(x = paste0("position on chromosome ", df2$chr[1] ," [bp]"), y = "methylation rate")

plot <- plot_g16126 + plot_g4483 + plot_layout(design = "12", guides = "collect", axes = "collect_y") + plot_annotation(tag_levels = 'a') & theme(legend.position='bottom')

ggsave("results/plot_candidates_methylation.pdf", plot, width = 8, device = "pdf")

