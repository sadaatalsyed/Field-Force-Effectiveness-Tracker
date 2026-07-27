# Sheet 3 — Market Time & GPS (Weight: 20%)

Part of the **ICE Daily Tracker** — a 4-sheet weighted Power BI scorecard (35/30/20/15%) that evaluates Order Booker (OB) performance in an FMCG distribution context.

This sub-project covers the **Market Time & GPS** sheet: how an Order Booker spends and manages their field time, and how reliable their location data is.

---

## Contents

| File | What's in it |
|---|---|
| [`business-kpis.md`](./business-kpis.md) | Plain-language KPI definitions, formulas, and assumptions — the source of truth for *what* each metric means |
| [`query.sql`](./query.sql) | SQL Server query producing the OrderBooker + Date grain fact table this sheet is built on |
| [`measures.dax`](./measures.dax) | Power BI DAX measures for the matrix visual, including distribution/date-level rollup logic |

---

## Grain

**One row = one Order Booker's performance on one day.**

Sources joined: `SyncLogs` (attendance), `SA_SalesOrdersDump` (productive visits), `NonProductiveCustomers` (non-productive visits), `Customer` (outlet GPS master), `OrderBooker` / `Distribution` (org hierarchy).

---

## Why this sheet needed special aggregation handling

Most KPIs here are **not naturally additive**. A matrix that groups by Distribution (multiple OBs) or by a date range (multiple days) needs subtotal/total rows to mean something real — not just an arithmetic artifact.

Three recurring problems were solved and are documented in `measures.dax`:

1. **Clock-time columns** (Day Start, Day End, First/Last Called At) are full datetimes. A naive `MEDIANX` across multiple dates lets the date component dominate the sort order and returns a meaningless value. Fix: strip the date with `MOD(x, 1)` before taking the median, so only time-of-day is compared.

2. **Duration columns** (Field Time, Trade Time, Shop Time, Active Market Time) must each be aggregated **independently** from their own pre-computed seconds column. It's tempting to derive `Active Market Time = [Median Trade Time] − [Median Idle Time]`, but median is not linear — `MEDIAN(A) − MEDIAN(B) ≠ MEDIAN(A − B)`. Subtracting two independently-aggregated medians produces a synthetic number that no actual OB-day ever experienced.

3. **Ratio/percentage columns** (GPS Compliance %, Shop Time %, % Shops Without GPS) must never be averaged as pre-computed percentages — a low-volume OB's 100% would carry the same weight as a high-volume OB's 60%. These are always recomputed as `SUM(numerator) ÷ SUM(denominator)` at whatever grain the matrix is currently showing.

See `measures.dax` header comments for the full aggregation-strategy table.

---

## Design decisions worth knowing

- **Non-productive visits have no real duration.** The source system stamps `OrderStartTime = OrderCompleteTime = CreatedOn` for them, so any duration formula evaluates to `0` — a data-availability artifact, not a true zero. Shop Time and Median Shop Time are therefore restricted to **productive visits only**.
- **GPS Compliance %'s denominator is `ShopsWithGPS`, not Total Stops** — it measures accuracy only among visits that had GPS data to check, per the original business definition (`Visits within 100m ÷ GPS Shops`). A separate KPI (`% Shops Without GPS`) covers data-coverage gaps against Total Stops.
- **Median Shop Time is a "median of medians"** (SQL computes per OB-day median, DAX takes median of those). This is an approximation — an exact rollup would need a visit-level grain table exposed to Power BI.

---

## Open items

- Exact (non-approximated) median per shop visit, if precision becomes a requirement.
- Data-quality check for OBs whose shifts cross midnight (would distort the `MOD(x,1)` clock-time trick — not expected in this business context, but worth verifying against real data).
- DP-203 / Azure-based re-platforming of this pipeline is a longer-term consideration, tracked separately from this sheet's scope.
