#!/usr/bin/env Rscript
# ============================================================================
# PASO 4 + 5 de qc_scores_pipeline.R: ajuste FFPE/Frozen, calculo de beta, y
# filtrado final SNP/XY/cross-hyb sobre la beta matrix (DMRcate::rmSNPandCH).
# Equivalente a adjustFFPE() + finalizeBeta() de Met4All.
#
# Uso:
#   Rscript calc_beta.R <msetsq_flt.rds> <array_type> <out_beta.rds> <out_beta.csv>
# ============================================================================

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 4) {
  stop("Uso: calc_beta.R <msetsq_flt.rds> <array_type> <out_beta.rds> <out_beta.csv>")
}
msetsq_rds <- args[1]
array_type <- args[2]
out_rds    <- args[3]
out_csv    <- args[4]

suppressPackageStartupMessages({
  library(minfi)
  library(limma)
  library(DMRcate)
  library(IlluminaHumanMethylationEPICv2anno.20a1.hg38)
})

mSetSq_flt <- readRDS(msetsq_rds)

message("== Paso 4: ajuste FFPE/Frozen + calculo de beta ==")
tissue_type <- if ("Tissue_Type" %in% colnames(minfi::pData(mSetSq_flt))) {
  minfi::pData(mSetSq_flt)$Tissue_Type
} else NULL

adjustFFPE <- function(methy, unmethy, tissue_type) {
  if (is.null(tissue_type) || length(unique(tissue_type)) == 1) {
    message("Sin ajuste FFPE/Frozen (una sola condicion o no especificada).")
    return(methy / (methy + unmethy + 100))
  }
  message("Ajustando por tipo de tejido FFPE/Frozen...")
  batch <- ifelse(tissue_type == "FFPE", 2, 1)
  methy.ba   <- 2^limma::removeBatchEffect(log2(methy + 1), batch)
  unmethy.ba <- 2^limma::removeBatchEffect(log2(unmethy + 1), batch)
  methy.ba / (methy.ba + unmethy.ba + 100)
}

meth   <- minfi::getMeth(mSetSq_flt)
unmeth <- minfi::getUnmeth(mSetSq_flt)
beta   <- adjustFFPE(meth, unmeth, tissue_type)

message("== Paso 5: filtrado final SNP/XY/cross-hyb ==")
beta <- aggregate_to_probes(beta)   # colapsa replicas EPICv2 a 1 fila/CpG
beta <- DMRcate::rmSNPandCH(beta, dist = 2, mafcut = 0.05, rmXY = TRUE, rmcrosshyb = TRUE)

saveRDS(beta, out_rds)
write.csv(beta, out_csv)
message("Beta matrix final: ", nrow(beta), " sondas x ", ncol(beta),
        " muestras -> ", out_rds)
