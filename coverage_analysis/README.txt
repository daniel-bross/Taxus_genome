Coverage analysis to determine reduced coverage in a potential SDR

Note: Only uses read depth information from reads with a mapping quality of 20 or better

### Needed for step 3: Prepare databse and get number of rows in coverage.db to determine array job parameters for stat test script
set sqlite setting for the database:
sqlite3 results/02_coverages/coverages.db "PRAGMA journal_mode=WAL; PRAGMA synchronous=OFF; PRAGMA busy_timeout = 5000;"

sqlite3 results/02_coverages/coverages.db "SELECT COUNT(1) FROM t1"
fh1: 20370849


### Supplementary: Check if read depths across individuals are normally distributed (for samples with reference sex) for each window
# read coverage data 
con <- DBI::dbConnect(RSQLite::SQLite(), dbname = paste(outdir, "coverages.db", sep=""))
dt <- dbGetQuery(con, paste0("SELECT * FROM t1")) %>% as_tibble() %>% mutate(female = rowMeans(select(., starts_with("f_")), na.rm = TRUE)) %>% mutate(male = rowMeans(select(., starts_with("m_")), na.rm = TRUE))
DBI::dbDisconnect(con)
# calculate shapiro-wilk test for random subset of windows (exclude windows were every female is 0)
pval <- dt %>% slice_sample(prop = 0.001) %>% rowwise() %>% filter(sum(c_across(starts_with("f_"))) > 0) %>% mutate(p = shapiro.test(c_across(starts_with("f_")))$p.value ) %>% select(p)
# plot as histogram. If this shows a uniform distribution (multiple testing!), we would expect a normal distribution of read depths in general
pval %>% ggplot(aes(p)) + geom_histogram(binwidth=0.01) + geom_vline(xintercept=0.05)

# => many windows are < 0.05 (i.e. have read depths with no normal distributions across samples), so we use a non-parameterical test like wilcox.test()


### Supplementary: Determine range of p-values we can reasonably expect in an SDR (assuming "normal" coverage for reference homogametic sex, half coverage in heterogematic sex)
# 1. Get median of read depths, as average across samples
mat <- dt %>% select(f_1:m_50) %>% as.matrix(); storage.mode(mat) <- "integer"
avg_median <- rowMedians(mat) %>% mean()

# 2. Get mean and standard deviation of windows that have an average depth smaller than 3 times the median (i.e., excluding "anomalous"/repetitive regions)
mask <- mat > avg_median * 3; row_mask <- rowAlls(mask)
avg_means <- rowMeans2(mat, rows = which(!row_mask)) %>% mean()
avg_sd <- rowSds(mat, rows = which(!row_mask)) %>% mean()

# 3. Simulate "SDR windows" based on a normal distribution according to calculated mean and sd (with half of the mean for the heterogametic sex) and calculate wilcox.test()
sim <- c()
for (i in 1:10000) {
	set.seed(i)
	sim[i] <- wilcox.test(rnorm(50, avg_means, avg_sd), rnorm(50, avg_means / 2, avg_sd), "greater")$p.value
}
# => This distribution could also be used as a reference of what p-value can be expected in SDR regions


### Supplementary: Get windows with anomalous read depths (i.e., count those with values exceeding mean + 3 * sd)
anomalies <- dt %>% filter(if_any(f_1:m_50, ~ .x > avg_means + 3 * avg_sd))
# how many samples exceed threshold?
counts <- anomalies %>% mutate(count = rowSums(across(f_1:m_50, ~ . > avg_means + 3 * avg_sd))) %>% select(count)
counts %>% ggplot(., aes(count)) + geom_histogram(bins=100)
# => usually, it is only a few samples
