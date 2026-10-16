# test_data/

Esta carpeta está vacía a propósito — las muestras reales no se suben al repo.

Para probar el pipeline antes de lanzarlo contra tus 166 muestras:

1. Elige 2-4 muestras tuyas de **un mismo array_type**, al menos una de ellas
   con `control_pattern` (por defecto `"Normal"`) en el nombre o en el grupo,
   y al menos una que no lo tenga (si no, `BIN_SCORE` se salta — no es un
   error, pero no prueba esa parte).
2. Rellena `samplesheet_test.csv` con esas filas, por ejemplo:

   ```csv
   sample,array_type,sample_group,tissue_type,idat_grn,idat_red
   normal_1,EPIC,Normal,,/ruta/absoluta/203049640041_R01C01_Grn.idat,/ruta/absoluta/203049640041_R01C01_Red.idat
   SCCOHT_1,EPIC,SCCOHT,,/ruta/absoluta/203049640041_R02C01_Grn.idat,/ruta/absoluta/203049640041_R02C01_Red.idat
   ```

   También puedes generarlo con `bin/make_nf_samplesheet.R` a partir de tu
   targets CSV de siempre (el mismo formato que usaba
   `01_targets_final_paperWDSLCT.csv`) y luego recortar el resultado a solo
   2-4 filas.
3. Asegúrate de que `assets/qc_resources/` está poblado (ver su propio
   README) — el perfil de test lo necesita igual que una corrida real.
4. `nextflow run . -profile test,docker --outdir test_results`

No hace falta copiar los .idat a esta carpeta: las rutas en el CSV pueden
apuntar directamente a donde ya los tengas en tu disco.
