//
// Main subworkflow: ports qc_scores_pipeline.R (the original standalone
// script) step by step to Nextflow processes. Each array_type (450K, EPIC,
// EPIC_V2) runs this same chain independently and in parallel -- just like
// the original script, which was run once per array_type.
//
// Order (same as the original script, see its comments for the why):
//   READ_RGSET -> FILTER_SAMPLES (step 0) -> NORMALIZE (step 1)
//     -> FILTER_DETP (step 2) -> FILTER_BLACKLIST (step 3)
//        -> BIN_SCORE (on msetsq_flt, before the beta matrix)
//        -> CALC_BETA (steps 4 + 5)
//           -> DB_SCORE + CM_SCORE (on the final beta matrix)
//              -> MERGE_SUMMARY
//

include { READ_RGSET }       from '../modules/local/read_rgset'
include { FILTER_SAMPLES }   from '../modules/local/filter_samples'
include { NORMALIZE }        from '../modules/local/normalize'
include { FILTER_DETP }      from '../modules/local/filter_detp'
include { FILTER_BLACKLIST } from '../modules/local/filter_blacklist'
include { BIN_SCORE }        from '../modules/local/bin_score'
include { CALC_BETA }        from '../modules/local/calc_beta'
include { DB_SCORE }         from '../modules/local/db_score'
include { CM_SCORE }         from '../modules/local/cm_score'
include { MERGE_SUMMARY }    from '../modules/local/merge_summary'
include { MERGE_VERSIONS }   from '../modules/local/merge_versions'

workflow QC_SCORES {
    take:
    ch_input   // tuple(array_type, local_samplesheet.csv, [idat files...])

    main:
    READ_RGSET(ch_input)

    // tuple(array_type, rgset) + tuple(array_type, detp) + tuple(array_type, targets)
    // -> a single tuple(array_type, rgset, detp, targets) channel for FILTER_SAMPLES
    ch_for_filter = READ_RGSET.out.rgset
        .join(READ_RGSET.out.detp)
        .join(READ_RGSET.out.targets)

    FILTER_SAMPLES(ch_for_filter, params.detp_threshold)

    NORMALIZE(FILTER_SAMPLES.out.rgset, params.norm_method)

    ch_for_detp = NORMALIZE.out.msetsq.join(FILTER_SAMPLES.out.detp)
    FILTER_DETP(ch_for_detp, params.detp_threshold)

    FILTER_BLACKLIST(FILTER_DETP.out.msetsq, file(params.filter_dir))

    BIN_SCORE(FILTER_BLACKLIST.out.msetsq, params.control_pattern, file(params.qc_resources_dir))

    CALC_BETA(FILTER_BLACKLIST.out.msetsq)

    DB_SCORE(CALC_BETA.out.rds)
    CM_SCORE(CALC_BETA.out.rds, file(params.stable_loci_file))

    ch_for_merge = DB_SCORE.out.csv
        .join(CM_SCORE.out.csv)
        .join(BIN_SCORE.out.csv)

    MERGE_SUMMARY(ch_for_merge)

    // -------------------------------------------------------------------
    // Collect every process's versions.yml (one per array_type instance)
    // into a single combined report (nf-core's dumpsoftwareversions idiom).
    // -------------------------------------------------------------------
    ch_versions = READ_RGSET.out.versions
        .mix(FILTER_SAMPLES.out.versions)
        .mix(NORMALIZE.out.versions)
        .mix(FILTER_DETP.out.versions)
        .mix(FILTER_BLACKLIST.out.versions)
        .mix(BIN_SCORE.out.versions)
        .mix(CALC_BETA.out.versions)
        .mix(DB_SCORE.out.versions)
        .mix(CM_SCORE.out.versions)
        .mix(MERGE_SUMMARY.out.versions)
        .collect()

    MERGE_VERSIONS(ch_versions)

    emit:
    summary  = MERGE_SUMMARY.out.csv
    beta     = CALC_BETA.out.rds
    versions = MERGE_VERSIONS.out
}
