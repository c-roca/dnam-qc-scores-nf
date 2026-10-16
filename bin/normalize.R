#!/usr/bin/env Rscript
# ============================================================================
# PASO 1 de qc_scores_pipeline.R: normalizacion (equivalente a
# normalizeMeth() de Met4All).
#
# Uso:
#   Rscript normalize.R <rgset.rds> <array_type> <norm_method> <out_msetsq.rds>
# ============================================================================

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 4) {
  stop("Uso: normalize.R <rgset.rds> <array_type> <norm_method> <out_msetsq.rds>")
}
rgset_rds   <- args[1]
array_type  <- args[2]
norm_method <- args[3]
out_msetsq  <- args[4]

suppressPackageStartupMessages(library(minfi))

load_manifest <- function(array_type) {
  if (array_type == "450K") {
    library(IlluminaHumanMethylation450kmanifest)
  } else if (array_type == "EPIC") {
    library(IlluminaHumanMethylationEPICmanifest)
  } else if (array_type == "EPIC_V2") {
    library(IlluminaHumanMethylationEPICv2manifest)
  } else {
    stop("array_type debe ser '450K', 'EPIC' o 'EPIC_V2'")
  }
}
load_manifest(array_type)

rgSet <- readRDS(rgset_rds)

message("== Paso 1: normalizacion (", norm_method, ") ==")
normalizeMeth <- function(rgSet, norm_method) {
  method <- tolower(norm_method)
  switch(method,
    ssnoob   = minfi::preprocessNoob(rgSet),
    raw      = minfi::preprocessRaw(rgSet),
    illumina = minfi::preprocessIllumina(rgSet),
    quantile = minfi::preprocessQuantile(rgSet),
    funnorm  = minfi::preprocessFunnorm(rgSet),
    stop("norm_method desconocido: ", method))
}
mSetSq <- normalizeMeth(rgSet, norm_method)

saveRDS(mSetSq, out_msetsq)
message("OK: ", out_msetsq, " (", nrow(mSetSq), " sondas x ", ncol(mSetSq), " muestras)")
