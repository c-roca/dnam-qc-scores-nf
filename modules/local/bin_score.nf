process BIN_SCORE {
    tag { array_type }
    publishDir { "${params.outdir}/${array_type}/BIN_Score" }, mode: 'copy'

    input:
    tuple val(array_type), path(msetsq_flt_rds)
    val control_pattern
    path qc_resources_dir

    output:
    tuple val(array_type), path("BIN_Score.csv"), emit: csv

    script:
    """
    bin_score.R "${msetsq_flt_rds}" "${array_type}" "${control_pattern}" "${qc_resources_dir}" BIN_Score.csv
    """
}
