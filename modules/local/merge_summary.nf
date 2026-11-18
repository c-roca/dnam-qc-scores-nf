process MERGE_SUMMARY {
    tag { array_type }
    publishDir { "${params.outdir}/${array_type}" }, mode: 'copy'

    input:
    tuple val(array_type), path(db_csv), path(cm_csv), path(bin_csv)

    output:
    tuple val(array_type), path("QC_Scores_summary_${array_type}.csv"), emit: csv
    path "versions.yml",                                                emit: versions

    script:
    """
    merge_summary.R "${db_csv}" "${cm_csv}" "${bin_csv}" "${array_type}" "QC_Scores_summary_${array_type}.csv"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r: \$(Rscript -e 'cat(R.version.string)' | sed 's/R version //; s/ .*//')
    END_VERSIONS
    """
}
