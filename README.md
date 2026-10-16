# dnam-qc-scores-nf

Pipeline Nextflow (DSL2, estilo nf-core) que calcula **DB-Score**, **BIN-Score** y
**CM-Score** — los tres QC-Scores de Glaser et al. 2024 (ver [Cita](#cita)) — a partir de
IDATs 450K / EPIC / EPICv2. Es la versión Nextflow del código original de los autores del
paper, [GlaserSe/DNAm-qc-scores](https://github.com/GlaserSe/DNAm-qc-scores).

Sigue exactamente el mismo procesamiento que usa [Met4All](https://github.com/gcampof/Met4All)
(`generate_beta_matrix()`) hasta la beta matrix: exclusión de muestras por detección-p,
normalización, filtrado de sondas por detección-p y por blacklist (SNP/cross-hyb/XY),
ajuste FFPE/Frozen, y filtrado final SNP/XY/cross-hyb. Es la versión en Nextflow del
script standalone `qc_scores_pipeline.R` que lo precedió — cada paso de ese script es
ahora un `process` independiente (ver `workflows/qc_scores.nf`).

## Dónde entra cada score

| Score | Se calcula sobre | Cuándo |
|---|---|---|
| BIN-Score | `mSetSq_flt` (intensidades Meth/Unmeth) | **antes** de calcular la beta matrix |
| DB-Score / CM-Score | beta matrix final, ya filtrada | **después** de la beta matrix |

Todo el filtrado de calidad de sondas (detección-p + blacklist) ocurre siempre sobre
intensidades, nunca sobre beta — por eso BIN-Score va en medio de la cadena y
DB/CM-Score al final.

## Requisitos

- [Nextflow](https://www.nextflow.io/) ≥ 23.04
- Docker (o Singularity, con `-profile singularity`)
- Tus propios IDATs y un samplesheet (ver abajo)
- `assets/qc_resources/` poblado con tus listas de blacklist, tablas de bins y loci
  estables — **no están incluidas en el repo**, cópialas desde tu copia local (ver
  `assets/qc_resources/README.md`)

## 1. Construir la imagen de Docker

```bash
docker build -t <TU_USUARIO>/dnam-qc-scores-nf:latest docker/
```

Luego pon esa misma referencia en `params.container` (`nextflow.config`), o pásala en
cada corrida con `--container <TU_USUARIO>/dnam-qc-scores-nf:latest`.

> La imagen instala `minfi`, `DMRcate`, `limma`, los manifests de 450k/EPIC/EPICv2, y
> `conumee2` desde GitHub (`hovestadtlab/conumee2`, no está en Bioconductor). El build
> falla explícitamente si alguna librería no carga, para no descubrirlo a mitad de una
> corrida de 3 horas.

## 2. Preparar el samplesheet

El pipeline espera un único CSV maestro con una fila por muestra:

```csv
sample,array_type,sample_group,tissue_type,idat_grn,idat_red
SCCOHT_1,EPIC,SCCOHT,,/ruta/absoluta/203049640041_R01C01_Grn.idat,/ruta/absoluta/203049640041_R01C01_Red.idat
normal_1,EPIC,Normal,,/ruta/absoluta/203049640041_R02C01_Grn.idat,/ruta/absoluta/203049640041_R02C01_Red.idat
```

- `array_type` tiene que ser exactamente `450K`, `EPIC` o `EPIC_V2`.
- `idat_grn` / `idat_red` son rutas **absolutas** a los `.idat` (o `.idat.gz`) — no hace
  falta copiarlos a ningún sitio especial, Nextflow los stagea él solo en cada proceso
  (funciona igual con Docker o Singularity, da igual dónde vivan en tu disco).
- Si ya tienes un targets CSV al estilo del que usabas con
  `prepare_idats_and_samplesheets.R` (columnas `Array_Type`, `Basename`,
  `Sample_Name`...), conviértelo con:

  ```bash
  Rscript bin/make_nf_samplesheet.R mi_targets.csv samplesheet.csv
  ```

## 3. Probarlo primero con un subset pequeño

**No lances las 166 muestras a la primera.** Antes de nada:

```bash
nextflow config .                              # valida que el pipeline parsea bien
# rellena test_data/samplesheet_test.csv con 2-4 muestras tuyas (ver test_data/README.md)
nextflow run . -profile test,docker --outdir test_results
```

Esto corre la cadena completa (lectura de IDATs → normalización → filtrados →
BIN-Score → beta → DB/CM-Score → resumen) con recursos reducidos, para pillar
cualquier problema de entorno/paths antes de una corrida larga.

## 4. Correr contra tus datos reales

```bash
nextflow run . -profile docker \
    --input samplesheet.csv \
    --outdir results \
    -resume
```

El pipeline agrupa las muestras por `array_type` automáticamente y corre 450K / EPIC /
EPIC_V2 **en paralelo**, cada uno con su propia cadena completa — igual que hacías antes
lanzando el script standalone una vez por array. `-resume` reutiliza los pasos ya
calculados si relanzas tras un fallo o un cambio de parámetros.

### Parámetros

| Parámetro | Default | Qué es |
|---|---|---|
| `--input` | *(obligatorio)* | samplesheet maestro (ver arriba) |
| `--outdir` | `results` | carpeta de salida |
| `--norm_method` | `ssnoob` | `ssnoob\|raw\|illumina\|quantile\|funnorm` |
| `--detp_threshold` | `0.05` | umbral de detección-p (muestras y sondas) |
| `--control_pattern` | `Normal` | substring en `sample`/`sample_group` que identifica tus referencias para BIN-Score |
| `--qc_resources_dir` | `assets/qc_resources` | carpeta con `filter/`, `Bin_positions_*.txt`, `Stable_loci.txt` |

## Salidas

Por cada `array_type`, dentro de `<outdir>/<array_type>/`:

- `qc_report/0-QC_report_<array_type>.pdf` — QC report de minfi
- `BIN_Score/BIN_Score.csv`
- `DB_Score/DBScore.csv`
- `CM_Score/CMScores.csv`
- `QC_Scores_summary_<array_type>.csv` — el merge de los tres
- `beta_<array_type>.rds` / `.csv` — beta matrix final

Cutoffs sugeridos por el paper (heurísticas, no umbrales biológicos validados):

- DB-Score **< 1**
- BIN-Score **< 0.25**
- CM-Score high / low / diff **< 20 %**

Si un `array_type` no tiene ninguna muestra con `control_pattern`, o **todas** sus
muestras lo tienen (sin ningún caso con el que comparar — p. ej. un batch 100%
"Normal"), `BIN_Score.csv` sale vacío (solo cabecera) para ese array, y
`QC_Scores_summary_<array_type>.csv` simplemente no trae esa columna con datos. No es
un error.

## Estructura del repo

```
main.nf                    entrypoint: lee el samplesheet, agrupa por array_type, llama al subworkflow
workflows/qc_scores.nf      cadena completa de processes por array_type
modules/local/*.nf          un process por paso (mismo mapeo 1:1 con qc_scores_pipeline.R)
bin/*.R                      la lógica real de cada paso (R), invocada desde cada process
conf/base.config             CPU/RAM por proceso
conf/test.config             perfil de test con un subset pequeño
docker/Dockerfile            imagen con minfi/conumee2/DMRcate/...
assets/qc_resources/         listas de blacklist, bins y loci estables (no versionadas)
test_data/                    samplesheet de test (vacío por defecto)
```

## Notas de la portación (de qc_scores_pipeline.R a Nextflow)

- `db_score()` y `cm_score()` del repo original del paper esperaban un data.frame con
  `TargetID` como primera columna y trabajaban con un `for` por muestra; aquí están
  vectorizados sobre la matriz probe × muestra.
- `bin_score()` estaba escrito contra el paquete `conumee` clásico; aquí está portado a
  `conumee2` (la misma API que ya usa Met4All en su módulo de CNV comparativo,
  `cnv_utils.R`), con tres fixes verificados contra datos reales — documentados como
  comentarios en `bin/bin_score.R`:
  1. `CNV.fit()` necesita **índices numéricos**, no vectores de nombres, para
     subsetear el objeto `CNV.data` cuando la referencia tiene más de una muestra.
  2. `anno@probes` hay que recortarlo a las sondas que sigan presentes tras los
     filtros de detección-p/blacklist — si no, `CNV.fit()` falla con
     *"query intensities not given for all probes"*.
  3. Tras ese recorte, `CNV.bin()` puede dejar bins con varianza `NA`/0 (muy pocas
     sondas por bin); hay que quitarlos antes de `CNV.segment()`, o
     `DNAcopy::segment()` revienta con *"all weights should be positive"*.
  4. `CNV.write(x, what = "segments")` devuelve una **lista** (un data.frame por
     muestra del query), no un data.frame suelto como `what = "bins"`.
- El script asume que tus muestras de referencia están identificadas por
  `control_pattern` en `sample`/`sample_group` — ajusta esto a como nombres tus
  muestras (por defecto `"Normal"`).

## Cita

Los tres QC-Scores que implementa este pipeline (DB-Score, BIN-Score, CM-Score), los
cutoffs sugeridos y el código R original vienen de:

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

Código R original de los autores: [GlaserSe/DNAm-qc-scores](https://github.com/GlaserSe/DNAm-qc-scores).
Este repositorio es una re-implementación independiente en Nextflow, integrada en el
pipeline de procesamiento de [Met4All](https://github.com/gcampof/Met4All) — no está
afiliado con los autores originales del paper.

## Licencia

MIT — ver [LICENSE](LICENSE).
