#!/usr/bin/env Rscript

#input: path to PLINK output .eigenvec file; a correspoding .eigenval file is expected to be in the same directory
args <- commandArgs(trailingOnly=TRUE)

packages = c("ggpubr","tidyverse","viridis")
package.check <- lapply(
  packages, FUN = function(x) {
      library(x, character.only = TRUE)
  }
)

name <- basename(args[1])
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
pca <- read_table(args[1], col_names = FALSE)
eigenval <- scan(paste0(tools::file_path_sans_ext(args[1]), ".eigenval"))

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
for (i in c(1,3,5,7)) {
	dt <- select(pca_final, library, sex, provenance, paste0("PC",i), paste0("PC",i+1)) %>% rename(a1 = paste0("PC",i), a2 =  paste0("PC",i+1))
	plist[[i]] <- ggplot(dt, aes(a1, a2, shape = provenance, color = sex)) + geom_point(size = 2) +
        xlab(paste0("PC",i," (", signif(pve$pve[i], 3), "%)")) +
        ylab(paste0("PC",i+1," (", signif(pve$pve[i+1], 3), "%)")) +
        geom_text(aes(label = library, color = sex), check_overlap=FALSE, size=1, alpha = 0.5) +
        theme_light(base_size = 5) +
        theme(plot.margin=margin(t=0,r=0,b=0,l=0),legend.margin=margin(t=0,r=0,b=0,l=0), legend.box.margin=margin(t=0,r=0,b=0,l=0), legend.key.size=unit(5,"mm"), legend.position="bottom", legend.justification.bottom = "left", legend.location = "plot", legend.title.position = "left") +
        scale_shape_manual(values = c(8,10,13,21,22,23,24,25), guide = guide_legend(title = "origin", nrow = 2, ncol = 4)) +
        scale_colour_manual(values = c("#3B62FF", "#F09B39"), guide = guide_legend(title = "sex", nrow = 2, ncol = 1))
}

plist <- plist[-which(sapply(plist, is.null))] 
names(plist) <- c(1,2,3,4)

plot <- ggarrange(plotlist = plist, align = "hv", ncol = 2, nrow = 2, common.legend = TRUE)

ggsave(paste0("results/",name,"_8pcs.pdf"), plot, device = "pdf", width = 180, height = 180, unit = "mm", compress = FALSE)
