process FETCH_TEST_DATA {
    tag { array_type }

    input:
    val array_type   // '450K' or 'EPIC' -- see bin/fetch_test_data.R for why EPIC_V2 isn't included

    output:
    tuple val(array_type), path("samplesheet.csv"), path("idats/*"), emit: input
    path "versions.yml",                                             emit: versions

    script:
    """
    fetch_test_data.R "${array_type}" samplesheet.csv idats

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r: \$(Rscript -e 'cat(R.version.string)' | sed 's/R version //; s/ .*//')
        minfi: \$(Rscript -e 'cat(as.character(packageVersion("minfi")))')
    END_VERSIONS
    """
}
