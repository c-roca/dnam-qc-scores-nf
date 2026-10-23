# ============================================================================
# Imagen para qc-scores-nf -- pipeline Nextflow que calcula DB-Score,
# BIN-Score y CM-Score (Glaser et al. 2024) sobre IDATs 450K/EPIC/EPICv2,
# siguiendo el procesamiento de Met4All (minfi) hasta la beta matrix.
#
# Imagen propia (no reutiliza la de Met4All): solo trae lo que este pipeline
# necesita.
# ============================================================================
FROM bioconductor/bioconductor_docker:RELEASE_3_19

LABEL org.opencontainers.image.source="https://github.com/<TU_USUARIO>/dnam-qc-scores-nf" \
      org.opencontainers.image.description="DB-Score / BIN-Score / CM-Score para IDATs de metilacion (minfi + conumee2)"

# Paquetes de sistema que necesitan algunas dependencias de compilacion de R
RUN apt-get update && apt-get install -y --no-install-recommends \
        libcurl4-openssl-dev \
        libssl-dev \
        libxml2-dev \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Paquetes CRAN
RUN R -e "install.packages(c('data.table', 'dplyr', 'matrixStats', 'ggplot2', 'plotly', 'remotes', 'BiocManager'), repos = 'https://cloud.r-project.org')"

# Paquetes Bioconductor -- version fijada por la imagen base (Bioconductor 3.19)
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

# conumee2 no esta en Bioconductor -- se instala desde GitHub (hovestadtlab/conumee2)
RUN R -e "remotes::install_github('hovestadtlab/conumee2/conumee2', upgrade = 'never')"

# Verificacion rapida de que todo carga en el momento de build (falla el
# build, no una corrida de 3 horas despues, si algo no esta bien instalado)
RUN R -e "library(minfi); library(data.table); library(dplyr); library(matrixStats); \
          library(DMRcate); library(limma); library(conumee2); library(ggplot2); \
          library(IlluminaHumanMethylationEPICv2anno.20a1.hg38); \
          message('OK: todas las librerias cargan correctamente')"

WORKDIR /data
