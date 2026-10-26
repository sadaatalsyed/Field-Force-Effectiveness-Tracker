# All 90 extracted DAX measures — visual-to-KPI traceability

> **Provenance:** Every expression below originates from uploaded `DAX(1).txt` TMDL. No formulas here have been reconstructed. Each visual association comes from the separate PBIX report JSON; absence of a reference does not mean measure unused outside this export.

| Section | Exact measure count |
|---|---:|
| Business Rules | 5 |
| Date Table | 1 |
| Org_hierarchy | 2 |
| Sheet1-DailySalesPerformance | 21 |
| Sheet2-RouteExecution | 12 |
| Sheet3-MarketTime&GPS | 39 |
| Sheet4-Product Mix & Brand Performance | 6 |
| Sheet4b-BrandPerformance | 4 |

**Important:** 90 semantic-model measures ≠ 68 reported business KPI definitions. Several measures are helper calculations, formatted duplicates, conditional formatting statuses and business-rule counters.

## Business Rules

| Original DAX measure | Bound report pages (observed) | Visual type(s) |
|---|---|---|
| `Daily Sales KPIs` | KPI Business Rules | advanceCardE03760C5AB684758B56AA29F9E6C257B |
| `Product Mix KPIs` | KPI Business Rules | advanceCardE03760C5AB684758B56AA29F9E6C257B |
| `Route Execution KPIs` | KPI Business Rules | advanceCardE03760C5AB684758B56AA29F9E6C257B |
| `Time Intelligence KPIs` | KPI Business Rules | advanceCardE03760C5AB684758B56AA29F9E6C257B |
| `Total KPIs Defined` | KPI Business Rules | advanceCardE03760C5AB684758B56AA29F9E6C257B |

[See original extracted DAX expressions](../dax/01-business-rules.dax)

## Date Table

| Original DAX measure | Bound report pages (observed) | Visual type(s) |
|---|---|---|
| `Last12Days_Sales` | Not found in extracted report bindings | — |

[See original extracted DAX expressions](../dax/02-date-intelligence.dax)

## Org_hierarchy

| Original DAX measure | Bound report pages (observed) | Visual type(s) |
|---|---|---|
| `ActiveOrderbookers (TM Restricted)` | Not found in extracted report bindings | — |
| `OBs Overall` | Daily Sales (Charts), Daily Sales Performance, Market Time & GPS, Market Time & GPS (Charts), Overview, Product Mix & Brand Performance, Product Mix (Charts), Route Execution & Productivity, Route Execution (Charts) | cardVisual, pivotTable |

[See original extracted DAX expressions](../dax/03-organizational-hierarchy.dax)

## Sheet1-DailySalesPerformance

| Original DAX measure | Bound report pages (observed) | Visual type(s) |
|---|---|---|
| `App Sales (Planned)` | Daily Sales (Charts), Daily Sales Performance, Overview | columnChart, donutChart, pivotTable |
| `App Sales (Planned) %` | Daily Sales (Charts), Daily Sales Performance, Overview | columnChart, pivotTable |
| `App Sales (UnPlanned)` | Daily Sales (Charts), Daily Sales Performance, Overview | columnChart, donutChart, pivotTable |
| `Avg Order Per Outlet (App)` | Daily Sales (Charts), Daily Sales Performance, Overview | cardVisual, pivotTable |
| `Avg Order Per Outlet 20Pct` | Daily Sales (Charts), Daily Sales Performance, Overview | clusteredColumnChart, pivotTable |
| `Avg Order Per Outlet 80Pct` | Daily Sales (Charts), Daily Sales Performance, Overview | clusteredColumnChart, pivotTable |
| `IsInLast12Days` | Daily Sales (Charts), Overview | lineClusteredColumnComboChart |
| `Last12Days_Exec` | Not found in extracted report bindings | — |
| `OB Contribution %` | Daily Sales (Charts) | pivotTable |
| `OBs Worked s1` | Daily Sales (Charts), Daily Sales Performance, Overview | cardVisual, pivotTable |
| `Order vs Execution % (Previous Day)` | Daily Sales (Charts), Daily Sales Performance, Overview | cardVisual, pivotTable |
| `Order vs Execution % (Today)` | Daily Sales (Charts), Daily Sales Performance, Overview | cardVisual, lineClusteredColumnComboChart, pivotTable |
| `Outlets Contributing 20% (BookedSales)` | Daily Sales (Charts), Daily Sales Performance, Overview | hundredPercentStackedBarChart, pivotTable |
| `Outlets Contributing 80% (BookedSales)` | Daily Sales (Charts), Daily Sales Performance, Overview | hundredPercentStackedBarChart, pivotTable |
| `Outlets(80Pct)%` | Daily Sales (Charts), Daily Sales Performance, Overview | decompositionTreeVisual, pivotTable |
| `Previous Day Delivered Value` | Daily Sales (Charts), Daily Sales Performance, Overview | pivotTable |
| `Previous Day Lost Sales` | Daily Sales (Charts), Daily Sales Performance, Overview | cardVisual, pivotTable |
| `Previous Day Order Booked` | Daily Sales (Charts), Daily Sales Performance, Overview | cardVisual, pivotTable |
| `Sales Booked (App)` | Daily Sales (Charts), Daily Sales Performance, Overview | cardVisual, columnChart, pivotTable |
| `Sales Booked (Web)` | Daily Sales (Charts), Daily Sales Performance, Overview | cardVisual, columnChart, pivotTable |
| `Web Sales Value` | Daily Sales (Charts), Daily Sales Performance, Overview | pivotTable |

