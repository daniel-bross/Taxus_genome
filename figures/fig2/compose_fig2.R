#!/usr/bin/env Rscript

library("tidyverse")
library("patchwork")

# load data
pca <- readRDS("results/pca_fig2.rds")
kmer_set_sizes <- readRDS("results/kmer_sets.rds")
kmer_consistency_random <- readRDS("results/kmer_consistency_random.rds")
kmer_consistency_population <- readRDS("results/kmer_consistency_population.rds")
qq <- readRDS("results/qq_fig2.rds")
manhattan <- readRDS("results/manhattan_fig2.rds")

# plot raster images
design <- "112\n112\n334\n555"

# disable data overlaying the points in qq plot
qq$layers$geom_ribbon$aes_params$alpha <- 0
qq$layers$geom_abline$aes_params$alpha <- 0

plot_raster <- pca + kmer_set_sizes +
        (free(kmer_consistency_random + kmer_consistency_population, side = "r")) + qq + manhattan +
        plot_layout(design = design, heights = c(1,1,1,0.75)) + plot_annotation(tag_levels = 'a')

ggsave("results/fig2.png", plot_raster, device = "png", height = 210, width = 180, unit = "mm", dpi = 600)

# reset and filter out data that would clutter the pdf and plot
qq$layers$geom_ribbon$aes_params$alpha <- 0.5
qq$layers$geom_abline$aes_params$alpha <- 1
qq$layers$geom_point$aes_params$size <- NA
manhattan$layers$geom_point$aes_params$size <- NA

plot_vector <- pca + kmer_set_sizes +
        (free(kmer_consistency_random + kmer_consistency_population, side = "r")) + qq + manhattan +
        plot_layout(design = design, heights = c(1,1,1,0.75)) + plot_annotation(tag_levels = 'a')

ggsave("results/fig2.pdf", plot_vector, device = "pdf",  height = 210, width = 180, unit = "mm", compress = TRUE)

# the plots are still a bit messed up with background panels overlaying some axes, the rest is cleaned up afterwards (e.g., inkscape)
