process MERGE_VERSIONS {
    publishDir "${params.outdir}/pipeline_info", mode: 'copy'

    input:
    path versions_yml, stageAs: 'versions_*.yml'

    output:
    path "software_versions.yml"

    script:
    // Dedup by whole block (top-level "process": key + its indented child
    // lines), not by individual line -- two different processes can share
    // an identical child line (the same R version, say), and a per-line
    // dedup silently drops that line from the second process's block.
    """
    awk '
        /^"/ { if (block != "") { if (!seen[block]++) printf "%s", block }; block = \$0 "\\n"; next }
        { block = block \$0 "\\n" }
        END { if (block != "" && !seen[block]++) printf "%s", block }
    ' ${versions_yml} > software_versions.yml
    """
}
