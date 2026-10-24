process NORMALIZE {
    tag { array_type }

    input:
    tuple val(array_type), path(rgset_rds)
    val norm_method

    output:
    tuple val(array_type), path("msetsq.rds"), emit: msetsq

    script:
    """
    normalize.R "${rgset_rds}" "${array_type}" "${norm_method}" msetsq.rds
    """
}
