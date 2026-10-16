process FILTER_BLACKLIST {
    tag "${array_type}"

    input:
    tuple val(array_type), path(msetsq_rds)
    path filter_dir

    output:
    tuple val(array_type), path("msetsq_flt.rds"), emit: msetsq

    script:
    """
    filter_blacklist.R "${msetsq_rds}" "${filter_dir}" msetsq_flt.rds
    """
}
