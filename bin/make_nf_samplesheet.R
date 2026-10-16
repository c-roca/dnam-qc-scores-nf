#!/usr/bin/env Rscript
# ============================================================================
# Utilidad (NO es un process de Nextflow, se corre a mano una vez): convierte
# un targets CSV "al viejo estilo" (con Basename apuntando a .../<Sentrix>_
# <Position>, como 01_targets_final_paperWDSLCT.csv) en el samplesheet
# maestro que espera este pipeline:
#
#   sample,array_type,sample_group,tissue_type,idat_grn,idat_red
#
# donde idat_grn/idat_red son RUTAS ABSOLUTAS a los .idat (o .idat.gz) de
# cada muestra. No copia ni mueve ningun archivo -- solo localiza y lista.
#
# Uso:
#   Rscript make_nf_samplesheet.R <targets.csv> <out_samplesheet.csv>
#
# Columnas esperadas en <targets.csv> (mismas que usaba
# prepare_idats_and_samplesheets.R): Array_Type, Basename, Sample_Name, y
# opcionalmente Sample_Group / Tissue_Type.
# ============================================================================

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2) stop("Uso: make_nf_samplesheet.R <targets.csv> <out_samplesheet.csv>")
targets_csv <- args[1]
out_csv     <- args[2]

targets <- read.csv(targets_csv, stringsAsFactors = FALSE, check.names = FALSE)

normalize_array_type <- function(x) {
  x_low <- tolower(trimws(x))
  if (x_low == "450k") return("450K")
  if (x_low %in% c("epic", "epicv1", "epic_v1")) return("EPIC")
  if (x_low %in% c("epic_v2", "epicv2")) return("EPIC_V2")
  NA_character_
}
targets$array_type <- vapply(targets$Array_Type, normalize_array_type, character(1))
bad <- is.na(targets$array_type)
if (any(bad)) {
  warning(sum(bad), " fila(s) con Array_Type no reconocido, se excluyen: ",
          paste(unique(targets$Array_Type[bad]), collapse = ", "))
  targets <- targets[!bad, , drop = FALSE]
}

found <- logical(nrow(targets))
idat_grn <- character(nrow(targets))
idat_red <- character(nrow(targets))

for (i in seq_len(nrow(targets))) {
  old_base <- targets$Basename[i]
  grn_src  <- paste0(old_base, "_Grn.idat")
  red_src  <- paste0(old_base, "_Red.idat")
  if (!file.exists(grn_src) && file.exists(paste0(grn_src, ".gz"))) grn_src <- paste0(grn_src, ".gz")
  if (!file.exists(red_src) && file.exists(paste0(red_src, ".gz"))) red_src <- paste0(red_src, ".gz")

  has_grn <- file.exists(grn_src)
  has_red <- file.exists(red_src)
  found[i] <- has_grn && has_red
  if (found[i]) {
    idat_grn[i] <- normalizePath(grn_src, mustWork = FALSE)
    idat_red[i] <- normalizePath(red_src, mustWork = FALSE)
  } else {
    message("FALTA (", paste(c(if (!has_grn) "Grn", if (!has_red) "Red"), collapse = "+"),
            "): ", targets$Sample_Name[i], " -- ", old_base)
  }
}

message(sum(found), " / ", nrow(targets), " muestra(s) localizadas.")
targets <- targets[found, , drop = FALSE]
idat_grn <- idat_grn[found]
idat_red <- idat_red[found]

out <- data.frame(
  sample       = targets$Sample_Name,
  array_type   = targets$array_type,
  sample_group = if ("Sample_Group" %in% colnames(targets)) targets$Sample_Group else NA,
  tissue_type  = if ("Tissue_Type" %in% colnames(targets)) targets$Tissue_Type else NA,
  idat_grn     = idat_grn,
  idat_red     = idat_red,
  stringsAsFactors = FALSE
)

write.csv(out, out_csv, row.names = FALSE, na = "")
message("Samplesheet para Nextflow guardado en: ", out_csv)
