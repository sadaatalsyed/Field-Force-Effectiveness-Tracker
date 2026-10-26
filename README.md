<p align="center"><img src="assets/ice-hero.svg" alt="ICE Field Force Effectiveness Tracker" width="100%"></p>

# ICE Tracker — Field Force Effectiveness Intelligence

> **A portfolio case study of an FMCG order-booker field-execution analytics solution:** SQL Server + Power BI + **90 original TMDL DAX measures**, with screenshots captured from the actual dashboard.

![Power BI](https://img.shields.io/badge/Power%20BI-Report-F2C811) ![SQL Server](https://img.shields.io/badge/SQL%20Server-Analytics-2E6EAE) ![DAX](https://img.shields.io/badge/90-Original%20DAX%20Measures-0F766E) ![Case Study](https://img.shields.io/badge/10-Actual%20Report%20Pages-17375E)

## The business problem

In FMCG direct-store distribution, **sales targets don't explain field behavior**. Managers need to understand whether orderbookers followed their PJP route, made enough productive outlet visits, spent enough time in trade, collected accurate GPS evidence, converted visits into orders and grew the breadth of brands per bill.

The solution connects *Daily Sales*, *Route Execution*, *Market Time & GPS*, and *Product Mix & Brand Performance* in one hierarchy-aware reporting experience.

### Executive Overview — original dashboard

![Original executive overview from Power BI PDF](assets/screenshots/02-executive-overview.jpg)

Explore the **[complete business case study with all 10 real screenshots](docs/CASE_STUDY.md)**.

## Four performance lenses

| Domain | Questions answered | Actual screenshot |
|---|---|---|
| **Daily Sales Performance** | What was booked vs delivered? App/Web contribution? Concentration of sales value? | [View actual page](assets/screenshots/03-daily-sales-charts.jpg) |
| **Route Execution & Productivity** | Did field staff follow the PJP? How many planned, productive, unplanned and nonproductive outlets? | [View actual page](assets/screenshots/04-route-execution-charts.jpg) |
| **Market Time & GPS** | How much market time was used? Are visits within 100m of outlet GPS? What are idle gaps? | [View actual page](assets/screenshots/05-market-time-gps-charts.jpg) |
| **Product Mix & Brand Performance** | How many distinct brands, segments and products per bill? Are orders 1/2/3+ pieces? | [View actual page](assets/screenshots/06-product-mix-charts.jpg) |

### Visual evidence

| Sales | Route |
|---|---|
| ![Actual Daily Sales Page](assets/screenshots/03-daily-sales-charts.jpg) | ![Actual Route Page](assets/screenshots/04-route-execution-charts.jpg) |
| Market Time & GPS | Product Mix |
| ![Actual Market Time Page](assets/screenshots/05-market-time-gps-charts.jpg) | ![Actual Product Mix Page](assets/screenshots/06-product-mix-charts.jpg) |

*These are cropped/resized **genuine report exports**. Confidential source rows and selected identifiers have been redacted; the graphics are not synthetic replacements.*

## Repository navigation

| Folder or document | Purpose |
|---|---|
| [Case study](docs/CASE_STUDY.md) | Business context, four analytical domains, visuals, engineering decisions, limitations |
| [Actual 10-page gallery](docs/REPORT_GALLERY.md) | All original Power BI PDF screenshots, including KPI rules and detailed matrix pages |
| [90 original DAX measures](dax/original-tmdl-export.txt) | Verbatim source TMDL extracted from supplied file |
| [DAX explained](docs/DAX_EXPLAINED.md) | Actual formulas, use in visuals, aggregation rules and QA findings |
| [90-measure visual mapping](docs/MEASURE_VISUAL_MAPPING.md) | Measures mapped to report pages/visual types from PBIX JSON |
| [KPI dictionary](docs/KPI_DICTIONARY.md) | Business KPI definitions and assumptions from source export |
| [Six SQL queries](sql/) | Daily Sales, Route, Market/GPS, Product Mix, Brand bands and hierarchy |
| [Architecture](docs/ARCHITECTURE.md) | Source → SQL grain → semantic model → dashboards |
| [Data quality](docs/DATA_QUALITY.md) | Date boundaries, GPS denominator, threshold review and limitations |


## Decisions and nuances worth discussing in an interview

**Invoice grain:** aggregate lines by InvoiceCode before computing per-bill depth and sales totals. **Visit grain:** distinct shops and visit events are different. **Percentages:** aggregate numerator/denominator before division, rather than averaging percentages. **Time medians:** duration seconds differ from clock-time medians. **GPS:** accuracy within 100m must be separated from GPS coverage. **Status metrics:** original threshold DAX contains a potential 95 vs 0.95 mismatch; see quality audit.

The repository is a **documented real-report portfolio case study**. It is not a live operational environment. No unvalidated ROI or performance claims are made. Exact source measures are reproduced unchanged; suggested corrections are documented separately.
