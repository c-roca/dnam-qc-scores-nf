process CM_SCORE {
    tag "${array_type}"
    publishDir "${params.outdir}/${array_type}/CM_Score", mode: 'copy'

    input:
    tuple val(array_type), path(beta_rds)
    path stable_loci_file

    output:
    tuple val(array_type), path("CMScores.csv"), emit: csv

    script:
    """
    cm_score.R "${beta_rds}" "${stable_loci_file}" CMScores.csv
    """
}
