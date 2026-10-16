#!/usr/bin/env nextflow
/*
========================================================================================
    qc-scores-nf
========================================================================================
    Pipeline Nextflow (estilo nf-core, DSL2) que calcula DB-Score, BIN-Score y CM-Score
    (Glaser et al. 2024, "Navigating Illumina DNA methylation data: biology versus
    technical artefacts", NAR Genomics and Bioinformatics; repo GlaserSe/DNAm-qc-scores)
    a partir de IDATs 450K/EPIC/EPICv2, siguiendo el mismo procesamiento que usa Met4All
    (minfi) hasta obtener la beta matrix. Portado desde el script standalone
    qc_scores_pipeline.R -- ver workflows/qc_scores.nf para el mapa de pasos.
========================================================================================
*/

nextflow.enable.dsl = 2

include { QC_SCORES } from './workflows/qc_scores'

def helpMessage() {
    log.info """
    Uso:
      nextflow run . -profile docker --input samplesheet.csv --outdir results

    Parametros obligatorios:
      --input                 CSV maestro con columnas:
                               sample,array_type,sample_group,tissue_type,idat_grn,idat_red
                               (idat_grn/idat_red = rutas absolutas a los .idat o .idat.gz
                               de cada muestra; array_type = 450K | EPIC | EPIC_V2)
                               Generalo con bin/make_nf_samplesheet.R a partir de tu
                               targets CSV de siempre, si todavia no lo tienes en este
                               formato.

    Parametros opcionales (con su valor por defecto):
      --outdir                 "results"
      --norm_method             "ssnoob"      (ssnoob|raw|illumina|quantile|funnorm)
      --detp_threshold          0.05
      --control_pattern         "Normal"      (substring en sample/sample_group para el BIN-Score)
      --qc_resources_dir        "assets/qc_resources"  (filter/*.txt, Bin_positions_*.txt, Stable_loci.txt)

    Perfiles:
      -profile docker           corre todos los procesos en el contenedor de docker/Dockerfile
      -profile test,docker      corre contra el subset pequeno de test_data/ (ver conf/test.config)
    """.stripIndent()
}

if (params.help) {
    helpMessage()
    exit 0
}

if (!params.input) {
    helpMessage()
    error "Falta --input <samplesheet.csv>. Ver 'nextflow run . --help'."
}

workflow {

    // --------------------------------------------------------------------
    // 1. Leer el samplesheet maestro y agrupar filas por array_type.
    // --------------------------------------------------------------------
    ch_rows = Channel
        .fromPath(params.input, checkIfExists: true)
        .splitCsv(header: true)
        .map { row ->
            if (!row.idat_grn || !row.idat_red) {
                error "Fila sin idat_grn/idat_red en ${params.input}: ${row}"
            }
            if (!(row.array_type in ['450K', 'EPIC', 'EPIC_V2'])) {
                error "array_type debe ser 450K, EPIC o EPIC_V2 (fila: ${row})"
            }
            tuple(row.array_type, row)
        }
        .groupTuple()

    // --------------------------------------------------------------------
    // 2. Por cada array_type: generar un samplesheet "local" (con los
    //    nombres de fichero .idat tal y como los vera el process, no la
    //    ruta absoluta del host) + la lista de ficheros .idat a stagear.
    //    Nextflow symlinkea cada path() declarado como input al directorio
    //    de trabajo del process, asi que read_rgset.R siempre los encuentra
    //    en el cwd independientemente de donde vivan en el host o si el
    //    process corre dentro de Docker/Singularity.
    // --------------------------------------------------------------------
    ch_input = ch_rows.map { array_type, rows ->
        def idat_files = []
        def lines = ["sample,array_type,sample_group,tissue_type,idat_grn,idat_red"]
        rows.each { row ->
            def grn = file(row.idat_grn)
            def red = file(row.idat_red)
            idat_files << grn
            idat_files << red
            lines << [row.sample, row.array_type, row.sample_group ?: '', row.tissue_type ?: '', grn.name, red.name].join(',')
        }
        def sheet = file("${workDir}/nf_samplesheets/${array_type}_samplesheet.csv")
        sheet.parent.mkdirs()
        sheet.text = lines.join('\n') + '\n'
        tuple(array_type, sheet, idat_files)
    }

    QC_SCORES(ch_input)

    QC_SCORES.out.summary.view { array_type, csv -> "QC-Scores listos para ${array_type}: ${csv}" }
}
