#!/usr/bin/env Rscript
# ============================================================================
# DB-Score (Glaser et al. 2024), vectorizado sobre la matriz probe x muestra.
# Corre sobre la beta matrix final, ya filtrada.
#
# Uso:
#   Rscript db_score.R <beta.rds> <out_csv>
# ============================================================================

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2) stop("Uso: db_score.R <beta.rds> <out_csv>")
beta_rds <- args[1]
out_csv  <- args[2]

suppressPackageStartupMessages(library(matrixStats))

beta <- readRDS(beta_rds)

message("== DB-Score ==")
hypo  <- matrixStats::colSums2(beta < 0.3, na.rm = TRUE)
hyper <- matrixStats::colSums2(beta > 0.7, na.rm = TRUE)
mid   <- matrixStats::colSums2(beta >= 0.3 & beta <= 0.7, na.rm = TRUE)
score <- round(mid / (hypo + hyper), 3)

tab <- data.frame(Sample = colnames(beta), `< 0.3` = hypo, mid = mid,
                  `> 0.7` = hyper, `DB-Score` = score, check.names = FALSE)
write.csv(tab, out_csv, row.names = FALSE)
message("DB-Score guardado en: ", out_csv, " (cutoff sugerido en el paper: < 1)")
