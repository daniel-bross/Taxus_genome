#!/usr/bin/env Rscript

packages = c("tidyverse","parallel", "dbplyr","DBI","RSQLite","viridis","ggrastr")
package.check <- lapply(
  packages,
  FUN = function(x) {
      library(x, character.only = TRUE)
  }
)

basedir <- system("grep '^BASEDIR=' config.cfg",intern=TRUE) %>% str_split(., "=") %>% .[[1]] %>% .[2]
win_size <- system("grep '^WIN_SIZE=' config.cfg",intern=TRUE) %>% str_split(., "=") %>% .[[1]] %>% .[2] %>% as.numeric()
expect_cov <- system("grep '^EXP_COV=' config.cfg",intern=TRUE) %>% str_split(., "=") %>% .[[1]] %>% .[2] %>% as.numeric()
refsex <- system("grep '^REFSEX=' config.cfg",intern=TRUE) %>% str_split(., "=") %>% .[[1]] %>% .[2]
sigthreshold <- system("grep '^SIGTHRESHHOLD=' config.cfg",intern=TRUE) %>% str_split(., "=") %>% .[[1]] %>% .[2] %>% as.numeric()
dbdir <- paste0(basedir, "results/02_coverages/")
sigdir <- paste0(basedir, "results/03_sig_windows/")
outdir <- paste0(basedir, "results/04_plots/")

if (refsex == "female") {
	exp_less <- "mc"
	exp_more <- "fc"
} else if (refsex == "male") {
        exp_less <- "fc"
        exp_more <- "mc"
}

# create output directory
dir.create(file.path(outdir), showWarnings = FALSE)

# read test results
files <- paste0(sigdir,list.files(sigdir))
df <- read_tsv(files, col_names=c("chr","start","fc","mc","p"), col_types=c("ci-nnn") ) %>%
	mutate(chr = case_when(
			       grepl("unloc", chr) ~ str_extract(chr, "[[:digit:]]+(\\n|_)"), # handle unlocalized contigs
			       grepl("tg", chr) ~ "0", # handle unassembled contigs in female haplotypes
			       grepl("scaff", chr) ~ "0", # handle unassembled contigs in male haplotypes
			       .default = chr %>% str_extract(., "\\d+(?![^\\r\\n\\d]*\\d)")) # handle pseudochromosomes
	) %>%
	mutate(chr = str_extract(chr, "\\d+"), chr = as.numeric(chr)) %>% arrange(chr,start) %>% mutate(chr = chr %>% str_replace("^0","other"), chr = factor(chr,levels=unique(chr)) ) %>% # convert chr names
	mutate(l2f = log2( .data[[exp_more]] / .data[[exp_less]] )) # add l2fc

expect_p <- sigthreshold / nrow(df) # calculate bonferroni threshold

# generate plot
plot <- ggplot(df, aes(x = l2f, y = -log10(p))) +
        rasterise(geom_point(size = 2, color = "#8c2981", alpha = 0), dpi=600) +
        geom_vline(xintercept = 1, linetype = "dashed") +
        geom_hline(yintercept = -log10(expect_p), linetype="dashed") +
        theme_grey(base_size = 6) +
        labs(x = expression("log"[2]*"FC"), y = expression("-log"[10]*"p-value")) + #, colour = "chr") +
        scale_x_continuous(breaks = seq(-10, 10, 2))
ggsave(paste0(outdir,"coverage_volcano_plot.pdf"), plot, device=pdf, height=90, width=90, units="mm", compress = FALSE)

sprintf("[%s] ... done!",date())
