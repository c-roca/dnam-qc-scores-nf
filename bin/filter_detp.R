#!/usr/bin/env Rscript
# ============================================================================
# PASO 2 de qc_scores_pipeline.R: filtrado de sondas por deteccion-p
# (equivalente a filterDetectionP() de Met4All).
#
# Uso:
#   Rscript filter_detp.R <msetsq.rds> <detp.rds> <detp_threshold> <out_msetsq.rds>
# ============================================================================

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 4) {
  stop("Uso: filter_detp.R <msetsq.rds> <detp.rds> <detp_threshold> <out_msetsq.rds>")
}
msetsq_rds     <- args[1]
detp_rds       <- args[2]
detp_threshold <- as.numeric(args[3])
out_msetsq     <- args[4]

suppressPackageStartupMessages({
  library(minfi)
  library(matrixStats)
})

mSetSq <- readRDS(msetsq_rds)
detP   <- readRDS(detp_rds)

message("== Paso 2: filtrado de sondas por deteccion-p ==")
filterDetectionP <- function(detP, mSetSq, threshold) {
  detP <- detP[match(minfi::featureNames(mSetSq), rownames(detP)), ]
  keep <- matrixStats::rowMaxs(detP, na.rm = TRUE) < threshold
  message("Sondas fuera: ", sum(!keep), " | dentro: ", sum(keep))
  mSetSq[keep, ]
}
mSetSq <- filterDetectionP(detP, mSetSq, detp_threshold)

saveRDS(mSetSq, out_msetsq)
message("OK: ", out_msetsq, " (", nrow(mSetSq), " sondas restantes)")
