# Source provenance and limitations

- **DAX expressions:** exact original TMDL expressions supplied as `DAX(1).txt`; **90 measures / 8 tables**, not approximations. Retained verbatim at [`dax/original-tmdl-export.txt`](../dax/original-tmdl-export.txt).
- **Power BI visual metadata:** obtained from report-definition JSON within uploaded `ICE Tracker(1).pbix`; maps measure names to visual types and report pages. The mapping is a reference graph, not runtime telemetry.
- **Report screenshots:** genuine pages from uploaded `ICE Tracker (6).pdf`, presented as redacted public-display captures (10 images). Unlike previous schematic previews, these are original report visuals.
- **SQL:** six user-supplied queries preserved from source documents. Without a live database, data correctness and execution plans are not independently validated.
- **KPI rules:** PDF cover counts **68** KPI definitions (16 / 15 / 18 / 19). Some detailed rules are clipped; the semantic model separately has 90 measures including helper metrics.
- **Known DAX QA:** `Execution_Status_Flag` uses threshold 95 while `OB Execution Status` uses .95; `Field Time Median` computes a difference of median clocks; text and numeric mixes require review. Original formulas are never silently rewritten.
- **Privacy:** original report includes real business metrics, personnel and client branding. Screenshots are redacted in part. Review permission before making raw reporting data accessible beyond project owners.
- **Results:** no validated performance uplift, time saved, ROI or adoption-rate study was provided.