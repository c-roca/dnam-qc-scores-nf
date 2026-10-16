#!/usr/bin/env Rscript
# ============================================================================
# CM-Score (Glaser et al. 2024), vectorizado sobre la matriz probe x muestra.
# Corre sobre la beta matrix final, ya filtrada.
#
# Uso:
#   Rscript cm_score.R <beta.rds> <stable_loci_file> <out_csv>
# ============================================================================

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 3) stop("Uso: cm_score.R <beta.rds> <stable_loci_file> <out_csv>")
beta_rds         <- args[1]
stable_loci_file <- args[2]
out_csv          <- args[3]

suppressPackageStartupMessages({
  library(data.table)
  library(matrixStats)
})

beta <- readRDS(beta_rds)

message("== CM-Score ==")
stableloci <- data.table::fread(stable_loci_file, data.table = FALSE)
common <- intersect(stableloci$TargetID, rownames(beta))
if (length(common) == 0) stop("CM-Score: ningun locus estable presente en la beta matrix.")

sl   <- stableloci[match(common, stableloci$TargetID), ]
bsub <- beta[common, , drop = FALSE]

is_high <- sl$Type == "high"
is_low  <- sl$Type == "low"
n_high  <- sum(is_high)
n_low   <- sum(is_low)

high_good <- matrixStats::colSums2(bsub[is_high, , drop = FALSE] > 0.9, na.rm = TRUE)
low_good  <- matrixStats::colSums2(bsub[is_low,  , drop = FALSE] < 0.1, na.rm = TRUE)

cm_high <- round(100 - (high_good / n_high) * 100, 2)
cm_low  <- round(100 - (low_good  / n_low)  * 100, 2)
cm_diff <- abs(cm_high - cm_low)

tab <- data.frame(Sample = colnames(beta), CM.Score.high = cm_high,
                  CM.Score.low = cm_low, CM.Score.diff = cm_diff)
write.csv(tab, out_csv, row.names = FALSE)
message("CM-Score guardado en: ", out_csv, " (cutoff sugerido en el paper: high/low/diff < 20%)")
