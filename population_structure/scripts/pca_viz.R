#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly=TRUE)
name <- args[1]

packages = c("tidyverse","GGally","unix","viridis","gridExtra")

package.check <- lapply(
  packages,
  FUN = function(x) {library(x, character.only = TRUE)}
)

basedir <- system("grep '^BASEDIR=' config.cfg",intern=TRUE) %>% str_split(., "=") %>% .[[1]] %>% .[2]
pheno <- system("grep '^PHENO=' config.cfg",intern=TRUE) %>% str_split(., "=") %>% .[[1]] %>% .[2]
dname <- dirname(name)
fname <- basename(name)
libnames <- read_tsv("data/libinfo.txt")

print("package check compelte. Reading PCA table...")
## load data from plink analysis
pca <- read_table(paste0(name, ".eigenvec"), col_names = FALSE)

eigenval <- scan(paste0(name, ".eigenval"))

pca <- pca[,-1]
names(pca)[1] <- "ind"
names(pca)[2:ncol(pca)] <- paste0("PC", 1:(ncol(pca)-1))
pve <- data.frame(PC = 1:length(eigenval), pve = eigenval/sum(eigenval)*100)

## plot scree plot
plot <- ggplot(pve, aes(PC, pve)) + geom_bar(stat = "identity") +
	ylab("Percentage variance explained") +
	theme_light()
ggsave(paste0(fname,"_scree_plot.pdf"), plot, device = "pdf", width = 15, height = 9, path = file.path(dname))

## check if all axes add up to exactly 100
cumsum(pve$pve)

phenotype <- read_table(pheno, col_names = TRUE) # plink phenotype file: FID	IID	sex	pheno	sample_name	sex_string
phenotype %>% mutate(across(3, as.character))
phenotype$sex <- str_replace_all(phenotype$sex,"1","male")
phenotype$sex <- str_replace_all(phenotype$sex,"2","female")
pca_final <- as_tibble(merge(pca, phenotype, by.x="ind", by.y="FID")) %>% left_join(.,libnames, by=join_by("ind" == "sample"))

## pca plot with first two PCs
plot <- ggplot(pca_final, aes(PC1, PC2, col = provenance, shape = sex)) + geom_point(size = 3) +
	xlab(paste0("PC1 (", signif(pve$pve[1], 3), "%)")) +
	ylab(paste0("PC2 (", signif(pve$pve[2], 3), "%)")) +
	theme(plot.margin=margin(t=0,r=0,b=0,l=0)) +
	theme_light(base_size = 6) +
	coord_equal() +
	scale_colour_viridis_d(option = "magma", begin=0.1, end=0.9)
ggsave(paste0(fname,"_pc1_pc2_small.pdf"), plot, device = "pdf", width = 90, height = 90, unit="mm", path = file.path(dname))

p12 <- ggplot(pca_final, aes(PC1, PC2, col = provenance, shape = sex)) + geom_point(size = 2) +
        xlab(paste0("PC1 (", signif(pve$pve[1], 3), "%)")) +
        ylab(paste0("PC2 (", signif(pve$pve[2], 3), "%)")) +
        theme_light(base_size=6) +
	theme(plot.margin=margin(t=0,r=0,b=0,l=0), legend.margin=margin(t=0,r=0,b=0,l=0), legend.key.size=unit(5,"mm")) +
        coord_equal() +
        geom_text(aes(label = library), colour="grey3", check_overlap=FALSE, size=2) +
        scale_colour_viridis_d(option = "magma", begin=0.1, end=0.9)

p34 <- ggplot(pca_final, aes(PC3, PC4, col = provenance, shape = sex)) + geom_point(size = 2) +
        xlab(paste0("PC3 (", signif(pve$pve[3], 3), "%)")) +
        ylab(paste0("PC4 (", signif(pve$pve[4], 3), "%)")) +
	theme_light(base_size=6) +
        theme(plot.margin=margin(t=0,r=0,b=0,l=0), legend.margin=margin(t=0,r=0,b=0,l=0), legend.key.size=unit(5,"mm")) +
	coord_equal() +
        geom_text(aes(label = library), colour="grey3", check_overlap=FALSE, size=2) +
        scale_colour_viridis_d(option = "magma", begin=0.1, end=0.9)

p56 <- ggplot(pca_final, aes(PC5, PC6, col = provenance, shape = sex)) + geom_point(size = 2) +
        xlab(paste0("PC5 (", signif(pve$pve[5], 3), "%)")) +
        ylab(paste0("PC6 (", signif(pve$pve[6], 3), "%)")) +
        theme_light(base_size=6) +
        theme(plot.margin=margin(t=0,r=0,b=0,l=0), legend.margin=margin(t=0,r=0,b=0,l=0), legend.key.size=unit(5,"mm")) +
	coord_equal() +
        geom_text(aes(label = library), colour="grey3", check_overlap=FALSE, size=2) +
        scale_colour_viridis_d(option = "magma", begin=0.1, end=0.9)

p78 <- ggplot(pca_final, aes(PC7, PC8, col = provenance, shape = sex)) + geom_point(size = 2) +
        xlab(paste0("PC7 (", signif(pve$pve[7], 3), "%)")) +
        ylab(paste0("PC8 (", signif(pve$pve[8], 3), "%)")) +
        theme_light(base_size=6) +
        theme(plot.margin=margin(t=0,r=0,b=0,l=0), legend.margin=margin(t=0,r=0,b=0,l=0), legend.key.size=unit(5,"mm")) +
        coord_equal() +
        geom_text(aes(label = library), colour="grey3", check_overlap=FALSE, size=2) +
        scale_colour_viridis_d(option = "magma", begin=0.1, end=0.9)

plot <- grid.arrange(p12,p34,p56,p78)

ggsave(paste0(fname,"_8pcs.pdf"), plot, device = "pdf", width = 180, height = 180, unit = "mm" ,path = file.path(dname))
