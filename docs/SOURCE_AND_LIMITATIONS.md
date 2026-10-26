# Evidence / source provenance

| Artifact | Inspected content | Verified? | Publishing decision |
|---|---|---|---|
| `ICE Tracker (6).pdf` (10 pages) | KPI-rules matrix; overview; 4 chart pages; 4 tabular pages | Yes | Source image pack prepared separately in redacted form; raw PDF not uploaded |
| `ICE Tracker(1).pbix` | PBIR report definition, page names, visual types, bound column and measure names | Yes | Do not publish complete binary; includes private model/data |
| Embedded PBIX `DataModel` | XPress9 compressed | Original DAX text **not extracted** | Do not invent expressions |
| Six attached `*.txt` SQL files | Source query structure and output fields | Yes | SQL code preserved in `sql/`, not claimed deployed |
| Legacy Market Time repo files | Older version existed in main and was intentionally deleted in rebuild | Not the current PBIX source of truth | Not retained in current repo |
| KPI rules page number cards | 68 displayed; category split 16 / 15 / 18 / 19 | Yes | Described as displayed definition counts |
| KPI rule table screenshot | 64 visible report-label rows; bottom text is clipped | Yes, partial | Do not claim every formula for 68 entries is independently verified |

**Do not equate a PBIX field binding with the source expression of that measure.** The report-definition metadata references objects such as `PJP Compliance %`, but it does not store their DAX source in readable form. Exact DAX from the compressed model should be exported via Power BI Desktop PBIP/TMDL or a supported Tabular tooling pipeline.

The score weights 35 / 30 / 20 / 15 appear in supplied SQL headings and earlier project context, but the uploaded Product Mix SQL explicitly calls out **missing business-approved Score of the Day logic**. Treat weight mentions as **requirements context**, not evidence the composite is implemented.

**SQL date source conventions** observed:
- Daily Sales: `DeliveryDate`;
- Route productive invoices: `InvoiceDate` and `SA_CustomerRoute.VisitDate`;
- Market Time: `CreatedOn` for visits and SyncLogs;
- Product Mix: `DeliveryDate`.

These dates must be distinguished during reconciliation.

## Public-source handling

The dashboard visibly contains individual names, commercial amounts, geographic hierarchy and the client's branding. The report screenshot package uses row redaction; public GitHub stores architecture, reference formulas, transformations and explicitly **schematic** SVG diagrams, not unaltered operational material.
