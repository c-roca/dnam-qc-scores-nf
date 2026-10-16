//
// Subworkflow principal: porta paso a paso qc_scores_pipeline.R (el script
// standalone original) a procesos de Nextflow. Cada array_type (450K, EPIC,
// EPIC_V2) corre esta misma cadena de forma independiente y en paralelo --
// igual que el script original, que se ejecutaba una vez por array_type.
//
// Orden (igual que el script original, ver comentarios ahi para el porque):
//   READ_RGSET -> FILTER_SAMPLES (paso 0) -> NORMALIZE (paso 1)
//     -> FILTER_DETP (paso 2) -> FILTER_BLACKLIST (paso 3)
//        -> BIN_SCORE (sobre msetsq_flt, antes de la beta matrix)
//        -> CALC_BETA (paso 4 + 5)
//           -> DB_SCORE + CM_SCORE (sobre la beta matrix final)
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

workflow QC_SCORES {
    take:
    ch_input   // tuple(array_type, samplesheet_local.csv, [idat files...])

    main:
    READ_RGSET(ch_input)

    // tuple(array_type, rgset) + tuple(array_type, detp) + tuple(array_type, targets)
    // -> un solo canal tuple(array_type, rgset, detp, targets) para FILTER_SAMPLES
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

    emit:
    summary = MERGE_SUMMARY.out.csv
    beta    = CALC_BETA.out.rds
}
