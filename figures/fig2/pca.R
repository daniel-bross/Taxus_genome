#!/usr/bin/env Rscript

packages = c("tidyverse","viridis","gridExtra","GGally")
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


paste(date(),"Reading PCA table...")
pca <- read_table("source_data/fh1_pca.eigenvec", col_names = FALSE)
eigenval <- scan("source_data/fh1_pca.eigenval")

pca <- pca[,-1]
names(pca)[1] <- "ind"
names(pca)[2:ncol(pca)] <- paste0("PC", 1:(ncol(pca)-1))
pve <- data.frame(PC = 1:length(eigenval), pve = eigenval/sum(eigenval)*100)

pheno$sex <- str_replace_all(pheno$sex,"1","male")
pheno$sex <- str_replace_all(pheno$sex,"2","female")
pca_final <- as_tibble(merge(pca, pheno, by.x="ind", by.y="FID")) %>% left_join(.,libnames, by=join_by("ind" == "sample")) %>%
	mutate(provenance = factor(provenance, levels = c("unknown", "Jelenia Góra (PL)", "Wierzchlas (PL)", "Eddigehausen (DE)", "Lengenberg (DE)", "Paterzell (DE)", "Gößweinstein (DE)", "Dermbach (DE)")))

# PC1 PC2 focus
pca12 <- ggplot(pca_final, aes(PC1, PC2, shape = provenance, color = sex)) + geom_point(size = 3) +
	xlab(paste0("PC1 (", signif(pve$pve[1], 3), "%)")) +
	ylab(paste0("PC2 (", signif(pve$pve[2], 3), "%)")) +
	theme_light(base_size = 5) +
	theme(plot.margin=margin(t=0,r=0,b=0,l=0),legend.margin=margin(t=0,r=0,b=0,l=0), legend.box.margin=margin(t=0,r=0,b=0,l=-10), legend.key.size=unit(5,"mm"), legend.position="bottom", legend.justification.bottom = "left", legend.location = "plot", legend.title.position = "left") +
	coord_equal() +
	scale_shape_manual(values = c(8,10,13,21,22,23,24,25), guide = guide_legend(title = "origin", nrow = 2, ncol = 4)) +	
	scale_colour_manual(values = c("#3B62FF", "#F09B39"), guide = guide_legend(title = "sex", nrow = 2, ncol = 1))
saveRDS(pca12, file = paste0("results/fh1_pc1_2.rds"))
ggsave(paste0("results/fh1_pc1_2.pdf"), pca12, device = "pdf", width = 100, height = 90, unit="mm", compress = FALSE)
