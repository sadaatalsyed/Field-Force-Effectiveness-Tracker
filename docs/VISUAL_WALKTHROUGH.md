# Report walkthrough — 10 original Power BI pages

This guide references the **actual PDF screenshots now hosted in this repository**, alongside the **90 DAX measure definitions extracted from user-provided TMDL** and visual metadata extracted from the accompanying PBIX. Screenshots are partially redacted for privacy; these are not mockup previews.

| PDF page | Report page | Original evidence | Business purpose |
|---|---|---|---|
| 1 | KPI Business Rules | [View capture](../assets/screenshots/01-kpi-business-rules.jpg) | 68 displayed rule definitions (some detail rows clipped) |
| 2 | Executive Overview | [View capture](../assets/screenshots/02-executive-overview.jpg) | Regional sales and field execution diagnostic overview |
| 3 | Daily Sales — Charts | [View capture](../assets/screenshots/03-daily-sales-charts.jpg) | Delivery against booking; App/Web, Pareto and operational gaps |
| 4 | Route Execution — Charts | [View capture](../assets/screenshots/04-route-execution-charts.jpg) | PJP vs actual coverage, strikes, productive calls and possible missed orders |
| 5 | Market Time & GPS — Charts | [View capture](../assets/screenshots/05-market-time-gps-charts.jpg) | Field time, shop time, idle, GPS coverage and 100m compliance |
| 6 | Product Mix — Charts | [View capture](../assets/screenshots/06-product-mix-charts.jpg) | Distinct brands/segments/variants, cross-sell and piece bands |
| 7 | Daily Sales — Matrix | [View capture](../assets/screenshots/07-daily-sales-matrix.jpg) | Organization-to-OB breakdown of booked/delivered and channel values |
| 8 | Route Execution — Matrix | [View capture](../assets/screenshots/08-route-execution-matrix.jpg) | Detailed planned/actual, productive, strike and GPS analysis |
| 9 | Market Time & GPS — Matrix | [View capture](../assets/screenshots/09-market-time-gps-matrix.jpg) | Detailed field/trade/shop time, idle and GPS |
| 10 | Product Mix — Matrix | [View capture](../assets/screenshots/10-product-mix-matrix.jpg) | Detailed assortment and product-piece analysis |

## Verified DAX expression → visual use

These formula names and logic are now **exact TMDL source**, not speculative examples. Visual mappings come from actual PBIX report JSON, see [90-measure mapping](MEASURE_VISUAL_MAPPING.md).

| Domain | Original model measure | Explanation |
|---|---|---|
| Daily Sales | `Order vs Execution % (Today)` | Delivered NetAmount relative to booked value; ratio-of-sums |
| Route Execution | `PJP Compliance %` | Planned visits (including nonproductive visits) ÷ PJP shops |
| Route Execution | `StrikeRate% Overall` | Productive outlets ÷ total visited outlets subject to planned-visit guards |
| Market & GPS | `GPS Compliance %` | ValidGPSCount ÷ ShopsVisitedWithGPS; reflects validity conditional on GPS availability |
| Market & GPS | `Field Time (HH:MM)` | Median of daily field time seconds with display formatting |
| Product Mix | `Avg Brands Per Bill` | Total brands across invoices ÷ bill count |
| Brand Mix | `3+ Piece Rate` | Fraction of invoice-brand observations with 3+ pieces |

**Original DAX source:** [Verbatim TMDL](../dax/original-tmdl-export.txt). **Lineage and caveats:** [DAX explained](DAX_EXPLAINED.md), [data quality](DATA_QUALITY.md).

## Confidentiality and evidence

Images are source-derived from the original dashboard PDF and partially redacted. Do not represent them as a live, interactively tested dashboard or share identifying figures without client permission. The report's 68 KPI rule-count is different from the model's 90 measures.
