process CALC_BETA {
    tag "${array_type}"
    publishDir "${params.outdir}/${array_type}", mode: 'copy', pattern: 'beta_*'

    input:
    tuple val(array_type), path(msetsq_flt_rds)

    output:
    tuple val(array_type), path("beta_${array_type}.rds"), emit: rds
    path "beta_${array_type}.csv",                         emit: csv

    script:
    """
    calc_beta.R "${msetsq_flt_rds}" "${array_type}" "beta_${array_type}.rds" "beta_${array_type}.csv"
    """
}
