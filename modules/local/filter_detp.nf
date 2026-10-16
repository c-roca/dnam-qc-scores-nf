process FILTER_DETP {
    tag "${array_type}"

    input:
    tuple val(array_type), path(msetsq_rds), path(detp_rds)
    val detp_threshold

    output:
    tuple val(array_type), path("msetsq_detp.rds"), emit: msetsq

    script:
    """
    filter_detp.R "${msetsq_rds}" "${detp_rds}" ${detp_threshold} msetsq_detp.rds
    """
}
