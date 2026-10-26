# Verified DAX — 90 measures from uploaded TMDL

The user-supplied `DAX(1).txt` is a **readable TMDL script**, not a compressed PBIX model. It contains **90 original measures across 8 table groups**. We have extracted and grouped every measure **without silently fixing the business logic**. See [all source expressions](../dax/original-tmdl-export.txt), [measure catalog](MEASURE_VISUAL_MAPPING.md) and per-domain `dax/*.dax`.

## Three levels of evidence

1. **Exact DAX**: 90 expressions reproduced from TMDL, including intentional blanks, text formatting and pre-existing calculation choices.
2. **Visual bindings**: report JSON identifies which of these names is referenced on each actual chart or matrix. It cannot prove a measure is computed correctly.
3. **SQL lineage**: six supplied extracts show source joins, invoice grain, visit sequencing, business flags and daily aggregation. Their tests are not executable without the client database.

## Practical measure walkthroughs

### 1. Sales — booked vs delivery execution

**Original:** `Order vs Execution % (Today)` divides sum of delivered invoice value by sum of booked value. In Sales charts/Overview it lets business teams separate order capture from fulfillment.

```dax
Order vs Execution % (Today) =
DIVIDE(
    SUM('Sheet1-DailySalesPerformance'[TotalSalesDelivered]),
    SUM('Sheet1-DailySalesPerformance'[TodayOrderBookedPKR]),
    0
)
```

*Subtotal:* naturally uses ratio of sums, not average of orderbooker percentages. *Date caveat:* the daily Sales SQL filters `DeliveryDate`, so mixing booked and delivered values demands careful definition.

### 2. Route — compliance versus conversion

```dax
PJP Compliance % =
DIVIDE(
    SUM('Sheet2-RouteExecution'[TotalVisitsPlanned_InclNonProductive]),
    SUM('Sheet2-RouteExecution'[PlannedShopsInPJP]),
    0
)
```

This measures planned shop coverage regardless of sale outcome. `StrikeRate% Overall` divides productive visited outlets by all visited outlets, with a **zero guard tied to planned shops and planned visits**. Managers need both route and conversion to distinguish missed coverage from low conversion.

### 3. Route — potential sales from missed outlets

Original `Missed Possible order value` multiplies `SUM(MissedOutlets)` by `[Avg Order Prod. Outlets]`. This is an **opportunity proxy**, *not actual booked/lost revenue*, because it assumes a hypothetical outlet order size.

### 4. Market Time — median, date stripping and text formatting

The exported `[Day Start (Median Time)]` computes `MEDIANX(ValidRows, MOD(DayStart, 1))`, stripping date to compare clock times across reporting days. Duration measures use `MEDIANX` over seconds columns and sometimes `FORMAT` to display `HH:MM` or `HH:MM:SS`. **Display strings should not be graphed as numeric axis values.**

`[Field Time Median]` in the actual TMDL is **median DayEnd minus median DayStart**, not the median of individual daily field durations; this difference matters and is flagged for QA. The separate `[Field Time (HH:MM)]` instead takes a median directly over daily duration seconds.

### 5. GPS — accuracy versus availability

```dax
GPS Compliance % =
DIVIDE(
    SUM('Sheet3-MarketTime&GPS'[ValidGPSCount]),
    SUM('Sheet3-MarketTime&GPS'[ShopsVisitedWithGPS]),
    0
)
```

This is **valid GPS / GPS-equipped visited shops**, not all stops. `[No GPS %]` uses `ShopsVisitedWithoutGPS / TotalStopRows` separately. Coordinate and repeat-visit definitions require SQL-to-visual reconciliation.

### 6. Brand depth — invoice-grain diversity

`[Avg Brands Per Bill]` is total distinct-brand-per-bill counts divided by bill count. `[Cross Brand Selling %]` is cross-brand bills divided by all bills. `[3+ Piece Rate]` uses the normalized invoice-brand piece-band dataset: count rows with `PieceBand = "3+ Pieces"` divided by all brand lines. These address deeper penetration, not just revenue.

### 7. Executive segmentation — statuses

`[OB Execution Status]` uses route compliance **0.95/0.90** and strike rate **0.65/0.60** as thresholds, returning On track / Watch / Action needed. In contrast, `[Execution_Status_Flag]` uses thresholds **95/90** and **65/60** on ratios whose formats suggest the 0–1 scale; the color logic is potentially defective. This remains unchanged in the source; see QA review.

## Audit: source-specific observations (not silently corrected)

- **Threshold scale mismatch:** `[Execution_Status_Flag]` compares `PJP >= 95` and `Strike >= 65`; `[OB Execution Status]` compares `>= 0.95` and `>= 0.65`. These are inconsistent for decimals formatted as percentages.
- **Numerical vs text outcomes:** `% Shops Without GPS` returns `"-"` or text concatenated with `%`, while `No GPS %` returns a numeric ratio; avoid using the former for quantitative charts.
- **Field Time Median:** `(MEDIAN(day_end_clock) - MEDIAN(day_start_clock)) * 86400` does not generally equal `MEDIAN(day_end - day_start)`.
- **Cumulative date logic:** `Last12Days_Sales` and `Last12Days_Exec` combine `DATESINPERIOD()` with `ALL('Date Table')`; verify filter override behavior against the intended trailing 12-day window.
- **Missing result policy:** Some measures return an empty string for missing numeric values; type coercion should be tested in totals, conditional formatting and charts.
- **Not a composite score:** TMDL measures include component counts and statuses, but the provided source does not establish an implemented 35/30/20/15 score formula.

**What has been verified:** semantic formula text and names, plus their static visual bindings. **What has not been verified:** calculation outputs in a running Power BI model, data accuracy, row-level security and measured real-world impact.