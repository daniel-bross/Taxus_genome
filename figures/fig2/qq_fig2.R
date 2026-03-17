#!/usr/bin/env Rscript

packages <- c("tidyverse")
package.check <- lapply(
  packages,
  FUN = function(x) {
      library(x, character.only = TRUE)
  }
)

# adapted from https://danielroelfs.com/posts/how-i-make-qq-plots-using-ggplot/

ci <- 0.95

# load data
gwas <- read_table(paste0("source_data/fh1_gwas.txt"), col_type="--n") %>% mutate(observed = -log10(sort(p_lrt)))
n_snps <- nrow(gwas)
gwas <- gwas %>% mutate(expected = -log10(ppoints(n_snps)),
	clower = -log10(qbeta(p = (1 - ci) / 2, shape1 = seq(n_snps), shape2 = rev(seq(n_snps)))),
	cupper = -log10(qbeta( p = (1 + ci) / 2, shape1 = seq(n_snps), shape2 = rev(seq(n_snps))))
)

plotdata_sup <- gwas |> filter(expected > 2)
plotdata_sub <- gwas |> filter(expected <= 2) |> sample_frac(0.001)
plotdata_small <- bind_rows(plotdata_sup, plotdata_sub)

ribbon_data <- plotdata_small[c(1:99,seq(100, nrow(plotdata_small), by = 10000)), ]

# plot
qq <- ggplot(plotdata_small, aes(x = expected, y = observed)) +
  geom_point(size = 1.5) +
  geom_ribbon(data = ribbon_data, aes(ymin = clower, ymax = cupper), fill = "grey30", alpha = 0.5) +
  labs(x = expression('expected -log'[10]*'P'), y = expression('observed -log'[10]*'P')) +
  theme_classic(base_size = 7) +
  geom_abline(intercept = 0, slope = 1) +
  lims(x = c(0,NA), y = c(0,NA))

saveRDS(qq, file = paste0("results/qq_fig2.rds"))
