#!/usr/bin/env Rscript

library("tidyverse")
library("patchwork")

colors <- c("#E85845","#6A9AD9")

for (i in c("fh1","fh2","mh1","mh2")) {
libinfo <- read_tsv("data/libinfo.txt" ,show_col_types = FALSE)
pheno <- read_tsv("data/pheno_100.txt", show_col_types = FALSE, col_names=TRUE) %>% mutate(across(3, as.character))
libnames <- libinfo %>%
	mutate(provenance = case_when(
                               grepl("Jelenia Góra", provenance) ~ "Jelenia Góra (PL)",
			       grepl("Wierzchlas", provenance) ~ "Wierzchlas (PL)",
			       grepl("unknown", provenance) ~ "unknown",
			       .default = provenance %>% paste(., "(DE)"))
        )

pca <- read_table(paste0("source_data/",i,"_pca.eigenvec"), col_names = FALSE)
eigenval <- scan(paste0("source_data/",i,"_pca.eigenval"))
pca <- pca[,-1]
names(pca)[1] <- "ind"
names(pca)[2:ncol(pca)] <- paste0("PC", 1:(ncol(pca)-1))
pve <- data.frame(PC = 1:length(eigenval), pve = eigenval/sum(eigenval)*100)

pheno$sex <- str_replace_all(pheno$sex,"1","male")
pheno$sex <- str_replace_all(pheno$sex,"2","female")
pca_final <- as_tibble(merge(pca, pheno, by.x="ind", by.y="FID")) %>% left_join(.,libnames, by=join_by("ind" == "sample")) %>%
	mutate(provenance = factor(provenance, levels = c("unknown", "Jelenia Góra (PL)", "Wierzchlas (PL)", "Eddigehausen (DE)", "Lengenberg (DE)", "Paterzell (DE)", "Gößweinstein (DE)", "Dermbach (DE)"))) %>%
	select(library, sex, provenance, PC1, PC2, PC3, PC4, PC5, PC6, PC7, PC8)

# grid plot PC1 - PC8
plist <- list()
for (j in c(1,3,5,7)) {
	dt <- select(pca_final, library, sex, provenance, paste0("PC",j), paste0("PC",j+1)) %>%
		rename(a1 = paste0("PC",j), a2 =  paste0("PC",j+1))

	plist[[j]] <- ggplot(dt, aes(a1, a2, shape = provenance, color = sex)) +
	geom_point(size = 2) +
        xlab(paste0("PC",j," (", signif(pve$pve[j], 3), "%)")) +
        ylab(paste0("PC",j+1," (", signif(pve$pve[j+1], 3), "%)")) +
        geom_text(aes(label = library, color = sex), check_overlap=FALSE, size=1, alpha = 0.5) +
        theme_classic(base_size = 7) +
        scale_shape_manual(values = c(8,10,13,21,22,23,24,25)) +
        scale_colour_manual(values = colors)
}
plist <- plist[-which(sapply(plist, is.null))] 

plot <- plist[[1]] + plist[[2]] + plist[[3]] + plist[[4]] + plot_layout(ncol = 2, nrow = 2, guides = "collect")
ggsave(paste0("results/",i,"_8pcs.pdf"), plot, device = "pdf", width = 180, height = 180, unit = "mm")
}
