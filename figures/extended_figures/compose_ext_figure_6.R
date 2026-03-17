#!/usr/bin/env Rscript

library("tidyverse")
library("patchwork")

# load data
qq_fh2 <- readRDS("results/qq_ext_fh2.rds")
qq_mh1 <- readRDS("results/qq_ext_mh1.rds")
qq_mh2 <- readRDS("results/qq_ext_mh2.rds")
manhattan_fh2 <- readRDS("results/manhattan_fh2.rds")
manhattan_mh1 <- readRDS("results/manhattan_mh1.rds")
manhattan_mh2 <- readRDS("results/manhattan_mh2.rds")


# plot raster images
design <- "1112\n3334\n5556"

# disable data overlaying the points in qq plot
qq_fh2$layers$geom_ribbon$aes_params$alpha <- 0
qq_fh2$layers$geom_abline$aes_params$alpha <- 0
qq_mh1$layers$geom_ribbon$aes_params$alpha <- 0
qq_mh1$layers$geom_abline$aes_params$alpha <- 0
qq_mh2$layers$geom_ribbon$aes_params$alpha <- 0
qq_mh2$layers$geom_abline$aes_params$alpha <- 0

plot_raster <- manhattan_fh2 + qq_fh2 +
	manhattan_mh1 + qq_mh1 +
	manhattan_mh2 + qq_mh2 +
        plot_layout(design = design) + plot_annotation(tag_levels = 'a')

ggsave("results/ext_data_fig_6.png", plot_raster, device = "png", height = 135 , width = 180, unit = "mm", dpi = 600)

# reset and filter out data that would clutter the pdf and plot
qq_fh2$layers$geom_ribbon$aes_params$alpha <- 0.5
qq_fh2$layers$geom_abline$aes_params$alpha <- 1
qq_fh2$layers$geom_point$aes_params$size <- NA
manhattan_fh2$layers$geom_point$aes_params$size <- NA
qq_mh1$layers$geom_ribbon$aes_params$alpha <- 0.5
qq_mh1$layers$geom_abline$aes_params$alpha <- 1
qq_mh1$layers$geom_point$aes_params$size <- NA
manhattan_mh1$layers$geom_point$aes_params$size <- NA
qq_mh2$layers$geom_ribbon$aes_params$alpha <- 0.5
qq_mh2$layers$geom_abline$aes_params$alpha <- 1
qq_mh2$layers$geom_point$aes_params$size <- NA
manhattan_mh2$layers$geom_point$aes_params$size <- NA

plot_vector <- manhattan_fh2 + qq_fh2 +
        manhattan_mh1 + qq_mh1 +
        manhattan_mh2 + qq_mh2 +
        plot_layout(design = design) + plot_annotation(tag_levels = 'a')

ggsave("results/ext_data_fig_6.pdf", plot_vector, device = "pdf",  height = 135, width = 180, unit = "mm", compress = TRUE)

# the plots are still a bit messed up with background panels overlaying some axes, the rest is cleaned up afterwards (e.g., in inkscape)
