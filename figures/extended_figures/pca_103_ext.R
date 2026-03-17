#!/usr/bin/env Rscript

packages = c("tidyverse")
package.check <- lapply(
  packages, FUN = function(x) {
      library(x, character.only = TRUE)
  }
)

libinfo <- read_tsv("data/libinfo.txt" ,show_col_types = FALSE)
pheno <- read_tsv("data/pheno_103.txt", show_col_types = FALSE, col_names=TRUE) %>% mutate(across(3, as.character))
colors <- c("#E85845","#6A9AD9")
libnames <- libinfo %>%
	mutate(provenance = case_when(
                               grepl("Jelenia Góra", provenance) ~ "Jelenia Góra (PL)",
			       grepl("Wierzchlas", provenance) ~ "Wierzchlas (PL)",
			       grepl("unknown", provenance) ~ "unknown",
			       .default = provenance %>% paste(., "(DE)"))
        )

pca <- read_table("source_data/subset_103_popstruct_pca.eigenvec", col_names = FALSE)
eigenval <- scan("source_data/subset_103_popstruct_pca.eigenval")
pca <- pca[,-1]
names(pca)[1] <- "ind"
names(pca)[2:ncol(pca)] <- paste0("PC", 1:(ncol(pca)-1))
pve <- data.frame(PC = 1:length(eigenval), pve = eigenval/sum(eigenval)*100)

pheno$sex <- str_replace_all(pheno$sex,"1","male")
pheno$sex <- str_replace_all(pheno$sex,"2","female")
pca_final <- as_tibble(merge(pca, pheno, by.x="ind", by.y="FID")) %>% left_join(.,libnames, by=join_by("ind" == "sample")) %>%
        mutate(provenance = factor(provenance, levels = c("unknown", "Jelenia Góra (PL)", "Wierzchlas (PL)", "Eddigehausen (DE)", "Lengenberg (DE)", "Paterzell (DE)", "Gößweinstein (DE)", "Dermbach (DE)")))

# plot PC1 and PC2
plot <- ggplot(pca_final, aes(PC1, PC2, shape = provenance, color = sex)) +
        geom_point(size = 3, stroke = 1.2) +
        xlab(paste0("PC1 (", signif(pve$pve[1], 3), "%)")) +
        ylab(paste0("PC2 (", signif(pve$pve[2], 3), "%)")) +
        theme_classic(base_size = 7) +
        theme(legend.text.align = 0) +
        coord_equal() +
        scale_colour_manual(values = colors, guide = guide_legend(title = "sex", nrow = 2, ncol = 1, order = 1)) +
        scale_shape_manual(values = c(8,10,13,21,22,23,24,25), guide = guide_legend(title = "provenance", nrow = 8, ncol = 1, order = 2))

ggsave(paste0("results/fh1_pca_103_samples.pdf"), plot, device = "pdf", width = 120, height = 120, unit="mm")
