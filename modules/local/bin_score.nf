process BIN_SCORE {
    tag { array_type }
    publishDir { "${params.outdir}/${array_type}/BIN_Score" }, mode: 'copy'

    input:
    tuple val(array_type), path(msetsq_flt_rds)
    val control_pattern
    path qc_resources_dir

    output:
    tuple val(array_type), path("BIN_Score.csv"), emit: csv
    path "versions.yml",                           emit: versions

    script:
    """
    bin_score.R "${msetsq_flt_rds}" "${array_type}" "${control_pattern}" "${qc_resources_dir}" BIN_Score.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r: \$(Rscript -e 'cat(R.version.string)' | sed 's/R version //; s/ .*//')
        minfi: \$(Rscript -e 'cat(as.character(packageVersion("minfi")))')
        conumee2: \$(Rscript -e 'cat(as.character(packageVersion("conumee2")))')
        data.table: \$(Rscript -e 'cat(as.character(packageVersion("data.table")))')
    END_VERSIONS
    """
}
