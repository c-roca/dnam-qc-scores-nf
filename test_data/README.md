# test_data/

This folder is intentionally empty -- real samples never get committed to the repo.

## Quick test (no data of your own needed)

```bash
nextflow run . -profile test,docker --outdir test_results
```

`-profile test` sets `params.fetch_test_data = true` (see `conf/test.config`), which
fetches a small, legitimately public IDAT set straight from Bioconductor's own
minfi test-data packages -- `minfiData` for 450K, `minfiDataEPIC` for EPIC -- via
`bin/fetch_test_data.R`. This needs internet access the first time (to install those
two packages inside the container), but no private IDATs, no `--input`, and nothing
to fill in here.

`minfiDataEPIC` ships 3 technical replicates of a single cell line, so there's no
control/case contrast for that array -- `BIN_SCORE` legitimately comes out empty
(header only) for the EPIC leg of this test. That's documented pipeline behaviour
(see the main README's Outputs section), not a bug. There is currently no equivalent
small public test package for EPIC_V2, so this quick test doesn't cover it.

## Testing against your own samples instead

Useful if you want to validate EPIC_V2 specifically, or do one last check with your
own data's quirks before a real run:

1. Pick 2-4 of your own samples from **a single array_type**, at least one matching
   `control_pattern` (default `"Normal"`) in its name or group, and at least one that
   doesn't (otherwise `BIN_SCORE` is skipped -- not an error, but it won't exercise
   that part).
2. Fill in `samplesheet_test.csv` with those rows -- see `samplesheet_test.example.csv`
   for the exact format, or generate it from your usual targets CSV with
   `bin/make_nf_samplesheet.R` and trim the result down to 2-4 rows.
3. Make sure `assets/qc_resources/` is populated (see its own README) -- the test
   profile needs it just like a real run does.
4. Run with the public-data fetch turned off:

   ```bash
   nextflow run . -profile test,docker --fetch_test_data false \
       --input test_data/samplesheet_test.csv --outdir test_results
   ```

You don't need to copy the `.idat` files into this folder: the paths in the CSV can
point straight to wherever they already live on disk.
