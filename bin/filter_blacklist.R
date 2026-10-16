#!/usr/bin/env Rscript
# ============================================================================
# PASO 3 de qc_scores_pipeline.R: filtrado de sondas por blacklist
# (SNP / cross-hyb / XY) -- equivalente a filterProbes() de Met4All.
#
# Uso:
#   Rscript filter_blacklist.R <msetsq.rds> <filter_dir> <out_msetsq_flt.rds>
#
# filter_dir debe contener las 4 listas que usa Met4All en
# shiny/app/common_files/filter/:
#   amb_3965probes.vh20151030.txt
#   epicV1B2_32260probes.vh20160325.txt
#   snp_7998probes.vh20151030.txt
#   xy_11551probes.vh20151030.txt
# ============================================================================

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 3) {
  stop("Uso: filter_blacklist.R <msetsq.rds> <filter_dir> <out_msetsq_flt.rds>")
}
msetsq_rds <- args[1]
filter_dir <- args[2]
out_msetsq <- args[3]

suppressPackageStartupMessages(library(minfi))

mSetSq <- readRDS(msetsq_rds)

message("== Paso 3: filtrado de sondas por blacklist (SNP / cross-hyb / XY) ==")
filterProbes <- function(mSetSq, filter_dir) {
  readFilt <- function(fname) read.table(file.path(filter_dir, fname), header = FALSE)[, 1]
  blacklist <- unique(c(
    readFilt("amb_3965probes.vh20151030.txt"),
    readFilt("epicV1B2_32260probes.vh20160325.txt"),
    readFilt("snp_7998probes.vh20151030.txt"),
    readFilt("xy_11551probes.vh20151030.txt")
  ))
  rs <- grep("rs", rownames(mSetSq), value = TRUE)
  ch <- grep("ch", rownames(mSetSq), value = TRUE)
  remove <- unique(c(blacklist, rs, ch))
  keep <- !rownames(mSetSq) %in% remove
  message("Filtrado por blacklist: fuera ", sum(!keep), ", dentro ", sum(keep))
  mSetSq[keep, ]
}
mSetSq_flt <- filterProbes(mSetSq, filter_dir)

saveRDS(mSetSq_flt, out_msetsq)
message("OK: ", out_msetsq, " (", nrow(mSetSq_flt), " sondas restantes)")
