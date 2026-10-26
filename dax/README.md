# Semantic layer — DAX

The source PBIX visual-definition JSON exposes **what field/measure was used in each visual**, but the actual measure definitions reside inside a compressed DataModel that was not extracted.

- [Illustrative reusable patterns](illustrative-patterns.dax): numeric percentage, sum/denominator and median duration examples.
- [DAX methodology and screenshot-to-measure mapping](../docs/DAX_EXPLAINED.md).
- [Data-grain and rollup risk register](../docs/DATA_QUALITY.md).

**Provenance:** Expressions in this directory are **reference examples**, not silently claimed original PBIX measures. Do not paste directly into production without mapping table and column names from a clean TMDL export.

## Exact DAX extraction next step

Open the provided `.pbix` in Power BI Desktop; save as `.pbip` with TMDL semantic model; inspect `definition/tables/*.tmdl`, strip server paths, credentials, employees and RLS before any public commit; map each report-bound measure to the extracted expression.