[See original extracted DAX expressions](../dax/04-daily-sales.dax)

## Sheet2-RouteExecution

| Original DAX measure | Bound report pages (observed) | Visual type(s) |
|---|---|---|
| `Avg Order Prod. Outlets` | Route Execution & Productivity, Route Execution (Charts) | pivotTable |
| `Execution_Status_Flag` | Not found in extracted report bindings | — |
| `Missed Possible order value` | Overview, Route Execution & Productivity, Route Execution (Charts) | cardVisual, decompositionTreeVisual, lineClusteredColumnComboChart, pivotTable |
| `OB Execution Status` | Route Execution (Charts) | pivotTable |
| `OBs Worked s2` | Route Execution & Productivity, Route Execution (Charts) | pivotTable |
| `PJP Compliance %` | Market Time & GPS (Charts), Overview, Route Execution & Productivity, Route Execution (Charts) | cardVisual, clusteredBarChart, clusteredColumnChart, lineClusteredColumnComboChart, pivotTable |
| `PJP Status` | Overview | pivotTable |
| `Planned Productive` | Route Execution & Productivity, Route Execution (Charts) | pivotTable |
| `Productive Outlets over500 bil%` | Overview, Route Execution & Productivity, Route Execution (Charts) | clusteredBarChart, lineClusteredColumnComboChart, pivotTable |
| `Productive Outlets under500 bil%` | Overview, Route Execution & Productivity, Route Execution (Charts) | clusteredBarChart, lineClusteredColumnComboChart, pivotTable |
| `StrikeRate% Overall` | Overview, Route Execution & Productivity, Route Execution (Charts) | cardVisual, clusteredBarChart, clusteredColumnChart, lineClusteredColumnComboChart, pivotTable |
| `StrikeRate% Under 100m` | Route Execution & Productivity, Route Execution (Charts) | pivotTable |

[See original extracted DAX expressions](../dax/05-route-execution.dax)

## Sheet3-MarketTime&GPS

