# Data quality review and unresolved decisions

This is a **code-review register**, not a claim that every issue affects the production report. No database connection or reconciliation dataset was supplied.

| Priority | Finding in supplied SQL / DAX | Why it matters | Recommended test / resolution |
|---|---|---|---|
| High | Some SQL predicates filter a `datetime` with `<= CAST(GETDATE()-1 AS date)` | This includes midnight only on the end date, potentially excluding most of that date | Use `EventDate >= @Start AND EventDate < DATEADD(day,1,@End)` |
| High | Booked, Delivered, Route, Market use different event-date columns | "Same day" comparisons can diverge | Explicit date role: invoice/booked/delivery/created; reconcile cutoffs |
| High | GPS query counts distinct customers while field visits may repeat | A repeat visit within 100m might disappear from numerator/denominator | Define visit/event key and separately offer unique-outlet KPI |
| High | GPS "ShopsWithGPS" in one query is based on outlet master coordinates | Coverage of reference outlet GPS is not the same as captured visit GPS | Expose both flags, compare captured and master coordinates, handle NULLs |
| High | **Score of the Day (Weighted)** has no source-approved calculation | Publishing a composite KPI would be fabricated | Obtain approved weights, component normalizations and blank policy |
| Medium | Route query has `AND c.Active = 1` commented out | Scheduled shop universe may include inactive master records | Confirm definition of eligible planned shops |
| Medium | Productive under/over 500 uses `COUNT(DISTINCT CustomerID)` separately per invoice band | A customer can fall in **both** bands if they place >1 order | Choose per-invoice or aggregate-per-customer band policy |
| Medium | Brand piece bands depend on exact `Brand.Title` pattern and hardcoded IDs | New/mismatched titles silently produce zero counts | Move to explicit controlled BrandID mapping & tests |
| Medium | 80/20 Pareto boundary includes the crossing outlet in top-80 | May exceed 80% due to a large outlet and ranking ties | Document crossing-outlet and tie policy with stakeholder |
| Medium | SQL Market Time removes stale timestamps **before sequencing**, while some other calculations still rely on aggregation row counts | Stale visit timestamps and NULL lat/lon can distort comparison denominators | Add QA count and rejected-row audit fields |
| Medium | Median of OB-day medians != median across all visits | Portfolio median shop duration may be statistically approximate | Preserve visit-grain table for true visit-weighted median |
| Medium | Several existing DAX display measures return `"-"` / appended `"%"` | Text measures cannot reliably drive numeric graphs | Separate numeric and formatted display measures |
| Medium | SQL hierarchy assigns `TOP (1)` manager by name after location matches | Overlapping manager territories may assign arbitrarily | Model effective-dated manager ownership or explicit allocation |
| Low | `CAST(datecolumn AS DATE)` in WHERE | May reduce predicate sargability on indexed datetime fields | Rewrite as half-open datetime range |

## Proposed automated reconciliation tests

1. **Invoice-grain test:** SUM raw invoice-line NetAmount equals aggregated InvoiceNetAmount by InvoiceCode and day (treat joins/status consistently).
2. **Visit-grain test:** PJP shops, unique visited outlets and visit events have separate counts, with defined duplicate rules.
3. **Product mix bucket test:** Every eligible invoice-brand combination belongs to exactly one of 1 / 2 / 3+ piece bands.
4. **Temporal test:** Spot-check prior day, month-end and DST-midnight edge cases. Distinguish appointment/sync/created/delivery dates.
5. **GPS test:** Feed near/far/missing/stale samples through the same 100-metre geodesic logic as SQL.
6. **Subtotal test:** Manually recalculate ratio of sums, median of daily durations and max idle in a 2-OB × 2-day fixture.
7. **Hierarchy test:** No duplicate OB × day row after organization joins and no silent unmapped manager.
8. **Status test:** Confirm whether `Open`/`Pending` ever settle later and whether 'lost' is a temporary operational backlog.

## Publishing policy

Never commit credentials, raw operational exports, original client PBIX, identifiable employee activity records, or unredacted client performance screenshots to a public portfolio. Use redacted/synthetic demonstrations and strip connection strings, server/database locations, real personnel names and confidential identifiers from any exported TMDL.
