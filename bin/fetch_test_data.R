#!/usr/bin/env Rscript
# ============================================================================
# Fetches a tiny, legitimately public IDAT test set from Bioconductor's own
# minfi test-data packages -- minfiData for 450K, minfiDataEPIC for EPIC --
# and emits them as a samplesheet + idat/ directory in the layout this
# pipeline expects. This is what -profile test uses by default so that
# `nextflow run . -profile test,docker` works out of the box for anyone,
# with no private IDATs required.
#
# There is currently no equivalent small public minfi test package for
# EPICv2, so that array type is not covered here -- supply your own
# test_data/samplesheet_test.csv (see test_data/README.md) to test EPICv2.
#
# Usage: fetch_test_data.R <450K|EPIC> <out_samplesheet.csv> <out_idat_dir>
# ============================================================================

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 3) {
  stop("Usage: fetch_test_data.R <450K|EPIC> <out_samplesheet.csv> <out_idat_dir>")
}
array_type   <- args[1]
out_csv      <- args[2]
out_idat_dir <- args[3]

pkg <- switch(array_type,
  "450K" = "minfiData",
  "EPIC" = "minfiDataEPIC",
  stop("fetch_test_data.R only knows how to fetch 450K (minfiData) or EPIC ",
       "(minfiDataEPIC) test IDATs; EPICv2 has no small public minfi test ",
       "package yet -- supply your own test_data/samplesheet_test.csv for it.")
)

if (!requireNamespace(pkg, quietly = TRUE)) {
  if (!requireNamespace("BiocManager", quietly = TRUE)) {
    install.packages("BiocManager", repos = "https://cloud.r-project.org")
  }
  BiocManager::install(pkg, update = FALSE, ask = FALSE)
}

extdata <- system.file("extdata", package = pkg)
if (!nzchar(extdata)) stop("Could not find extdata/ for package ", pkg)

suppressMessages(library(minfi))

# minfi's own helper: reads whatever SampleSheet csv the package ships and
# resolves each row's Basename to the actual IDAT files under extdata/,
# regardless of the exact subfolder layout or .idat vs .idat.gz used by that
# Bioconductor release.
targets <- read.metharray.sheet(extdata)

dir.create(out_idat_dir, recursive = TRUE, showWarnings = FALSE)

grn_dst <- character(nrow(targets))
red_dst <- character(nrow(targets))
for (i in seq_len(nrow(targets))) {
  base    <- targets$Basename[i]
  grn_src <- paste0(base, "_Grn.idat")
  red_src <- paste0(base, "_Red.idat")
  if (!file.exists(grn_src) && file.exists(paste0(grn_src, ".gz"))) grn_src <- paste0(grn_src, ".gz")
  if (!file.exists(red_src) && file.exists(paste0(red_src, ".gz"))) red_src <- paste0(red_src, ".gz")
  if (!file.exists(grn_src) || !file.exists(red_src)) {
    stop("Could not locate IDATs for ", targets$Sample_Name[i], " (", base, ") in ", pkg)
  }
  grn_dst[i] <- file.path(out_idat_dir, basename(grn_src))
  red_dst[i] <- file.path(out_idat_dir, basename(red_src))
  file.copy(grn_src, grn_dst[i], overwrite = TRUE)
  file.copy(red_src, red_dst[i], overwrite = TRUE)
}

sample_group <- if ("Sample_Group" %in% colnames(targets)) {
  as.character(targets$Sample_Group)
} else {
  rep(pkg, nrow(targets))
}

out <- data.frame(
  sample       = as.character(targets$Sample_Name),
  array_type   = array_type,
  sample_group = sample_group,
  tissue_type  = "",
  idat_grn     = normalizePath(grn_dst),
  idat_red     = normalizePath(red_dst),
  stringsAsFactors = FALSE
)

write.csv(out, out_csv, row.names = FALSE, na = "")
message(nrow(out), " test sample(s) for ", array_type, " fetched from ", pkg,
        " (groups: ", paste(unique(sample_group), collapse = ", "), ")")
if (length(unique(sample_group)) < 2) {
  message("NOTE: ", pkg, " has a single sample group, so BIN_SCORE's control ",
          "vs. case contrast will come out empty for this array -- that's ",
          "documented pipeline behaviour, not a bug (see README).")
}
