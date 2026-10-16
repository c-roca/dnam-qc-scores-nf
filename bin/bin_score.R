#!/usr/bin/env Rscript
# ============================================================================
# BIN-Score (Glaser et al. 2024, portado a conumee2). Corre sobre
# mSetSq_flt (intensidades Meth/Unmeth), ANTES de calcular la beta matrix.
#
# Incluye los 3 fixes verificados contra datos reales (ver comentarios):
#   1. CNV.fit() necesita indices NUMERICOS, no vectores de nombres.
#   2. anno@probes debe recortarse a las sondas que sigan en mset tras los
#      filtros de deteccion-p/blacklist, si no CNV.fit() falla con
#      "query intensities not given for all probes".
#   3. CNV.bin() puede dejar bins con varianza NA/0 tras ese recorte; hay que
#      quitarlos antes de CNV.segment() o DNAcopy::segment() revienta con
#      "all weights should be positive".
#   4. CNV.write(x, what = "segments") devuelve una LISTA (una por muestra
#      del query), no un data.frame -- hay que indexar [[1]].
#
# Si no hay muestras de referencia, o no hay ninguna muestra caso con la que
# comparar (p.ej. un array donde todas las muestras son "Normal"), el script
# escribe un CSV vacio con las columnas correctas (Sample, BIN-Score) y
# termina sin error -- asi el merge final no se rompe.
#
# Uso:
#   Rscript bin_score.R <msetsq_flt.rds> <array_type> <control_pattern> \
#           <qc_resources_dir> <out_csv>
#
# qc_resources_dir debe contener Bin_positions_450k.txt / Bin_positions_EPIC.txt
# (del repo GlaserSe/DNAm-qc-scores). No hay tabla de bins para EPIC_V2 en el
# paper original -- para ese array_type el score se salta siempre.
# ============================================================================

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 5) {
  stop("Uso: bin_score.R <msetsq_flt.rds> <array_type> <control_pattern> ",
       "<qc_resources_dir> <out_csv>")
}
msetsq_rds       <- args[1]
array_type       <- args[2]
control_pattern  <- args[3]
qc_resources_dir <- args[4]
out_csv          <- args[5]

suppressPackageStartupMessages({
  library(minfi)
  library(data.table)
  library(conumee2)
})

write_empty <- function(out_csv) {
  bin_table <- data.frame(Sample = character(0), `BIN-Score` = numeric(0), check.names = FALSE)
  write.csv(bin_table, out_csv, row.names = FALSE)
  invisible(bin_table)
}

mset <- readRDS(msetsq_rds)

message("== BIN-Score (", array_type, ") ==")

ref_idx <- grep(control_pattern, colnames(mset), ignore.case = TRUE)
if (length(ref_idx) == 0 && "Sample_Group" %in% colnames(minfi::pData(mset))) {
  ref_idx <- grep(control_pattern, minfi::pData(mset)$Sample_Group, ignore.case = TRUE)
}
if (length(ref_idx) == 0) {
  warning("BIN-Score: ninguna muestra coincide con control_pattern = '",
          control_pattern, "'. Se salta este score.")
  write_empty(out_csv)
  quit(save = "no", status = 0)
}

conumee_array <- switch(array_type,
                        "450K" = "450k", "EPIC" = "EPIC", "EPIC_V2" = "EPICv2")
bin_file <- file.path(qc_resources_dir, sprintf("Bin_positions_%s.txt",
                      if (array_type == "450K") "450k" else "EPIC"))
if (!file.exists(bin_file)) {
  warning("BIN-Score: no encuentro ", bin_file, " (EPIC_V2 no trae tabla en el paper). Se salta.")
  write_empty(out_csv)
  quit(save = "no", status = 0)
}
bin_positions <- data.table::fread(bin_file, data.table = FALSE)

anno <- conumee2::CNV.create_anno(array_type = conumee_array, chrXY = TRUE)

probes_mset   <- minfi::featureNames(mset)
probes_anno   <- names(anno@probes)
common_probes <- probes_anno %in% probes_mset
message("BIN-Score: recortando anotacion a sondas comunes: ",
        sum(common_probes), " / ", length(probes_anno))
anno@probes <- anno@probes[common_probes]

data_cnv <- conumee2::CNV.load(mset)
case_idx <- setdiff(seq_len(ncol(mset)), ref_idx)
if (length(case_idx) == 0) {
  warning("BIN-Score: todas las muestras coinciden con control_pattern = '",
          control_pattern, "' (no hay ninguna muestra caso con la que comparar). ",
          "Se salta este score para ", array_type, ".")
  write_empty(out_csv)
  quit(save = "no", status = 0)
}

scores <- list()

for (i in case_idx) {
  s <- colnames(mset)[i]
  x <- conumee2::CNV.fit(data_cnv[i], data_cnv[ref_idx], anno)
  x <- conumee2::CNV.detail(conumee2::CNV.bin(x))

  var1 <- x@bin$variance[[1]]
  bad_bins <- is.na(var1) | var1 <= 0
  if (any(bad_bins)) {
    x@bin$ratio[[1]]    <- x@bin$ratio[[1]][!bad_bins]
    x@bin$variance[[1]] <- x@bin$variance[[1]][!bad_bins]
    x@anno@bins         <- x@anno@bins[!bad_bins]
  }

  x <- conumee2::CNV.segment(x)

  bin <- conumee2::CNV.write(x, what = "bins")
  bin_val <- as.numeric(bin[, 5])

  segment <- conumee2::CNV.write(x, what = "segments")[[1]]
  seg_df <- segment[order(segment$chrom), c("num.mark", "seg.median")]

  seg_median_per_bin <- rep(seg_df$seg.median, seg_df$num.mark)
  if (length(seg_median_per_bin) != length(bin_val)) {
    warning("BIN-Score: desajuste bins/segmentos para ", s, "; muestra saltada.")
    next
  }

  diff_vals <- bin_val - seg_median_per_bin
  scores[[s]] <- median(abs(diff_vals), na.rm = TRUE)
}

bin_table <- data.frame(
  Sample = if (length(scores)) names(scores) else character(0),
  `BIN-Score` = if (length(scores)) unlist(scores) else numeric(0),
  check.names = FALSE)
write.csv(bin_table, out_csv, row.names = FALSE)
message("BIN-Score guardado en: ", out_csv, " (cutoff sugerido en el paper: < 0.25)")
