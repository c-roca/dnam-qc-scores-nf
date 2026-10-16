#!/usr/bin/env Rscript
# ============================================================================
# PASO 0 de qc_scores_pipeline.R: exclusion de muestras malas (detP medio >=
# umbral).
#
# Uso:
#   Rscript filter_samples.R <rgset.rds> <detp.rds> <targets.rds> \
#           <detp_threshold> <out_rgset.rds> <out_detp.rds> <out_targets.rds>
# ============================================================================

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 7) {
  stop("Uso: filter_samples.R <rgset.rds> <detp.rds> <targets.rds> ",
       "<detp_threshold> <out_rgset.rds> <out_detp.rds> <out_targets.rds>")
}
rgset_rds      <- args[1]
detp_rds       <- args[2]
targets_rds    <- args[3]
detp_threshold <- as.numeric(args[4])
out_rgset      <- args[5]
out_detp       <- args[6]
out_targets    <- args[7]

suppressPackageStartupMessages({
  library(minfi)
  library(matrixStats)
})

rgSet   <- readRDS(rgset_rds)
detP    <- readRDS(detp_rds)
targets <- readRDS(targets_rds)

mean_detP <- matrixStats::colMeans2(detP, na.rm = TRUE)
names(mean_detP) <- colnames(detP)

keep <- mean_detP < detp_threshold
message("== Paso 0: exclusion de muestras (umbral detP = ", detp_threshold, ") ==")
if (!all(keep)) {
  message("Excluidas ", sum(!keep), " muestra(s): ",
          paste(names(mean_detP)[!keep], collapse = ", "))
  detP    <- detP[, keep, drop = FALSE]
  rgSet   <- rgSet[, keep, drop = FALSE]
  targets <- targets[match(colnames(rgSet), targets$ID), , drop = FALSE]
} else {
  message("Ninguna muestra por encima del umbral.")
}

if (ncol(rgSet) == 0) stop("Paso 0: todas las muestras quedaron excluidas (umbral demasiado estricto).")

saveRDS(rgSet, out_rgset)
saveRDS(detP, out_detp)
saveRDS(targets, out_targets)
message("OK: ", ncol(rgSet), " muestra(s) tras el filtro.")
