#!/usr/bin/env Rscript
# ============================================================================
# Lee un sample sheet "local" (idat_grn/idat_red ya estan en el cwd del
# process, simlinkeados ahi por Nextflow) y construye el RGChannelSet +
# deteccion-p para un array_type. Equivalente a la seccion 2-3 de
# qc_scores_pipeline.R.
#
# Uso:
#   Rscript read_rgset.R <samplesheet.csv> <array_type> <out_rgset.rds> \
#           <out_detp.rds> <out_targets.rds> <out_qcreport.pdf>
#
# samplesheet.csv (columnas minimas, generadas por main.nf a partir del
# samplesheet maestro del usuario):
#   sample, array_type, sample_group, tissue_type, idat_grn, idat_red
# idat_grn / idat_red son los NOMBRES LOCALES de los .idat (o .idat.gz) ya
# presentes en el directorio de trabajo del process -- Nextflow los stagea
# ahi (symlink) independientemente de donde vivan en la maquina del host o
# si el process corre en un contenedor Docker/Singularity.
# ============================================================================

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 6) {
  stop("Uso: read_rgset.R <samplesheet.csv> <array_type> <out_rgset.rds> ",
       "<out_detp.rds> <out_targets.rds> <out_qcreport.pdf>")
}
samplesheet_csv <- args[1]
array_type      <- args[2]
out_rgset       <- args[3]
out_detp        <- args[4]
out_targets     <- args[5]
out_qcreport    <- args[6]

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

message("== Leyendo sample sheet local (", array_type, ") ==")
targets <- read.csv(samplesheet_csv, stringsAsFactors = FALSE, check.names = FALSE)
if (nrow(targets) == 0) stop("Sample sheet vacio: ", samplesheet_csv)
for (col in c("sample", "idat_grn", "idat_red")) {
  if (!col %in% colnames(targets)) stop("Falta columna '", col, "' en ", samplesheet_csv)
}

# Basename = nombre local sin el sufijo _Grn.idat[.gz] -- los .idat ya estan
# en el cwd del process (staged por Nextflow), asi que read.metharray.exp()
# se llama con base = "." y recursive = FALSE.
strip_grn_suffix <- function(x) sub("_Grn\\.idat(\\.gz)?$", "", x)
targets$Basename <- strip_grn_suffix(basename(targets$idat_grn))

if (anyDuplicated(targets$Basename)) {
  dup <- unique(targets$Basename[duplicated(targets$Basename) | duplicated(targets$Basename, fromLast = TRUE)])
  stop("Basename duplicado en el sample sheet (", length(dup), " valor(es)):\n  ",
       paste(dup, collapse = "\n  "))
}

targets$Sample_Name  <- targets$sample
targets$Sample_Group <- if ("sample_group" %in% colnames(targets)) targets$sample_group else NA
targets$Tissue_Type  <- if ("tissue_type" %in% colnames(targets)) targets$tissue_type else NA

targets$ID <- if (!all(is.na(targets$Sample_Group))) {
  paste(targets$Sample_Group, targets$Sample_Name, sep = "_")
} else {
  targets$Sample_Name
}

rgSet <- minfi::read.metharray.exp(base = ".", targets = targets,
                                    force = TRUE, extended = FALSE, recursive = FALSE)
minfi::sampleNames(rgSet) <- targets$ID

message("Muestras leidas: ", ncol(rgSet))

message("== Calculando p-valores de deteccion ==")
detP <- minfi::detectionP(rgSet, type = "m+u")

message("== QC report (minfi) ==")
minfi::qcReport(rgSet, sampNames = targets$Sample_Name,
                sampGroups = if (!all(is.na(targets$Sample_Group))) targets$Sample_Group else NULL,
                pdf = out_qcreport)

saveRDS(rgSet, out_rgset)
saveRDS(detP, out_detp)
saveRDS(targets, out_targets)
message("OK: ", out_rgset, " / ", out_detp, " / ", out_targets, " / ", out_qcreport)
