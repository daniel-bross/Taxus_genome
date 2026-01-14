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

for (i in c("fh1","fh2","mh1","mh2")) {
gwas <- read_table(paste0("source_data/",i,"_gwas.txt"), col_type="--n") %>% mutate(observed = -log10(sort(p_lrt)))
n_snps <- nrow(gwas)
gwas <- gwas %>% mutate(expected = -log10(ppoints(n_snps)),
	clower = -log10(qbeta(p = (1 - ci) / 2, shape1 = seq(n_snps), shape2 = rev(seq(n_snps)))),
	cupper = -log10(qbeta( p = (1 + ci) / 2, shape1 = seq(n_snps), shape2 = rev(seq(n_snps))))
)

plotdata_sub <- gwas |> filter(expected <= 2) |> sample_frac(0.01)
plotdata_sup <- gwas |> filter(expected > 2)
plotdata_small <- bind_rows(plotdata_sub, plotdata_sup)

qq1 <- ggplot(plotdata_small, aes(x = expected, y = observed)) +
  geom_ribbon(aes(ymax = cupper, ymin = clower), fill = "grey30", alpha = 0 ) +
  labs(x = expression('expected -log'[10]*'P'), y = expression('observed -log'[10]*'P')) +
  theme_classic(base_size = 6) +
  geom_abline(intercept = 0, slope = 1) +
  lims(x=c(0,NA),y=c(0,NA))
ggsave(paste0("results/", i, "_qq.pdf"), qq1, device = pdf, width=50, height=50, units="mm", compress = FALSE)

qq2 <- ggplot(plotdata_small, aes(x = expected, y = observed)) +
  geom_ribbon(aes(ymax = cupper, ymin = clower), fill = "grey30", alpha = 0.5 ) +
  geom_point(size= 1, alpha = 1) +
  labs(x = expression('expected -log'[10]*'P'), y = expression('observed -log'[10]*'P')) +
  theme_classic(base_size = 6) +
  geom_abline(intercept = 0, slope = 1, alpha = 0) +
  lims(x=c(0,NA),y=c(0,NA))
saveRDS(qq2, file = paste0("results/",i,"_qq.rds"))
ggsave(paste0("results/", i, "_qq.png"), qq2, device = png, width=50, height=50, units="mm")
}
