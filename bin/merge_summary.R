#!/usr/bin/env Rscript
# ============================================================================
# Resumen final: merge de DB-Score + CM-Score + BIN-Score (si existe) por
# muestra, igual que la seccion 6 de qc_scores_pipeline.R.
#
# Uso:
#   Rscript merge_summary.R <db.csv> <cm.csv> <bin.csv> <array_type> <out_csv>
#
# <bin.csv> puede ser un CSV vacio (solo cabecera Sample,BIN-Score) -- en ese
# caso el merge simplemente no añade esa columna con datos, igual que cuando
# bin_score() devolvia NULL en el script original.
# ============================================================================

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 5) {
  stop("Uso: merge_summary.R <db.csv> <cm.csv> <bin.csv> <array_type> <out_csv>")
}
db_csv     <- args[1]
cm_csv     <- args[2]
bin_csv    <- args[3]
array_type <- args[4]
out_csv    <- args[5]

db_scores  <- read.csv(db_csv, stringsAsFactors = FALSE, check.names = FALSE)
cm_scores  <- read.csv(cm_csv, stringsAsFactors = FALSE, check.names = FALSE)
bin_scores <- read.csv(bin_csv, stringsAsFactors = FALSE, check.names = FALSE)

tabs <- list(db_scores, cm_scores)
if (nrow(bin_scores) > 0) tabs <- c(tabs, list(bin_scores))

message("\n== Resumen QC-Scores (", array_type, ") ==")
summary_tab <- Reduce(function(x, y) merge(x, y, by = "Sample", all = TRUE), tabs)
print(summary_tab)
write.csv(summary_tab, out_csv, row.names = FALSE)

message("\nListo: ", out_csv)
message("Cutoffs sugeridos (no son umbrales biologicos, son heuristicas del paper):")
message("  DB-Score            < 1")
message("  BIN-Score            < 0.25")
message("  CM-Score high/low   < 20%")
message("  CM-Score diff       < 20%")
