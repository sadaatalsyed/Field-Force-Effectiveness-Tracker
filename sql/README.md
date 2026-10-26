# SQL workstreams — source-faithful drafts

These are the six attached SQL source query files preserved for architecture and code review; they were **not** executed against the client's database by this repository workflow.

| Workstream | File | Business intent |
|---|---|---|
| Daily sales | [01](01-daily-sales-performance.sql) | Order Booker's booked vs delivered, app/web and outlet Pareto |
| Route execution | [02](02-route-execution-productivity.sql) | Planned route and productive/nonproductive visits |
| Market time + GPS | [03](03-market-time-gps.sql) | Sync logs, visit sequencing and GPS/geodesic check |
| Product mix | [04](04-product-mix.sql) | Bill-level distinct assortment and brand piece buckets |
| Brand bands | [05](05-brand-piece-bands.sql) | Brand x 1/2/3+ piece chart dataset |
| Hierarchy | [06](06-organizational-hierarchy.sql) | Distribution hierarchy and team-level assignments |

The source queries use environment-specific tables, codes and some hardcoded date boundaries. Refer to [quality review](../docs/DATA_QUALITY.md) before parameterization, deployment or relying on any calculated score.
