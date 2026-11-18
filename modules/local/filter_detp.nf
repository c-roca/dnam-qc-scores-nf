process FILTER_DETP {
    tag { array_type }

    input:
    tuple val(array_type), path(msetsq_rds), path(detp_rds)
    val detp_threshold

    output:
    tuple val(array_type), path("msetsq_detp.rds"), emit: msetsq
    path "versions.yml",                             emit: versions

    script:
    """
    filter_detp.R "${msetsq_rds}" "${detp_rds}" ${detp_threshold} msetsq_detp.rds

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r: \$(Rscript -e 'cat(R.version.string)' | sed 's/R version //; s/ .*//')
        minfi: \$(Rscript -e 'cat(as.character(packageVersion("minfi")))')
        matrixStats: \$(Rscript -e 'cat(as.character(packageVersion("matrixStats")))')
    END_VERSIONS
    """
}
