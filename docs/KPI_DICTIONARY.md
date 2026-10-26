# KPI dictionary — source definitions, filters and rollup rules

The PDF's KPI Business Rules page states **68 defined KPIs**: **16 Daily Sales**, **15 Route Execution**, **18 Market Time & GPS**, **19 Product Mix & Brand Performance**. The captured exported page displays **64 visible table entries, including a truncated bottom row**, so this document does not claim to reproduce all 68 original rows verbatim. It documents the most business-critical definitions using the supplied SQL and the legible PDF content.

## 1. Daily Sales Performance — 16 defined

| Metric | Source-backed calculation concept | Critical interpretation |
|---|---|---|
| Sales Booked (App / Web) | Sum booked invoice value by synchronized App flag and order status | The source treats Open/Pending/Settled as booked |
| Sales Delivered (App / Web) | Sum invoice net amount where status is Settled by channel | Delivery date is used in the supplied SQL |
| Order vs Execution % | Delivery-versus-booking performance | Verify reporting-day alignment and final denominator from TMDL |
| Lost Sales Due to Operations | Non-settled booked value (Open/Pending in supplied extract) | Label should be reconciled with actual cancellation / eventual fulfillment definition |
| Avg Order per Outlet (App) | App Booked Value / App Outlets Booked | Distinct customer count, not raw invoice-line count |
| App Sales from Planned / Unplanned | App value split by route flag | Whether sold within planned journey |
| App Sales (Planned) % | Planned App Value / Total App Booked Value | Recompute totals from value, never mean of OB percentages |
| Outlets Contributing 80% / 20% | Rank outlets by booked value, allocate cumulative contribution | Top 80 **of sales value**, not top 80% of outlet count |
| Avg Order (80%) / (20%) | Value in group / number of outlets in that group | Recomputed for all selected OBs/days; ties/threshold require a policy |
| Previous-day booked / delivered | Prior-day comparisons shown in matrix | Date basis must be reconciled, not inferred from chart labels |

## 2. Route Execution & Productivity — 15 defined

| Metric | Concept | Correct denominator / caution |
|---|---|---|
| Planned outlets in PJP | Distinct planned `CustomerID` from `SA_CustomerRoute` by OB/day | PJP is a schedule, not evidence of a visit |
| Planned / unplanned outlets visited | Actual visits including productive and nonproductive sources | Distinct outlets vs repeat visit events must be decided |
| PJP Compliance % | Planned outlets actually visited / planned shops in PJP | Use full visit set, not only successful invoices |
| Productive outlets / calls | Sale-related customer contacts from invoice source | Invoice ≠ unique outlet; align with official KPI wording |
| Strike Rate % | Productive visited outlets / total visited outlets | Cannot average raw OB strike rates in subtotal |
| Productive Calls Per Hour | Productive calls / field hours | Source starts at first SyncDown, ends at last SyncUp |
| Productive Outlets Under/Over 500 | Distinct outlets by invoice net-value band | Exactly 500 belongs to <=500 in SQL; multiple bills/outlet need policy |
| GPS-compliant productive outlets | Distance to outlet geotag <= 100 metres | Visit-based count and unique-customer count are **different KPI definitions** |
| Missed shops / possible missed value | PJP missed outlets and related opportunity proxy | This is an estimate / proxy; not recognized sales revenue |

## 3. Market Time & GPS — 18 defined

| Metric | Source-backed formula | Aggregation |
|---|---|---|
| Field Time | Day End (SyncUp) - Day Start (SyncDown) | Median of daily OB durations for overview |
| Trade Time | Last visit completion - first visit start | Median of OB-day trade durations |
| Shop Time | Sum productive visit completion-start durations | Separate from travel, no duration assigned to nonproductive |
| Shop Time % | SUM(Shop Time Seconds) / SUM(Field Time Seconds) | Ratio of sums |
| Idle Time | SUM over consecutive visits of max(0, gap_seconds - 300) | Source has both daily sum and median representations; confirm reporting rule |
| Longest Idle Period | MAX of threshold-adjusted gaps | MAX across selected OBs/days |
| Active Market Time | Trade time less idle | Compute at OB-day before rollup; medians are not linear |
| Avg Time Between Visits | Average raw gap between consecutive stops | Requires at least two visits; source also describes travel-time interpretation |
| Median Time per Shop | Median duration of productive shop visits | Median-of-medians is not exact visit-level median |
| Distance Travelled | SUM consecutive visit-to-visit geodesic metres / 1000 | Invalid/missing coordinates excluded |
| GPS Compliance % | Valid GPS count (within 100m) / GPS-comparable observations | The existing DAX uses `ShopsWithGPS` as denominator |
| Shops With / Without GPS | Observations with/without usable reference/captured coordinates | Verify what SQL actually counts before labeling visit GPS coverage |

**Clock-time vs duration:** For timestamp medians across dates, `MOD(datetime,1)` isolates time-of-day; duration calculations operate on seconds. Formatting expressions returning a text label such as `"09:35"` should not be reused as a numeric chart axis.

## 4. Product Mix & Brand Performance — 19 defined

| Metric | Formula | Source grain |
|---|---|---|
| Average Brands per Bill | SUM(distinct brand counts per bill) / COUNT(bills) | InvoiceCode |
| Average Segments per Bill | SUM(distinct segment counts per bill) / COUNT(bills) | InvoiceCode |
| Average Variants per Bill | SUM(distinct ProductID counts per bill) / COUNT(bills) | InvoiceCode |
| Cross Brand Selling % | Invoices with >1 brand / all eligible invoices | InvoiceCode |
| CAPRI, HYPRO, OPAL, CAPRI Hand Wash, HYPE piece bands | Sum pieces for each **InvoiceCode + Brand**, then count invoices with 1, 2 or >=3 pieces | Invoice-brand |
| 3+ Piece Rate | Brand invoices in >=3 bucket / brand invoices in all buckets | Compare brand mix fairly |

Product Mix query filters settled orders and positive delivered pieces. Hardcoded BrandIDs used in the supplied source must map to the intended names; the source itself instructs verifying Brand.Title.

## Universal safeguards

- **Denominator not available:** show blank / N/A, not an invented 100%.
- **Subtotal:** counts/values additive; averages recalculated using sum of numerators and counts; durations often median; longest idle max.
- **Date lineage:** Sales/Product Mix generally delivery-date; Route invoices use invoice-date; Market Time visits use created-date; distinct dates are not automatically comparable.
- **Statuses:** Booked != delivered; nonproductive visits != invoices.
- **Grain:** Distinct `CustomerID`, `InvoiceCode` and actual visit events represent different concepts.
- **Weighted Score of the Day:** The supplied SQL explicitly records the weighting formula as undefined; no score is published as proven.
