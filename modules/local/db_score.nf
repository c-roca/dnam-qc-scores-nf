process DB_SCORE {
    tag { array_type }
    publishDir { "${params.outdir}/${array_type}/DB_Score" }, mode: 'copy'

    input:
    tuple val(array_type), path(beta_rds)

    output:
    tuple val(array_type), path("DBScore.csv"), emit: csv

    script:
    """
    db_score.R "${beta_rds}" DBScore.csv
    """
}
