process DB_SCORE {
    tag { array_type }
    publishDir { "${params.outdir}/${array_type}/DB_Score" }, mode: 'copy'

    input:
    tuple val(array_type), path(beta_rds)

    output:
    tuple val(array_type), path("DBScore.csv"), emit: csv
    path "versions.yml",                         emit: versions

    script:
    """
    db_score.R "${beta_rds}" DBScore.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r: \$(Rscript -e 'cat(R.version.string)' | sed 's/R version //; s/ .*//')
        matrixStats: \$(Rscript -e 'cat(as.character(packageVersion("matrixStats")))')
    END_VERSIONS
    """
}
