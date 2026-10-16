# assets/qc_resources/

Esta carpeta tiene que quedar exactamente como la `qc_resources/` que ya
usas con `qc_scores_pipeline.R` (el script standalone). **No está incluida
en el repo** porque son ficheros de referencia de terceros (listas de sondas
y loci), no código del pipeline — cópiala tal cual desde tu copia local
antes de correr nada aquí:

```
assets/qc_resources/
├── filter/
│   ├── amb_3965probes.vh20151030.txt
│   ├── epicV1B2_32260probes.vh20160325.txt
│   ├── snp_7998probes.vh20151030.txt
│   └── xy_11551probes.vh20151030.txt
├── Bin_positions_450k.txt
├── Bin_positions_EPIC.txt
└── Stable_loci.txt
```

- `filter/*.txt` — las 4 listas de blacklist que ya usa Met4All en
  `shiny/app/common_files/filter/` (paso 3: SNP / cross-hyb / XY).
- `Bin_positions_450k.txt` / `Bin_positions_EPIC.txt` — del repo
  [GlaserSe/DNAm-qc-scores](https://github.com/GlaserSe/DNAm-qc-scores), para
  el BIN-Score. No hay tabla para EPIC_V2 en el paper original — para ese
  array_type el BIN-Score se salta siempre (con un aviso, no un error).
- `Stable_loci.txt` — del mismo repo, para el CM-Score.

Si quieres que estos ficheros vivan dentro del repo (para que `git clone` +
`nextflow run` funcione sin ningún paso manual), puedes quitar esta carpeta
del `.gitignore` y comitearlos directamente — son texto plano y pequeños,
así que no hay problema de tamaño de repo.
