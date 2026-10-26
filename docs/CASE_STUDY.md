# Case Study — Turning FMCG Sales Numbers into Field-Execution Intelligence

## 1. Context and the decision problem

An FMCG direct-store-distribution network depends on daily order-booker (OB) activity. An OB receives a Permanent Journey Plan (PJP), visits retailers, records orders in a mobile app or via other channels, and operates within distributor, territory and management hierarchies. Merely knowing yesterday's booked value does not explain whether the team followed the plan, reached the right outlets, used market time well or sold across the portfolio.

**Business question:** *For each order booker, on each day, did the right market activity happen — and what explains the sales result?*

The source report provides four analytical domains (Daily Sales, Route, Market Time/GPS and Product Mix), a consolidated Overview and a KPI-rules matrix. The need to bring these together is evidenced by the supplied SQL drafts and the actual report visual configuration.

## 2. Failure modes the dashboard was designed to expose

1. **Sales-only visibility.** A booked sales total can hide missed PJP shops, offline or web-booked orders, and a weak productive-visit rate.
2. **Activity counted at the wrong grain.** Invoice lines are not invoices and repeat visits are not necessarily unique outlets. Summing product rows without grouping by invoice inflates order counts.
3. **Confusing time metrics.** Field, trade, shop and idle intervals answer distinct questions; median duration subtotals need deliberate definitions.
4. **Poorly qualified GPS claims.** Missing coordinates and visits beyond the 100m threshold must be separated — a good accuracy rate among GPS-equipped visits does not imply high overall coverage.
5. **Low assortment depth concealed by revenue.** A strong order value could still concentrate on one brand or one-piece bills.
6. **Unclear management ownership.** Coaching opportunities need to aggregate under distribution, town, territory, area and the corresponding manager.

These are **diagnostic problems that motivated the design**; they are not a fabricated account of measured outages or an independently verified pre-project baseline.

## 3. The solution: four diagnostic lenses connected to one daily unit

| Lens | Extracted from sources | Managerial interpretation |
|---|---|---|
| **Daily sales** | `SA_SalesOrdersDump`, invoice `SUM(NetAmount)`, delivery-date basis, statuses | Separate booking from delivered sales; App/Web channel split and order concentration |
| **Route execution** | `SA_CustomerRoute`, productive invoices and `NonProductiveCustomers` | Compare planned calls with execution; identify unplanned and missed-shop exposure |
| **Market-time & GPS** | `SyncLogs`, sequenced visit timestamps, customer/visit coordinates | Field vs trade hours, idle periods, shop contact and quality of geotags |
| **Product mix** | `Product`, `Brand`, invoice-level distinct counts and per-brand units | Cross-brand penetration, average assortment and one/two/three-plus piece distribution |

**Architecture choice:** Make source-level transactional distinctions explicit in SQL, then expose daily reporting fields and DAX aggregations for slicers, cards, visual trends and matrix subtotals.

## 4. Analytical design decisions that mattered

### A. De-duplicate at the correct event grain
The Daily Sales source first groups invoice-line amounts to invoice headers using **SUM of NetAmount**, not MIN. Product Mix counts distinct BrandID, SegmentID and ProductID **inside each InvoiceCode**, then aggregates per OB-day. This prevents multiple lines for a brand from inflating the number of bills or brands. *One invoice can contain several SKUs; one customer can place multiple invoices.*

### B. Distinguish booked versus delivered
The sales query treats `Open`, `Pending`, and `Settled` as booked, while delivered value is `Settled`. It separates synchronized App from non-App/Web records. Delivery-date filtering in the supplied query is a **source implementation choice**, not proof that booking date and delivery date always coincide.

### C. Measure the route, not just transactions
The Route SQL combines productive and nonproductive activity with PJP shops. The denominators therefore differ: **planned outlets**, **all visited outlets**, **productive outlets**, and **invoices** are not interchangeable.

### D. Reconstruct the day from timestamped visits
The Market Time source combines App productive visits with nonproductive records; the latter have one timestamp and therefore do not supply real shop duration. SQL uses `LAG` to sequence stops, 5 minutes of normal transition allowance, and great-circle distance between consecutive GPS coordinates.

### E. Make subtotal semantics explicit
For multiple OBs and days, ordinary averages can be wrong:
- Durations often use **median per OB-day** rather than simple sum.
- Ratios use **SUM(numerator) / SUM(denominator)**, not the average of percentages.
- Longest idle uses the **maximum** of observed idle intervals.
- Clock-time medians should remove the date component before aggregation.
- Medians of OB-day medians are **not** the true median of underlying visit events.

### F. Separate coverage and accuracy for GPS
The source flags locations within **100 metres**. A ratio such as valid GPS / GPS-capable outlet observations measures accuracy *conditional on coverage*. Report a separate GPS availability indicator; otherwise an OB with many missing coordinates could still appear compliant.

## 5. The business-facing experience

The Overview brings performance summaries and comparisons together. Each analytical chart page uses a mix of cards, trends, bars, funnel/donut or decomposition visuals and distribution/OB hierarchy drilldowns. Four dedicated detail matrices provide row-level organizational drilldown and reconciliation. The KPI Business Rules page is part of the report: metric definitions are available to end users, not hidden in a developer notebook.

**Illustrative operating workflow:** A manager notices a low route strike rate in the Overview → filters to territory and distributor → compares planned versus executed outlets → examines missed-outlet opportunity and field-time gaps → reviews 100m GPS validity → follows through to Product Mix to see whether weak basket depth compounded the route problem.

## 6. What this delivered — and what has *not* been proven

**Evidence-backed capabilities:** Multi-page analytical report; SQL source transformations; reporting dimensions; clearly displayed KPI dictionary; defined outputs for visit execution, time, GPS and assortment; actual PBIX visual field bindings.

**Business value enabled (not measured impact):** Better diagnosis of unproductive field days; a consistent coaching agenda by hierarchy; clearer distinction between sales output and execution behavior; explicit visibility into location-quality gaps.

**Not claimed:** Revenue uplift, hours saved, adoption %, accuracy improvement, validated weighted performance score or specific turnaround time. None of these before/after metrics was supplied.

## 7. Engineering risks & next iteration

The supplied source is a valuable analytical draft, but it contains **material follow-up items**: date range predicates on DATETIME fields, the definition of an invoice vs unique outlet/visit for GPS counts, 80/20 outlet grouping boundaries, and the undefined weighted score formula. See [Data Quality / Decisions](DATA_QUALITY.md).

For a production-ready next step: move extraction to views/stored procedures with parameters; add a canonical date dimension, normalized per-visit and per-invoice facts, automated reconciliation tests, a semantic TMDL export, and a formal source-of-truth measure catalog. Keep the public portfolio version de-identified.

## Portfolio skills demonstrated

**SQL Server:** CTE-based shaping, window functions, distinct-count controls, invoice normalization, conditional aggregation, GPS trigonometry, hierarchy joins.  
**Power BI:** Executive narrative, chart + detailed matrix experiences, interactive segmentation, diagnostic drilldown, KPI documentation.  
**DAX:** Explicit non-additive aggregation, median-based duration rollups, context-aware numerator/denominator logic, readable time formatting.  
**Business analytics:** Translating field performance operations into operationally actionable measures without overstating causality.
