process NORMALIZE {
    tag { array_type }

    input:
    tuple val(array_type), path(rgset_rds)
    val norm_method

    output:
    tuple val(array_type), path("msetsq.rds"), emit: msetsq
    path "versions.yml",                       emit: versions

    script:
    """
    normalize.R "${rgset_rds}" "${array_type}" "${norm_method}" msetsq.rds

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r: \$(Rscript -e 'cat(R.version.string)' | sed 's/R version //; s/ .*//')
        minfi: \$(Rscript -e 'cat(as.character(packageVersion("minfi")))')
    END_VERSIONS
    """
}
