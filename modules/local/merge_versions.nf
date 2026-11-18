process MERGE_VERSIONS {
    publishDir "${params.outdir}/pipeline_info", mode: 'copy'

    input:
    path versions_yml, stageAs: 'versions_*.yml'

    output:
    path "software_versions.yml"

    script:
    // The same process run once per array_type (e.g. READ_RGSET for 450K
    // and for EPIC) emits byte-identical blocks, since it's the same
    // container/tool versions either way -- dedupe at the line level so
    // each unique "<process>": {...} block only appears once.
    """
    cat ${versions_yml} | awk '!seen[\$0]++' > software_versions.yml
    """
}
