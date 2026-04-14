#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

# Define packages to load
packages = c("tidyverse","data.table","viridis")

package.check <- lapply(
  packages,
  FUN = function(x) { library(x, character.only = TRUE) }
)

# get basedir from config.cfg and set dir paths
basedir <- system("grep '^BASEDIR=' config.cfg",intern=TRUE) %>% str_split(., "=") %>% .[[1]] %>% .[2]

# arguments: 1 - target file; 2 (optional) - target region in format chr:start-end

# parse and process input
target_path <- paste0(basedir,args[1])
region <- if(is.na(args[2])){""}else{as.character(args[2])}
chr <- if(is.na(args[2])){""}else{region %>% str_split(":") %>% .[[1]] %>% .[1]}
start <- if(is.na(args[2])){""}else{region %>% str_split(":|-") %>% .[[1]] %>% tail(.,n=2) %>% head(.,n=1)}
end <- if(is.na(args[2])){""}else{region %>% str_split(":|-") %>% .[[1]] %>% tail(.,n=1)}
reg_str <- if(is.na(args[2])){""}else{paste("-r",region)}
filtername <- target_path %>% str_split("/") %>% .[[1]] %>% tail(.,n=1) %>% str_split("\\.") %>% .[[1]] %>% .[1]
regname <- if(is.na(args[2])){""}else{paste0("_",chr,"_",start,"_",end)}

outdir <- paste0(basedir,"results/11_vcf_stats/",filtername,regname,"/")
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

# read in vcf
qd <- system(paste0("bcftools view ", reg_str, target_path, " | awk -f ", basedir, "scripts/get_qual_by_depth.awk"),intern=TRUE) %>% as_tibble() %>% mutate(value = as.double(value))

qdplot <- ggplot(qd, aes(x=value)) +
	geom_density() +
	theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)) +
	labs(title=paste0(filtername, ": QD"), subtitle = reg_str)
ggsave(paste0("plot_QD.pdf"), qdplot, device = "pdf", width = 15, height = 9, path = file.path(outdir))

rm(qd)

# read INFO fields
dt <- fread(cmd=paste("bcftools query -H ",reg_str," -f '%CHROM %POS %ID %REF %ALT %QUAL %INFO/DP %INFO/AD %INFO/VDB %INFO/SGB %INFO/RPBZ %INFO/MQBZ %INFO/MQSBZ %INFO/BQBZ %INFO/SCBZ %INFO/FS %INFO/MQ0F %INFO/AC %INFO/AN %INFO/DP4 %INFO/MQ\n' ", target_path, sep=""), colClasses = c("character", "integer", "character","character","character","numeric","numeric","character","numeric","numeric","numeric","numeric","numeric","numeric","numeric","numeric","numeric","numeric","numeric","character","numeric"))

# calculate mode of DP distribution
d <- density(dt$`[7]DP`)
dmode <- d$x[which.max(d$y)] 
print(paste("mode of DP distribution is at", dmode))

# generate histograms from INFO fields
colnames(dt) <- colnames(dt) %>% gsub("#{0,1}\\[\\d{1,}\\]{1}","\\1",.)

dplotcols <- c("QUAL", "DP", "SGB", "RPBZ", "MQBZ", "MQSBZ", "BQBZ", "SCBZ", "FS", "MQ0F", "AN", "MQ")
dp4plotcols <- c("DP4")

for (i in dplotcols) {
	var <- i
	try(df <- dt[, ..var] %>% as_tibble())
	plot <- ggplot(df, aes(x=!! rlang::sym(i))) +
		geom_density() +
		theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)) +
		labs(title=paste0(filtername, ": ", i), subtitle = reg_str)
	ggsave(paste0("plot_",i,".pdf"), plot, device = "pdf", width = 15, height = 9, path = file.path(outdir))
}

dp4dt <- dt %>% select(DP4) %>% separate_wider_delim(DP4, delim=",", names= c("ref-for", "ref-rev", "alt-for", "alt-rev")) %>% pivot_longer(everything(),names_to= "type", values_to="count") %>% arrange(type) %>% mutate(type = as.factor(type), count = as.numeric(count)) %>% group_by(type)

for (i in dp4plotcols) {
	plot <- ggplot(dp4dt, aes(count, fill=type)) +
		geom_density() +
		theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)) +
		scale_colour_viridis_d("magma") +
		xlim(0,1000) +
		labs(title=paste0(filtername, ": ", i), subtitle = reg_str)
	ggsave(paste0("plot_",i,".pdf"), plot, device = "pdf", width = 15, height = 9, path = file.path(outdir))
}
