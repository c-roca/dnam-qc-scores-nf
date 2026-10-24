process FILTER_SAMPLES {
    tag { array_type }

    input:
    tuple val(array_type), path(rgset_rds), path(detp_rds), path(targets_rds)
    val detp_threshold

    output:
    tuple val(array_type), path("rgset_filtered.rds"),   emit: rgset
    tuple val(array_type), path("detp_filtered.rds"),    emit: detp
    tuple val(array_type), path("targets_filtered.rds"), emit: targets

    script:
    """
    filter_samples.R "${rgset_rds}" "${detp_rds}" "${targets_rds}" ${detp_threshold} \
        rgset_filtered.rds detp_filtered.rds targets_filtered.rds
    """
}
