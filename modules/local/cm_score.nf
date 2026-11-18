process CM_SCORE {
    tag { array_type }
    publishDir { "${params.outdir}/${array_type}/CM_Score" }, mode: 'copy'

    input:
    tuple val(array_type), path(beta_rds)
    path stable_loci_file

    output:
    tuple val(array_type), path("CMScores.csv"), emit: csv
    path "versions.yml",                          emit: versions

    script:
    """
    cm_score.R "${beta_rds}" "${stable_loci_file}" CMScores.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r: \$(Rscript -e 'cat(R.version.string)' | sed 's/R version //; s/ .*//')
        data.table: \$(Rscript -e 'cat(as.character(packageVersion("data.table")))')
        matrixStats: \$(Rscript -e 'cat(as.character(packageVersion("matrixStats")))')
    END_VERSIONS
    """
}
