# Visual walkthrough — all 10 observed report pages

Browse the [public-safe schematic gallery](REPORT_GALLERY.md) for five illustrated report-layout previews. They are **not original report screenshots**.

The mappings below come from the **actual report page names and field/measure references found in the uploaded PBIX report definition**, cross-checked against the PDF. They are not guessed visual requirements. The uploaded PDF provides the visual appearance; confidential rows have been kept out of the public repository.

| PDF page | Power BI page | Audience / analytical goal | Confirmed visual patterns |
|---:|---|---|---|
| 1 | KPI Business Rules | All viewers; consistent KPI interpretation | Rules table with formula, assumptions, subtotal logic and date basis |
| 2 | Overview | Directors and regional managers | Regional sales comparisons, KPI matrix, combo trends, donut, funnel, decomposition tree |
| 3 | Daily Sales (Charts) | Sales leadership | Pareto 80/20 composition, App/Web cards, execution trend, orderbooker detail, decomposition |
| 4 | Route Execution (Charts) | Field operations leaders | PJP vs visited trend, small-bill mix, productive visits by role, missed-order opportunity |
| 5 | Market Time & GPS (Charts) | Field execution / audit | GPS availability funnel, idle/market time cards, hierarchy comparisons and trends |
| 6 | Product Mix (Charts) | Category / distribution managers | Brand piece-band distribution, cross-brand %, 3+ rate, product-depth cards |
| 7 | Daily Sales Performance | Analysts and sales managers | Full-width organization-to-OB matrix: booking, delivery, App/Web, 80/20 |
| 8 | Route Execution & Productivity | Distribution managers | Full-width PJP, visits, strikes, 100m, low-bill and productivity matrix |
| 9 | Market Time & GPS | Trade execution leaders | Full-width start/end, field/trade/idle, shop time, distance, GPS matrix |
| 10 | Product Mix & Brand Performance | Sales/category analysts | Full-width brands/segments/variants, piece bands and cross-brand matrix |

## Screenshot ↔ DAX binding examples, verified against PBIX metadata

| Page / visual type | Specific bound fields or measures | What the audience sees |
|---|---|---|
| Overview — regional clustered chart | `PJP Compliance %`, `StrikeRate% Overall`, `GPS Compliance %`, region | A regional comparison across three execution-quality dimensions |
| Overview — decomposition tree | `Cross Brand Selling %`, `Avg Brands Per Bill`, region/territory/distributor/OB | Explaining where cross-brand selling differs |
| Daily Sales — 100% stacked bar | `Outlets Contributing 80% (BookedSales)`, `Outlets Contributing 20% (BookedSales)` | Concentration of outlet contribution to booked value |
| Daily Sales — combo trend | `LostSalesDueToOperationsPKR`, `TodayOrderBookedPKR`, `Order vs Execution % (Today)` | Booking-delivery execution and operational loss signals |
| Route — matrix | `PlannedShopsInPJP`, `TotalVisitsPlanned_InclNonProductive`, `PJP Compliance %`, `ProductiveOutletsOverall` | Planning versus actual visitation and conversion |
| Route — trend | `ProductiveCallsPerHour`, `PlannedShopsInPJP`, `TotalVisitsPlanned_InclNonProductive` | Productivity alongside planned route activity |
| Market Time — time comparison | `Field Time (HH:MM) Derived`, `Trade Time Median`, `Active Market Time Median`, `Longest Idle Period max` | Separating field presence from useful work |
| Market Time — GPS funnel | `TotalStopsMade`, `Shops With GPS`, `Shops Without GPS`, `ProductiveStopsMade`, `ValidGPSCount` | Funnel of availability/accuracy/productive stops |
| Product Mix — piece bands | `Brand`, `PieceBand`, `Lines` | 1 / 2 / 3+ pieces by brand |
| Product Mix — depth bar | `Brand`, `3+ Piece Rate` | Basket-depth comparison |
| Product Mix — scorecard | `Avg Brands Per Bill`, `Avg Segments Per Bill`, `Avg Variance Per Bill`, `Cross Brand Selling %` | Bill depth and breadth |

**Report metadata says how a measure is used in visuals, not what its DAX expression is.** Some visuals bind source columns directly, while others bind DAX measures. The actual semantic expressions need TMDL export for 100% accuracy.

## Narrative: reading the report as a manager

Start from Overview, identify which regional measure is off-target, enter the relevant domain's chart page, then open the corresponding detailed matrix. The hierarchy is not just navigation — it is the reconciliation path from aggregate symptoms to a specific OB/day.

## Visual gallery status

A set of **10 rendered images from the provided PDF**, including redacted detail-matrix screenshots, is included in the accompanying local asset package prepared for manual binary upload. This GitHub connector can write source text but does **not** accept local PNG/WEBP bytes in this workflow, so the true screenshots are not misrepresented as already hosted here. The SVGs in the gallery are **original explanatory illustrations, not the PDF screenshots**.
