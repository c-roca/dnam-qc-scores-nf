# assets/qc_resources/

```
assets/qc_resources/
├── filter/                              <- NOT in the repo, copy it from your own setup
│   ├── amb_3965probes.vh20151030.txt
│   ├── epicV1B2_32260probes.vh20160325.txt
│   ├── snp_7998probes.vh20151030.txt
│   └── xy_11551probes.vh20151030.txt
├── Bin_positions_450k.txt               <- vendored in the repo, see below
├── Bin_positions_EPIC.txt               <- vendored in the repo, see below
└── Stable_loci.txt                      <- vendored in the repo, see below
```

## Vendored files (BIN-Score / CM-Score)

`Bin_positions_450k.txt`, `Bin_positions_EPIC.txt` and `Stable_loci.txt` are copied
as-is from [GlaserSe/DNAm-qc-scores](https://github.com/GlaserSe/DNAm-qc-scores)
(`BIN.Score/Bin positions_450k.txt`, `BIN.Score/Bin positions_EPIC.txt` and
`CM.Scores/Stable_loci.txt`, renamed to the underscore filenames this pipeline
expects) -- the same paper this pipeline implements (see the main README's
Citation section), published under the MIT license kept here as
`LICENSE-GlaserSe-DNAm-qc-scores`. There is no bin-positions table for EPIC_V2
in the original paper, so BIN-Score is always skipped for that array type
(with a warning, not an error).

Committing these lets `-profile test` run BIN-Score and CM-Score out of the box.
`FILTER_BLACKLIST` still needs `filter/`, below, so a from-scratch clone can't
run past that step until you add it.

## Not included: `filter/` (SNP / cross-hyb / XY blacklists)

This folder has to match the `qc_resources/filter/` you already use with
`qc_scores_pipeline.R` (the standalone script). **It's not included in the repo**
because its provenance/licence for public redistribution isn't confirmed here --
copy it as-is from your local setup before running anything that needs it
(`FILTER_BLACKLIST`, and everything downstream: `BIN_SCORE`, `CALC_BETA`,
`DB_SCORE`, `CM_SCORE`, `MERGE_SUMMARY` all depend on its output). If you can
confirm these four files are fine to publish (e.g. they're your own derived
list, or covered by a licence that allows it), you can vendor them the same
way as the files above and remove `assets/qc_resources/filter/*.txt` from
`.gitignore`.
