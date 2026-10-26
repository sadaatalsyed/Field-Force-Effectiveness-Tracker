# DAX explained — measure lineage and visuals

## What is truly extracted versus illustrative?

| Evidence class | Available | How to interpret |
|---|---|---|
| **Source SQL** | Yes, six original attached text files | Underlying queries supplied by the analyst; this repo preserves them |
| **Power BI report-definition visual bindings** | Yes, from report JSON embedded in uploaded PBIX | Confirms page → visual → bound measure or source column |
| **Original DAX from previous repo history** | Deleted from the current tree as requested | It is not treated as evidence of the uploaded PBIX semantic expressions |
| **Original DAX formula text inside attached PBIX** | **Not extractable with available runtime** | Embedded DataModel is XPress9-compressed; report-definition JSON contains **names** but not semantic formula text |
| **Additional DAX in this repo** | Yes, [illustrative patterns](../dax/illustrative-patterns.dax) | Clearly labeled reference implementation, **not claimed to be extracted from the PBIX** |

## Worked examples and visual use

### PJP compliance — route matrix, Overview regional chart
**Meaning:** share of PJP shops actually visited, including nonproductive recorded visits if the business definition requires actual coverage rather than sale creation.

```dax
PJP Compliance % (illustrative) =
DIVIDE (
    SUM ( RouteDaily[TotalVisitsPlanned_InclNonProductive] ),
    SUM ( RouteDaily[PlannedShopsInPJP] )
)
```
Do **not** take `AVERAGE(RouteDaily[PJPCompliancePercent])` across OBs with different numbers of planned outlets.

### Strike Rate — region comparison, route performance matrix
```dax
Strike Rate % (illustrative) =
DIVIDE (
    SUM ( RouteDaily[ProductiveOutletsOverall] ),
    SUM ( RouteDaily[TotalVisits_InclNonProductive] )
)
```
A source row may de-duplicate a customer within a day, so this is an **outlet-based** example; it is not interchangeable with order-event conversion.

### GPS compliance — Market Time GPS funnel
The **documented business definition** uses valid GPS count divided by shops with GPS. For a numeric visual, avoid concatenating `"%"` or returning `"-"`, because that converts the measure to text and impairs chart sorting/numeric scaling.

```dax
GPS Compliance % (numeric illustration) =
DIVIDE (
    SUM ( MarketDaily[ValidGPSCount] ),
    SUM ( MarketDaily[ShopsWithGPS] )
)
```
Format as percentage. Always display a separate no-GPS metric. The supplied SQL's `ValidGPSCount` is based on distinct customers in one workstream, not all raw check-in events.

### Median field/trade duration — Market Time time-series
Recommended median-duration reference pattern uses `MEDIANX` on `FieldTimeSeconds`, then formats hours/minutes. Crucially, duration medians operate on the **raw seconds column**, not a subtraction of two already aggregated medians. This supports the report's field-time and trade-time comparison visual.

```dax
Field Time Seconds (median illustration) =
MEDIANX (
    FILTER ( MarketDaily, NOT ISBLANK ( MarketDaily[FieldTimeSeconds] ) ),
    MarketDaily[FieldTimeSeconds]
)
```
A second *formatted display* measure is appropriate for a card or table; keep the numeric version for graphical axes.

### Shop Time % — Market KPI card
```dax
Shop Time % (illustrative) =
DIVIDE (
    SUM ( MarketDaily[ShopTimeSeconds] ),
    SUM ( MarketDaily[FieldTimeSeconds] )
)
```

### Cross-brand selling — Product Mix decomposition tree
```dax
Cross Brand Selling % (illustrative) =
DIVIDE (
    SUM ( ProductMixDaily[CrossBrandBillCount] ),
    SUM ( ProductMixDaily[BillCount] )
)
```

### Average brands / bill — Product Mix scorecards & drilldown
```dax
Avg Brands Per Bill (illustrative) =
DIVIDE (
    SUM ( ProductMixDaily[TotalBrandsInBill] ),
    SUM ( ProductMixDaily[BillCount] )
)
```

## How to get **the actual complete DAX** without pretending

1. Open the original `ICE Tracker(1).pbix` in **Power BI Desktop**.
2. Save as a **Power BI Project (.pbip)** with semantic model stored as **TMDL**.
3. Commit only **de-identified** `*.tmdl` metadata after verifying source strings, credentials, organization names, RLS and private entities.
4. Reconcile every report-bound measure name against its actual `measure ... =` expression in TMDL.
5. Then replace illustrative examples and mark the formula catalog *PBIX verified*. Never label an example as original until verified against that model.

References: [Microsoft Power BI Projects / TMDL](https://learn.microsoft.com/en-us/power-bi/developer/projects/projects-dataset), [pbi-tools extraction guide](https://pbi.tools/cli/usage.html).
