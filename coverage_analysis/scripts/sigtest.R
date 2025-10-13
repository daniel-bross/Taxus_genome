#!/usr/bin/env Rscript
args <- commandArgs(trailingOnly=TRUE)

packages = c("tidyverse","parallel", "dbplyr","DBI","RSQLite")

package.check <- lapply(
  packages,
  FUN = function(x) {
    if (!require(x, character.only = TRUE)) {
      install.packages(x, dependencies = TRUE, repos = "https://cloud.r-project.org")
      library(x, character.only = TRUE)
    }
  }
)

basedir <- system("grep '^BASEDIR=' config.cfg",intern=TRUE) %>% str_split(., "=") %>% .[[1]] %>% .[2]
inputdir <- paste0(basedir, "results/02_coverages/")
outputdir <- paste0(basedir, "results/03_sig_windows/")
refsex <- system("grep '^REFSEX=' config.cfg",intern=TRUE) %>% str_split(., "=") %>% .[[1]] %>% .[2]
job_id <- args[1] %>% as.numeric()
sigthreshold <- system("grep '^SIGTHRESHHOLD=' config.cfg",intern=TRUE) %>% str_split(., "=") %>% .[[1]] %>% .[2] %>% as.numeric()
dbsize <- system("grep '^DBSIZE=' config.cfg",intern=TRUE) %>% str_split(., "=") %>% .[[1]] %>% .[2] %>% as.numeric()
jobcount <- 50 # this is the total number of jobs in the slurm array to cover the whole database, specified in the header of 04_coverage_sigtest.cmd

print(paste0(date(), " processing input file: ",as.character(job_id)))

# create output directory if it doesn't exist already
dir.create(file.path(outputdir), showWarnings = FALSE)

# determine rows to compute depending on job_id
chunk_size <- ceiling(dbsize / jobcount)
start <- (job_id - 1) * chunk_size + 1
end   <- min(job_id * chunk_size, dbsize)

print(paste0(date(), " processing rows ", start, " to ", end ))
con <- DBI::dbConnect(RSQLite::SQLite(), dbname = paste(inputdir, "coverages.db", sep=""), flags=SQLITE_RO)
query <- sprintf("SELECT * FROM t1 WHERE ROWID BETWEEN %d AND %d", start, end)
x <- dbGetQuery(con, query) %>% as_tibble()
DBI::dbDisconnect(con)
dt <- x %>%mutate(avg_f = rowMeans(select(x, starts_with("f_")), na.rm = TRUE), avg_m = rowMeans(select(x, starts_with("m_")), na.rm = TRUE))

print("applying refsex filter...")
exp_less <- ""
exp_more <- ""

if (refsex=="male") {
	dt <- dt %>% filter(avg_f <= avg_m); exp_less <- "f_"; exp_more <- "m_"
} else if (refsex=="female") {
	dt <- dt %>% filter(avg_f >= avg_m); exp_less <- "m_"; exp_more <- "f_"
}

print("calculating tests...")
# the depths in a window are not always normally distributed (see README), so we use wilcox.test(); also filter out insignificant windows
dt <- dt %>% rowwise() %>% mutate(pval = wilcox.test(c_across(starts_with(exp_more)), c_across(starts_with(exp_less)), alternative="greater")$p.value) %>% filter(pval < sigthreshold)

print("Writing to output...")
dt %>% select(chr:end, avg_f, avg_m, pval) %>% write_delim(paste(outputdir,"sig_windows_",as.character(job_id),".txt",sep=""), col_names=FALSE, delim="\t")
print(paste0(date(), " done"))
