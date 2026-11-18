process FILTER_BLACKLIST {
    tag { array_type }

    input:
    tuple val(array_type), path(msetsq_rds)
    path filter_dir

    output:
    tuple val(array_type), path("msetsq_flt.rds"), emit: msetsq
    path "versions.yml",                            emit: versions

    script:
    """
    filter_blacklist.R "${msetsq_rds}" "${filter_dir}" msetsq_flt.rds

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r: \$(Rscript -e 'cat(R.version.string)' | sed 's/R version //; s/ .*//')
        minfi: \$(Rscript -e 'cat(as.character(packageVersion("minfi")))')
    END_VERSIONS
    """
}
