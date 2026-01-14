#!/usr/bin/env Rscript

packages = c("ggpubr","tidyverse")
package.check <- lapply(
  packages,
  FUN = function(x) {
      library(x, character.only = TRUE)
  }
)

p1 <- list()
p2 <- list()

for (i in c("fh1","fh2","mh1","mh2")) {

if (substr(i,1,1) == "f") {exp_less <- "mc"; exp_more <- "fc"} else if (substr(i,1,1) == "m") {exp_less <- "fc"; exp_more <- "mc"}

# read and process test results
files <- paste0("data/",i,"_coverage_sigwin/",list.files(paste0("data/",i,"_coverage_sigwin/")))
df <- read_tsv(files, col_names=c("chr","start","fc","mc","p"), col_types=c("ci-nnn") ) %>%
	mutate(l2f = log2( .data[[exp_more]] / .data[[exp_less]] )) # add l2fc

expect_p <- 0.05 / nrow(df) # calculate bonferroni threshold

# generate plots
p1[[i]] <- ggplot(df, aes(x = l2f, y = -log10(p))) +
        geom_point(size = 2, alpha = 0) +
        geom_vline(xintercept = 1, linetype = "dashed") +
        geom_hline(yintercept = -log10(expect_p), linetype="dashed") +
        theme_classic(base_size = 6) +
        labs(x = expression("log"[2]*"FC"), y = expression("-log"[10]*"p-value")) +
        scale_x_continuous(breaks = seq(-10, 10, 2), limits = c(NA, 13))

p2[[i]] <- ggplot(df, aes(x = l2f, y = -log10(p))) +
        geom_point(size = 2) +
	geom_hline(yintercept = -log10(expect_p), linetype="dashed", alpha = 0) +
        theme_classic(base_size = 6) +
        labs(x = expression("log"[2]*"FC"), y = expression("-log"[10]*"p-value")) +
	scale_x_continuous(breaks = seq(-10, 10, 2), limits = c(NA, 13))
}

plot1 <- ggarrange(plotlist = p1, ncol = 2, nrow = 2, labels = "auto")
plot2 <- ggarrange(plotlist = p2, ncol = 2, nrow = 2, labels = "auto")

ggsave("results/volcano.pdf", plot1, device=pdf, height=120, width=120, units="mm", compress = FALSE)
ggsave("results/volcano.png", plot2, device=png, height=120, width=120, units="mm")

