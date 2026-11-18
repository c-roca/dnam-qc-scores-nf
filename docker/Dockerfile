# ============================================================================
# Image for qc-scores-nf -- a Nextflow pipeline that computes DB-Score,
# BIN-Score and CM-Score (Glaser et al. 2024) from 450K/EPIC/EPICv2 IDATs,
# following the same processing Met4All (minfi) uses up to the beta matrix.
#
# Own image (does not reuse Met4All's): it only brings what this pipeline
# needs.
# ============================================================================
FROM bioconductor/bioconductor_docker:RELEASE_3_19

LABEL org.opencontainers.image.source="https://github.com/c-roca/dnam-qc-scores-nf" \
      org.opencontainers.image.description="DB-Score / BIN-Score / CM-Score for DNA methylation IDATs (minfi + conumee2)"

# System packages some R build dependencies need
RUN apt-get update && apt-get install -y --no-install-recommends \
        libcurl4-openssl-dev \
        libssl-dev \
        libxml2-dev \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# CRAN packages
RUN R -e "install.packages(c('data.table', 'dplyr', 'matrixStats', 'ggplot2', 'plotly', 'remotes', 'BiocManager'), repos = 'https://cloud.r-project.org')"

# Bioconductor packages -- version pinned by the base image (Bioconductor 3.19)
RUN R -e "BiocManager::install(c( \
        'minfi', \
        'limma', \
        'DMRcate', \
        'DMRcatedata', \
        'IlluminaHumanMethylation450kmanifest', \
        'IlluminaHumanMethylation450kanno.ilmn12.hg19', \
        'IlluminaHumanMethylationEPICmanifest', \
        'IlluminaHumanMethylationEPICanno.ilm10b4.hg19', \
        'IlluminaHumanMethylationEPICv2manifest', \
        'IlluminaHumanMethylationEPICv2anno.20a1.hg38' \
    ), update = FALSE, ask = FALSE)"

# conumee2 is not on Bioconductor -- install it from GitHub (hovestadtlab/conumee2)
RUN R -e "remotes::install_github('hovestadtlab/conumee2/conumee2', upgrade = 'never')"

# Quick sanity check that everything loads at build time (fail the build now,
# not three hours into a real run, if something isn't installed correctly)
RUN R -e "library(minfi); library(data.table); library(dplyr); library(matrixStats); \
          library(DMRcate); library(limma); library(conumee2); library(ggplot2); \
          library(IlluminaHumanMethylationEPICv2anno.20a1.hg38); \
          message('OK: all libraries load correctly')"

WORKDIR /data
