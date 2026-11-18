process READ_RGSET {
    tag { array_type }
    publishDir { "${params.outdir}/${array_type}/qc_report" }, mode: 'copy', pattern: '*.pdf'

    input:
    tuple val(array_type), path(samplesheet), path(idat_files)

    output:
    tuple val(array_type), path("rgset.rds"),   emit: rgset
    tuple val(array_type), path("detp.rds"),    emit: detp
    tuple val(array_type), path("targets.rds"), emit: targets
    path "0-QC_report_${array_type}.pdf",       emit: qc_report
    path "versions.yml",                        emit: versions

    script:
    """
    read_rgset.R "${samplesheet}" "${array_type}" rgset.rds detp.rds targets.rds "0-QC_report_${array_type}.pdf"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r: \$(Rscript -e 'cat(R.version.string)' | sed 's/R version //; s/ .*//')
        minfi: \$(Rscript -e 'cat(as.character(packageVersion("minfi")))')
    END_VERSIONS
    """
}
