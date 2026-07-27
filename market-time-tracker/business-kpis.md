# Business KPI Definitions — Market Time & GPS

Grain: **OrderBooker + Date** (one row = one OB's performance for one day).

| KPI | Business Logic | Formula | Assumptions |
|---|---|---|---|
| Total Time Spent in Field | Duration device was active in field, sync-down to sync-up | `DayEnd − DayStart` | First successful SyncDown to last successful SyncUp, selected day |
| First Shop Called At | Start time of first visit | Earliest Visit Start Time | `OrderStartTime` for productive, `CreatedOn` for non-productive |
| Last Shop Called At | End time of last visit | Latest Visit End Time | `OrderCompleteTime` for productive, `CreatedOn` for non-productive |
| Total Time Spent in Trade | First visit start to last visit end | `Last Visit End − First Visit Start` | Includes Productive + Non-Productive; NonProductive Start=Complete=CreatedOn |
| Total Distance Covered (Kms) | GPS distance across consecutive visits | Σ Haversine distance | Visit-to-visit GPS; stops without GPS ignored |
| Total Inactive/Idle Period | Excess gap beyond 5-min travel allowance | `Σ Max(0, Gap − 5min)` | Applies across Productive + Non-Productive |
| Longest Idle Period | Largest single idle gap in the day | `Max(Idle Gap)` | Idle threshold (5 min) applied before max |
| Active Market Time | Trade time minus idle time | `Trade Time − Idle Time` | Derived per OB-day, not from independently-aggregated components |
| Avg Time Between Visits | Average gap between consecutive visits | `Total Gap Time ÷ (Stops − 1)` | Requires ≥ 2 stops |
| Total Time Spent in Shops | Actual time inside shop (excl. travel/idle) | `Σ (Visit End − Visit Start)` | **Productive visits only** — non-productive has no real start/end |
| Median Time Spent per Shop | Typical duration per shop visit | `Median(Visit Duration)` | Productive visits only |
| GPS Compliance % | % of GPS visits within accuracy threshold | `(Visits within 100m ÷ GPS Shops) × 100` | Only visits where both outlet GPS and visit GPS exist |
| Shops Visited with GPS | Count of visits with valid captured GPS | `Count(Visits with GPS)` | GPS successfully recorded |
| Shops Visited without GPS | Count of visits missing GPS | `Count(Visits without GPS)` | Includes missing/invalid GPS |
| % Shops without GPS | % of total visits missing GPS | `(No-GPS Shops ÷ Total Stops) × 100` | Total Stops = Productive + Non-Productive |
| % Time in Shops for Sales Call | % of field time spent transacting | `(Shop Time ÷ Field Time) × 100` | Based on productive visit duration only |
| Total Stops Made | Unique outlets visited | `Count(Distinct Outlets)` | Productive + Non-Productive, Planned + Unplanned, any invoice status |

---

## Why NonProductive visits don't get a Shop Time

`NonProductiveCustomers` only captures a single `CreatedOn` timestamp per visit — there's no separate "arrival" and "departure" event like a productive order has. Setting `OrderStartTime = OrderCompleteTime = CreatedOn` for these rows means any duration formula on them evaluates to exactly `0`.

That `0` is not a real "zero time spent" — it's a data-availability signal, not an observed value. Including it in Shop Time / Median Shop Time averages would silently deflate those KPIs in proportion to how many non-productive visits exist, without any true underlying data. This is why **Shop Time and Median Time per Shop are restricted to Productive visits only** — a deliberate design decision, not an oversight.

Fixing this properly would require the source mobile app to capture separate arrival/departure timestamps for non-productive visits too — a data-capture change, not a SQL/DAX one.
