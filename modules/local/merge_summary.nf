process MERGE_SUMMARY {
    tag { array_type }
    publishDir { "${params.outdir}/${array_type}" }, mode: 'copy'

    input:
    tuple val(array_type), path(db_csv), path(cm_csv), path(bin_csv)

    output:
    tuple val(array_type), path("QC_Scores_summary_${array_type}.csv"), emit: csv

    script:
    """
    merge_summary.R "${db_csv}" "${cm_csv}" "${bin_csv}" "${array_type}" "QC_Scores_summary_${array_type}.csv"
    """
}
