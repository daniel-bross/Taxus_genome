#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly=TRUE)
name <- args[1]

packages = c("tidyverse")

package.check <- lapply(
  packages,
  FUN = function(x) {library(x, character.only = TRUE)}
)

basedir <- system("grep '^BASEDIR=' config.cfg",intern=TRUE) %>% str_split(., "=") %>% .[[1]] %>% .[2]
pheno <- system("grep '^PHENO=' config.cfg",intern=TRUE) %>% str_split(., "=") %>% .[[1]] %>% .[2]
outdir <- paste0(basedir,"results/",name,"/")

## load data from plink analysis
het <- read_table(paste0(basedir,"results/",name,"/",name,"_filtered_het.het"), col_names=)
imis <- read_table(paste0(basedir,"results/",name,"/",name,"_filtered_missing.imiss"), col_names=)

het %>% summarize(mean = mean(F), std = sd(F))

plot <- ggplot(het, aes(F)) +
	geom_histogram(bins=30) +
        labs(title=paste0(name, "_filtered: F statistic distribution"), x = "F", y = "Frequency")
ggsave(paste0(name,"_filtered_hetdist.pdf"), plot, device = "pdf", width = 15, height = 9, path = file.path(outdir))

plot <- ggplot(imis, aes(F_MISS)) +
        geom_histogram(bins=30) +
        labs(title=paste0(name, "_filtered: missing gt data distribution"), x = "fraction of missing genotypes", y = "Frequency")
ggsave(paste0(name,"_filtered_imisdist.pdf"), plot, device = "pdf", width = 15, height = 9, path = file.path(outdir))

