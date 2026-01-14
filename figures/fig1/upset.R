#!/usr/bin/env Rscript
# input defined below

library(UpSetR)

process_annotation <- function(input, targets) {
  valid_targets <- setdiff(targets, input)
  
  gene_sets <- list()
  
  # Read input annotation file
  input_file <- paste0("data/upset_data/",input, "_annotation_list_genes.renamed.txt")
  cat("Reading input file:", input_file, "\n")
  gene_sets[[input]] <- readLines(input_file)
  cat("Loaded", length(gene_sets[[input]]), "genes from", input_file, "\n")
  
  # Read comparison files
  for (target in valid_targets) {
    file <- paste0("data/upset_data/","sorted_", input, "_vs_", target, "_mapped.genes.list.txt")
    key <- target
    cat("Reading comparison file:", file, "\n")
    gene_sets[[key]] <- readLines(file)
    cat("Loaded", length(gene_sets[[key]]), "genes from", file, "\n")
  }
  
  # Create binary matrix
  binary_matrix <- fromList(gene_sets)
  names(binary_matrix)[names(binary_matrix) == 'f1'] <- 'B236-h1'
  names(binary_matrix)[names(binary_matrix) == 'f2'] <- 'B236-h2'
  names(binary_matrix)[names(binary_matrix) == 'm1'] <- 'B346-h1'
  names(binary_matrix)[names(binary_matrix) == 'm2'] <- 'B346-h2'
  
  # Plot regular scale
  pdf(paste0("results/upset/",input,"upset_1.pdf"), width = 6, height = 3, compress = FALSE)
  print(upset(binary_matrix, sets = c("B236-h1", "B236-h2", "B346-h1", "B346-h2"), order.by = "freq"))
  dev.off()

  pdf(paste0("results/upset/",input,"upset_2.pdf"), width = 6, height = 3, compress = FALSE)
  print(upset(binary_matrix, sets = c("B236-h1", "B236-h2", "B346-h1", "B346-h2"), order.by = "freq", mainbar.y.max = 1000))
  dev.off()

}

annotations <- c("f1")
targets <- c("f1", "f2", "m1", "m2")

for (input in annotations) {
  process_annotation(input, targets)
}