| Original DAX measure | Bound report pages (observed) | Visual type(s) |
|---|---|---|
| `% Shops Without GPS` | Not found in extracted report bindings | — |
| `Active Market Time (HH:MM)` | Market Time & GPS, Market Time & GPS (Charts), Overview | cardVisual, clusteredBarChart, clusteredColumnChart, lineClusteredColumnComboChart, pivotTable |
| `Active Market Time Median` | Market Time & GPS (Charts) | clusteredColumnChart |
| `Avg Stops per Day` | Market Time & GPS (Charts) | pivotTable |
| `Avg Time Between Visits (Minutes)` | Market Time & GPS, Market Time & GPS (Charts) | pivotTable |
| `Avg Time Between Visits (Seconds)` | Not found in extracted report bindings | — |
| `Before/After Field Time (HH:MM)` | Market Time & GPS (Charts) | cardVisual, clusteredColumnChart |
| `Before/After Field Time (seconds)` | Not found in extracted report bindings | — |
| `Data Quality` | Market Time & GPS (Charts) | pivotTable |
| `Day End (Median Time)` | Not found in extracted report bindings | — |
| `Day End (Median Time) Display` | Market Time & GPS, Market Time & GPS (Charts) | cardVisual, pivotTable |
| `Day Start (Median Time)` | Not found in extracted report bindings | — |
| `Day Start (Median Time) Display` | Market Time & GPS, Market Time & GPS (Charts) | cardVisual, pivotTable |
| `Field Time (HH:MM)` | Market Time & GPS (Charts) | clusteredBarChart, clusteredColumnChart, lineClusteredColumnComboChart |
| `Field Time (HH:MM) Derived` | Market Time & GPS, Market Time & GPS (Charts) | cardVisual, clusteredColumnChart, pivotTable |
| `Field Time Median` | Not found in extracted report bindings | — |
| `First Shop Called At (Median Time)` | Not found in extracted report bindings | — |
| `First Shop Called At (Median Time) Display` | Market Time & GPS, Market Time & GPS (Charts) | cardVisual, pivotTable |
| `GPS Compliance %` | Market Time & GPS, Market Time & GPS (Charts), Overview | cardVisual, clusteredColumnChart, lineClusteredColumnComboChart, pivotTable |
| `Last Shop Called At (Median Time)` | Not found in extracted report bindings | — |
| `Last Shop Called At (Median Time) Display` | Market Time & GPS, Market Time & GPS (Charts) | cardVisual, pivotTable |
| `Last Shop Completed At (Median Time)` | Not found in extracted report bindings | — |
| `Last Shop Completed At (Median Time) Display` | Market Time & GPS, Market Time & GPS (Charts) | cardVisual, pivotTable |
| `Longest Idle Period (HH:MM:SS)` | Market Time & GPS, Market Time & GPS (Charts) | cardVisual, clusteredBarChart, clusteredColumnChart, lineClusteredColumnComboChart, pivotTable |
| `Longest Idle Period max` | Market Time & GPS (Charts) | clusteredColumnChart |
| `Median Shop Time (HH:MM:SS)` | Market Time & GPS, Market Time & GPS (Charts) | cardVisual, clusteredBarChart, lineClusteredColumnComboChart, pivotTable |
| `No GPS %` | Market Time & GPS, Market Time & GPS (Charts) | lineClusteredColumnComboChart, pivotTable |
| `OBs Worked s3` | Market Time & GPS, Market Time & GPS (Charts) | pivotTable |
| `Shop Time (HH:MM)` | Market Time & GPS, Market Time & GPS (Charts) | cardVisual, clusteredBarChart, lineClusteredColumnComboChart, pivotTable |
| `Shop Time (Seconds) Derived` | Market Time & GPS (Charts) | lineClusteredColumnComboChart |
| `Shop Time %` | Market Time & GPS, Market Time & GPS (Charts), Product Mix & Brand Performance, Product Mix (Charts) | cardVisual, pivotTable |
| `Shops With GPS` | Market Time & GPS, Market Time & GPS (Charts) | funnel, lineClusteredColumnComboChart, pivotTable |
| `Shops Without GPS` | Market Time & GPS (Charts) | funnel, pivotTable |
| `Total Idle Period (HH:MM)` | Market Time & GPS, Market Time & GPS (Charts) | cardVisual, clusteredBarChart, clusteredColumnChart, lineClusteredColumnComboChart, pivotTable |
| `Total Idle Period (Seconds) Derived` | Not found in extracted report bindings | — |
| `Total Idle Period (Seconds) Median` | Not found in extracted report bindings | — |
| `Trade Time (HH:MM)` | Market Time & GPS (Charts) | cardVisual, clusteredBarChart, clusteredColumnChart, lineClusteredColumnComboChart, pivotTable |
| `Trade Time (HH:MM) Derived` | Market Time & GPS, Market Time & GPS (Charts) | pivotTable |
| `Trade Time Median` | Market Time & GPS (Charts) | clusteredColumnChart |

[See original extracted DAX expressions](../dax/06-market-time-gps.dax)

## Sheet4-Product Mix & Brand Performance

| Original DAX measure | Bound report pages (observed) | Visual type(s) |
|---|---|---|
| `Assortment Status` | Product Mix (Charts) | pivotTable |
| `Avg Brands Per Bill` | Overview, Product Mix & Brand Performance, Product Mix (Charts) | cardVisual, decompositionTreeVisual, pivotTable |
| `Avg Segments Per Bill` | Product Mix & Brand Performance, Product Mix (Charts) | cardVisual, pivotTable |
| `Avg Variance Per Bill` | Product Mix & Brand Performance, Product Mix (Charts) | cardVisual, pivotTable |
| `Cross Brand Selling %` | Overview, Product Mix & Brand Performance, Product Mix (Charts) | cardVisual, decompositionTreeVisual, pivotTable |
| `OBs Worked s4` | Product Mix & Brand Performance, Product Mix (Charts) | pivotTable |

[See original extracted DAX expressions](../dax/07-product-mix.dax)

## Sheet4b-BrandPerformance

| Original DAX measure | Bound report pages (observed) | Visual type(s) |
|---|---|---|
| `1 Piece Lines` | Not found in extracted report bindings | — |
| `2 Piece Lines` | Not found in extracted report bindings | — |
| `3+ Piece Lines` | Not found in extracted report bindings | — |
| `3+ Piece Rate` | Product Mix (Charts) | clusteredBarChart, lineClusteredColumnComboChart |

[See original extracted DAX expressions](../dax/08-brand-piece-bands.dax)