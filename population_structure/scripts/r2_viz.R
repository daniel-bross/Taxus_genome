#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly=TRUE)

name <- args[1]

packages = c("tidyverse","viridis")

package.check <- lapply(
  packages,
  FUN = function(x) {library(x, character.only = TRUE)}
)

basedir <- system("grep '^BASEDIR=' config.cfg",intern=TRUE) %>% str_split(., "=") %>% .[[1]] %>% .[2]
pheno <- system("grep '^PHENO=' config.cfg",intern=TRUE) %>% str_split(., "=") %>% .[[1]] %>% .[2]

outdir <- paste0(basedir,"results/",name,"/")

## load data from plink analysis
dt <- read_table(paste0(basedir,"results/",name,"/",name,"_filtered_r2.ld"))

dt2 <- dt %>% mutate(distance = BP_B - BP_A) %>% select(R2, distance) %>% mutate(distance = round(distance / 500, digits = 0) * 500) %>% group_by(distance)
dt3 <- dt2 %>% summarize(avg = mean(R2), med = median(R2))
dt4 <- dt2 %>% count(distance)
df <- inner_join(dt3,dt4)
df <- df %>% mutate(n = as.double(n))

plot <- ggplot(df, aes(x=distance, y=avg, colour = n)) + 
	geom_line() +
	scale_colour_viridis(option = "magma") +
        labs(title=paste0(name, ": LD decay"), x = "Distance (bp)", y = expression('Average LD ('~italic(r^2)~')'))
ggsave(paste0(name,"_filtered_ld_decay.pdf"), plot, device = "pdf", width = 15, height = 9, path = file.path(outdir))

