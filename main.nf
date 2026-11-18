#!/usr/bin/env nextflow
/*
========================================================================================
    qc-scores-nf
========================================================================================
    Nextflow pipeline (nf-core style, DSL2) that computes DB-Score, BIN-Score and
    CM-Score (Glaser et al. 2024, "Navigating Illumina DNA methylation data: biology
    versus technical artefacts", NAR Genomics and Bioinformatics; repo
    GlaserSe/DNAm-qc-scores) from 450K/EPIC/EPICv2 IDATs, following the same
    processing Met4All (minfi) uses up to the beta matrix. Ported from the standalone
    qc_scores_pipeline.R script -- see workflows/qc_scores.nf for the step map.
========================================================================================
*/

nextflow.enable.dsl = 2

include { QC_SCORES }       from './workflows/qc_scores'
include { FETCH_TEST_DATA } from './modules/local/fetch_test_data'

def helpMessage() {
    log.info """
    Usage:
      nextflow run . -profile docker --input samplesheet.csv --outdir results

    Required parameters:
      --input                 Master CSV with columns:
                               sample,array_type,sample_group,tissue_type,idat_grn,idat_red
                               (idat_grn/idat_red = absolute paths to each sample's
                               .idat or .idat.gz files; array_type = 450K | EPIC | EPIC_V2)
                               Generate it with bin/make_nf_samplesheet.R from your
                               usual targets CSV, if you don't have it in this format
                               yet.

    Optional parameters (with their default value):
      --outdir                 "results"
      --norm_method             "ssnoob"      (ssnoob|raw|illumina|quantile|funnorm)
      --detp_threshold          0.05
      --control_pattern         "Normal"      (substring in sample/sample_group for the BIN-Score)
      --qc_resources_dir        "assets/qc_resources"  (filter/*.txt, Bin_positions_*.txt, Stable_loci.txt)

    Profiles:
      -profile docker           runs every process inside the docker/Dockerfile container
      -profile test,docker      runs against a small public IDAT set fetched automatically
                                 from Bioconductor's minfiData/minfiDataEPIC (see conf/test.config
                                 and bin/fetch_test_data.R); no private data or --input needed
    """.stripIndent()
}

workflow {

    if (params.help) {
        helpMessage()
        exit 0
    }

    if (!params.fetch_test_data && !params.input) {
        helpMessage()
        error "Missing --input <samplesheet.csv>. See 'nextflow run . --help'."
    }

    // Declared here (not inside the branches below) so it stays visible
    // after the if/else -- the strict Nextflow parser scopes a bare `=`
    // assignment to the block it first appears in, same issue as the
    // tag/publishDir closures elsewhere in this pipeline.
    def ch_input

    if (params.fetch_test_data) {
        // --------------------------------------------------------------
        // Test profile: fetch a small public IDAT set per array_type from
        // Bioconductor itself (minfiData for 450K, minfiDataEPIC for EPIC)
        // instead of reading a user-supplied samplesheet. See
        // bin/fetch_test_data.R for why EPIC_V2 isn't included here.
        // --------------------------------------------------------------
        FETCH_TEST_DATA(Channel.of('450K', 'EPIC'))
        ch_input = FETCH_TEST_DATA.out.input
    } else {
        // --------------------------------------------------------------------
        // 1. Read the master samplesheet and group rows by array_type.
        // --------------------------------------------------------------------
        ch_rows = Channel
            .fromPath(params.input, checkIfExists: true)
            .splitCsv(header: true, quote: '"')   // R's write.csv (make_nf_samplesheet.R) quotes every field
            .map { row ->
                if (!row.idat_grn || !row.idat_red) {
                    error "Row missing idat_grn/idat_red in ${params.input}: ${row}"
                }
                if (!(row.array_type in ['450K', 'EPIC', 'EPIC_V2'])) {
                    error "array_type must be 450K, EPIC or EPIC_V2 (row: ${row})"
                }
                tuple(row.array_type, row)
            }
            .groupTuple()

        // --------------------------------------------------------------------
        // 2. For each array_type: build a "local" samplesheet (with the .idat
        //    file names as the process will see them, not the host's absolute
        //    path) + the list of .idat files to stage. Nextflow symlinks every
        //    path() declared as input into the process's work directory, so
        //    read_rgset.R always finds them in the cwd regardless of where they
        //    live on the host or whether the process runs inside Docker/Singularity.
        // --------------------------------------------------------------------
        ch_input = ch_rows.map { array_type, rows ->
            def idat_files = []
            def lines = ["sample,array_type,sample_group,tissue_type,idat_grn,idat_red"]
            rows.each { row ->
                def grn = file(row.idat_grn)
                def red = file(row.idat_red)
                idat_files << grn
                idat_files << red
                // Quote every field: sample_group can contain commas (e.g. "SLCT, no defined subtype")
                lines << [row.sample, row.array_type, row.sample_group ?: '', row.tissue_type ?: '', grn.name, red.name]
                    .collect { v -> '"' + v.toString().replace('"', '""') + '"' }
                    .join(',')
            }
            def sheet = file("${workDir}/nf_samplesheets/${array_type}_samplesheet.csv")
            sheet.parent.mkdirs()
            sheet.text = lines.join('\n') + '\n'
            tuple(array_type, sheet, idat_files)
        }
    }

    QC_SCORES(ch_input)

    QC_SCORES.out.summary.view { array_type, csv -> "QC-Scores ready for ${array_type}: ${csv}" }
    QC_SCORES.out.versions.view { f -> "Combined software versions: ${f}" }
}
