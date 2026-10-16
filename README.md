# dnam-qc-scores-nf

A Nextflow pipeline (DSL2, nf-core style) that computes **DB-Score**, **BIN-Score** and
**CM-Score**, the three QC scores from Glaser et al. 2024 (see [Citation](#citation)),
from 450K / EPIC / EPICv2 IDATs. It's the Nextflow version of the original code from the
paper's authors, [GlaserSe/DNAm-qc-scores](https://github.com/GlaserSe/DNAm-qc-scores).

It follows the exact same processing [Met4All](https://github.com/gcampof/Met4All) uses
(`generate_beta_matrix()`) up to the beta matrix: sample exclusion by detection-p,
normalization, probe filtering by detection-p and by blacklist (SNP/cross-hyb/XY), FFPE
adjustment, and a final SNP/XY/cross-hyb filter. It's the Nextflow version of the
standalone `qc_scores_pipeline.R` script that came before it, every step of that script is
now its own `process` (see `workflows/qc_scores.nf`).

## Where each score fits in

| Score | Computed on | When |
|---|---|---|
| BIN-Score | `mSetSq_flt` (Meth/Unmeth intensities) | **before** the beta matrix exists |
| DB-Score / CM-Score | final, filtered beta matrix | **after** the beta matrix |

All the probe quality filtering (detection-p + blacklist) always happens on intensities,
never on beta values. That's why BIN-Score sits in the middle of the chain and DB/CM-Score
come at the end.

## What you need

- [Nextflow](https://www.nextflow.io/) 23.04 or newer
- Docker (or Singularity, with `-profile singularity`)
- Your own IDATs and a samplesheet (see below)
- `assets/qc_resources/` filled in with your blacklist lists, bin tables and stable loci,
  not included in the repo, copy them from your local setup (see
  `assets/qc_resources/README.md`)

## 1. Build the Docker image

```bash
docker build -t <YOUR_USERNAME>/dnam-qc-scores-nf:latest docker/
```

Then put that same reference in `params.container` (`nextflow.config`), or pass it on
each run with `--container <YOUR_USERNAME>/dnam-qc-scores-nf:latest`.

> The image installs `minfi`, `DMRcate`, `limma`, the 450k/EPIC/EPICv2 manifests, and
> `conumee2` from GitHub (`hovestadtlab/conumee2`, it's not on Bioconductor). The build
> fails on purpose if any library doesn't load, so you find out now instead of three
> hours into a real run.

## 2. Prepare the samplesheet

The pipeline expects a single master CSV, one row per sample:

```csv
sample,array_type,sample_group,tissue_type,idat_grn,idat_red
SCCOHT_1,EPIC,SCCOHT,,/absolute/path/203049640041_R01C01_Grn.idat,/absolute/path/203049640041_R01C01_Red.idat
normal_1,EPIC,Normal,,/absolute/path/203049640041_R02C01_Grn.idat,/absolute/path/203049640041_R02C01_Red.idat
```

- `array_type` has to be exactly `450K`, `EPIC` or `EPIC_V2`.
- `idat_grn` / `idat_red` are **absolute** paths to the `.idat` (or `.idat.gz`) files. No
  need to copy them anywhere special, Nextflow stages them for you in each process
  (works the same with Docker or Singularity, doesn't matter where they live on disk).
- If you already have a targets CSV in the style you used with
  `prepare_idats_and_samplesheets.R` (columns `Array_Type`, `Basename`, `Sample_Name`...),
  convert it with:

  ```bash
  Rscript bin/make_nf_samplesheet.R my_targets.csv samplesheet.csv
  ```

## 3. Test it first with a small subset

**Don't launch all 166 samples right away.** First:

```bash
nextflow config .                              # checks the pipeline parses OK
# fill test_data/samplesheet_test.csv with 2-4 of your own samples (see test_data/README.md)
nextflow run . -profile test,docker --outdir test_results
```

This runs the full chain (reading IDATs, normalization, filtering, BIN-Score, beta,
DB/CM-Score, summary) with smaller resources, so you catch any environment/path issue
before a long run.

## 4. Run it on your real data

```bash
nextflow run . -profile docker \
    --input samplesheet.csv \
    --outdir results \
    -resume
```

The pipeline groups samples by `array_type` automatically and runs 450K / EPIC / EPIC_V2
**in parallel**, each with its own full chain, same as before when you launched the
standalone script once per array. `-resume` reuses steps already computed if you rerun
after a failure or a parameter change.

### Parameters

| Parameter | Default | What it is |
|---|---|---|
| `--input` | *(required)* | master samplesheet (see above) |
| `--outdir` | `results` | output folder |
| `--norm_method` | `ssnoob` | `ssnoob\|raw\|illumina\|quantile\|funnorm` |
| `--detp_threshold` | `0.05` | detection-p threshold (samples and probes) |
| `--control_pattern` | `Normal` | substring in `sample`/`sample_group` that marks your reference samples for BIN-Score |
| `--qc_resources_dir` | `assets/qc_resources` | folder with `filter/`, `Bin_positions_*.txt`, `Stable_loci.txt` |

## Outputs

For each `array_type`, inside `<outdir>/<array_type>/`:

- `qc_report/0-QC_report_<array_type>.pdf`, minfi's QC report
- `BIN_Score/BIN_Score.csv`
- `DB_Score/DBScore.csv`
- `CM_Score/CMScores.csv`
- `QC_Scores_summary_<array_type>.csv`, the merge of the three
- `beta_<array_type>.rds` / `.csv`, final beta matrix

Cutoffs suggested by the paper (heuristics, not validated biological thresholds):

- DB-Score **< 1**
- BIN-Score **< 0.25**
- CM-Score high / low / diff **< 20%**

If an `array_type` has no sample matching `control_pattern`, or **all** of them match it
(no case sample left to compare against, e.g. a batch that's 100% "Normal"),
`BIN_Score.csv` comes out empty (header only) for that array, and
`QC_Scores_summary_<array_type>.csv` just doesn't carry that column with data. That's not
a bug.

## Repo layout

```
main.nf                    entrypoint: reads the samplesheet, groups by array_type, calls the subworkflow
workflows/qc_scores.nf     full chain of processes per array_type
modules/local/*.nf         one process per step (1:1 with qc_scores_pipeline.R)
bin/*.R                    the actual logic for each step (R), called from each process
conf/base.config           CPU/RAM per process
conf/test.config           test profile with a small subset
docker/Dockerfile          image with minfi/conumee2/DMRcate/...
assets/qc_resources/       blacklist lists, bin tables and stable loci (not versioned)
test_data/                 test samplesheet (empty by default)
```

## Porting notes (from qc_scores_pipeline.R to Nextflow)

- `db_score()` and `cm_score()` from the paper's original repo expected a data.frame with
  `TargetID` as the first column and looped sample by sample. Here they're vectorized
  over the probe x sample matrix instead.
- `bin_score()` was written against the classic `conumee` package. Here it's ported to
  `conumee2` (the same API Met4All already uses in its comparative CNV module,
  `cnv_utils.R`), with three fixes verified against real data, documented as comments in
  `bin/bin_score.R`:
  1. `CNV.fit()` needs **numeric indices**, not name vectors, to subset the `CNV.data`
     object when the reference has more than one sample.
  2. `anno@probes` needs to be trimmed down to the probes still present after the
     detection-p/blacklist filters, otherwise `CNV.fit()` fails with
     *"query intensities not given for all probes"*.
  3. After that trim, `CNV.bin()` can leave bins with `NA`/0 variance (too few probes in
     that bin). They need to be dropped before `CNV.segment()`, or `DNAcopy::segment()`
     blows up with *"all weights should be positive"*.
  4. `CNV.write(x, what = "segments")` returns a **list** (one data.frame per sample in
     the query), not a plain data.frame like `what = "bins"` does.
- The script assumes your reference samples are identified by `control_pattern` in
  `sample`/`sample_group`, adjust this to however you name your samples (defaults to
  `"Normal"`).

## Citation

The three QC scores this pipeline implements (DB-Score, BIN-Score, CM-Score), the
suggested cutoffs, and the original R code all come from:

> Glaser S, Kretzmer H, Kolassa IT, Schlesner M, Fischer A, Fenske I, Siebert R, Ammerpohl O.
> **Navigating Illumina DNA methylation data: biology versus technical artefacts.**
> *NAR Genomics and Bioinformatics*, 2024;6(4):lqae181.
> https://doi.org/10.1093/nargab/lqae181

```bibtex
@article{glaser2024navigating,
  title     = {Navigating {I}llumina {DNA} methylation data: biology versus technical artefacts},
  author    = {Glaser, Selina and Kretzmer, Helene and Kolassa, Iris Tatjana and Schlesner, Matthias and Fischer, Anja and Fenske, Isabell and Siebert, Reiner and Ammerpohl, Ole},
  journal   = {NAR Genomics and Bioinformatics},
  volume    = {6},
  number    = {4},
  pages     = {lqae181},
  year      = {2024},
  doi       = {10.1093/nargab/lqae181}
}
```

Original R code by the authors: [GlaserSe/DNAm-qc-scores](https://github.com/GlaserSe/DNAm-qc-scores).
This repo is an independent reimplementation in Nextflow, built into the
[Met4All](https://github.com/gcampof/Met4All) processing pipeline, not affiliated with the
paper's original authors.

## License

MIT, see [LICENSE](LICENSE).
