#!/usr/bin/env Rscript

packages = c("tidyverse","vegan","snpStats","ggpubr")
package.check <- lapply(
  packages, FUN = function(x) {
      library(x, character.only = TRUE)
  }
)

libinfo <- read_tsv("data/libinfo.txt" ,show_col_types = FALSE)
pheno <- read_tsv("data/pheno_100.txt", show_col_types = FALSE, col_names=TRUE) %>% mutate(across(3, as.character))

libnames <- libinfo %>%
	mutate(provenance = case_when(
                               grepl("Jelenia Góra", provenance) ~ "Jelenia Góra (PL)",
			       grepl("Wierzchlas", provenance) ~ "Wierzchlas (PL)",
			       grepl("unknown", provenance) ~ "unknown",
			       .default = provenance %>% paste(., "(DE)"))
        )

x <- snpStats::read.plink("data/nmds/subset_100_popstruct_filtered_pruned") # read plink input
mat <- as(x$genotypes, "numeric") # convert to matrix
dmat <- dist(mat, method="manhattan") # compute distance matrix with manhattan distance
nmds = metaMDS(dmat, try = 100, trymax = 200) # compute nmds
# stress is around 0.2, which is bad

df <- scores(nmds,tidy=TRUE) %>% as_tibble() %>% inner_join(libnames, by = join_by(label == sample)) %>% inner_join(pheno, by = join_by(label == FID)) %>%
	mutate(provenance = factor(provenance, levels = c("unknown", "Jelenia Góra (PL)", "Wierzchlas (PL)", "Eddigehausen (DE)", "Lengenberg (DE)", "Paterzell (DE)", "Gößweinstein (DE)", "Dermbach (DE)")))

plot <- ggplot(df, aes(x = NMDS1, y = NMDS2, color = str_sex, shape = provenance)) +
	geom_point(size = 6) +
	theme_classic() +
	theme(plot.margin=margin(t=0,r=0,b=0,l=0),legend.margin=margin(t=0,r=0,b=0,l=0), legend.box.margin=margin(t=0,r=0,b=0,l=-10), legend.key.size=unit(5,"mm"), legend.justification.bottom = "left", legend.location = "plot", legend.title.position = "left") +
        coord_equal() +
	scale_shape_manual(values = c(8,10,13,21,22,23,24,25), guide = guide_legend(title = "origin")) +
	scale_color_manual(values = c("#3B62FF", "#F09B39"), guide = guide_legend(title = "sex"))

df2 <- tibble(distance = nmds$dist, dissimilarity = nmds$diss)

formula <- y ~ poly(x, 3, raw = TRUE)

splot <- ggscatter(df2, x="dissimilarity", y="distance", ylim = c(0,NA), title = paste0("Stress: ",nmds$stress)) +
	 stat_smooth(method = "lm", formula = formula) +
	 stat_cor(method = "pearson")

plist <- list(plot, splot)
a <- ggarrange(plotlist = plist, labels = "auto", ncol = 1, nrow = 2)
ggsave("results/nmds_with_stressplot.pdf", a, device = "pdf", width = 210, height = 297, unit = "mm", compress = FALSE)

