#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)


packages = c("tidyverse","parallel", "dbplyr","DBI","RSQLite","viridis")

package.check <- lapply(
  packages,
  FUN = function(x) {
      library(x, character.only = TRUE)
  }
)

basedir <- system("grep '^BASEDIR=' config.cfg",intern=TRUE) %>% str_split(., "=") %>% .[[1]] %>% .[2]
dbdir <- paste0(basedir, "results/02_coverages/")
outdir <- paste0(basedir, "results/04_plots/")
fcount <- as.numeric(system('cat data/female_mappings.txt | wc -l',intern=TRUE))
mcount <- as.numeric(system('cat data/male_mappings.txt | wc -l',intern=TRUE))
win_size <- system("grep '^WIN_SIZE=' config.cfg",intern=TRUE) %>% str_split(., "=") %>% .[[1]] %>% .[2] %>% as.numeric()
expect_cov <- system("grep '^EXP_COV=' config.cfg",intern=TRUE) %>% str_split(., "=") %>% .[[1]] %>% .[2] %>% as.numeric()

# create output directory
dir.create(file.path(outdir), showWarnings = FALSE)

# read in sample names
fsamples <- read_table("data/female_mappings.txt", col_names = "name") %>% mutate( name = name %>% str_extract(., "[\\d+unloc_]*\\d+(?![^\\r\\n\\d]*\\d)"))
msamples <- read_table("data/male_mappings.txt", col_names = "name") %>% mutate( name = name %>% str_extract(., "[\\d+unloc_]*\\d+(?![^\\r\\n\\d]*\\d)"))

# create database connection
con <- DBI::dbConnect(RSQLite::SQLite(), dbname = paste(dbdir, "coverages.db", sep=""))

lines <- dbGetQuery(con, paste0("SELECT * FROM t1")) %>% as_tibble()
DBI::dbDisconnect(con)

dt <- lines %>%
	mutate(female = rowMeans(select(lines, starts_with("f_")), na.rm = TRUE)) %>%
	mutate(male = rowMeans(select(lines, starts_with("m_")), na.rm = TRUE)) %>%
	select(chr, start, female, male) %>% filter(female < 3 * expect_cov * win_size & male < 3 * expect_cov * win_size)

# calculate mode of DP distribution
fdens <- density(dt$female[dt$female < expect_cov * 2 * win_size])
mdens <- density(dt$male[dt$male < expect_cov * 2 * win_size])
fmode <- fdens$x[which.max(fdens$y)]
mmode <- mdens$x[which.max(mdens$y)]

pivot <- dt %>% pivot_longer(values_to="cov", names_to="Variable", cols=c("female","male")) 
plot <- ggplot(pivot, aes(x=cov, colour=Variable, fill=Variable)) +
	geom_density() +
        scale_colour_manual(values=alpha(c(magma(n=1,begin=0.2,end=0.2), magma(n=1,begin=0.8,end=0.8)), 1)) +
	scale_fill_manual(values=alpha(c(magma(n=1,begin=0.2,end=0.2), magma(n=1,begin=0.8,end=0.8)), 0.3)) +
	labs(title = paste0("Female mode: ", fmode/win_size, "; Male mode: ", mmode/win_size)) +
	labs(x="average coverage",y="density")

ggsave(paste0(outdir,"coverage_distribution.png"), plot, dpi="print", height=9, width=16)

sprintf("[%s] ... done!",date())
