process CALC_BETA {
    tag { array_type }
    publishDir { "${params.outdir}/${array_type}" }, mode: 'copy', pattern: 'beta_*'

    input:
    tuple val(array_type), path(msetsq_flt_rds)

    output:
    tuple val(array_type), path("beta_${array_type}.rds"), emit: rds
    path "beta_${array_type}.csv",                         emit: csv
    path "versions.yml",                                   emit: versions

    script:
    """
    calc_beta.R "${msetsq_flt_rds}" "${array_type}" "beta_${array_type}.rds" "beta_${array_type}.csv"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r: \$(Rscript -e 'cat(R.version.string)' | sed 's/R version //; s/ .*//')
        minfi: \$(Rscript -e 'cat(as.character(packageVersion("minfi")))')
        limma: \$(Rscript -e 'cat(as.character(packageVersion("limma")))')
        DMRcate: \$(Rscript -e 'cat(as.character(packageVersion("DMRcate")))')
    END_VERSIONS
    """
}
