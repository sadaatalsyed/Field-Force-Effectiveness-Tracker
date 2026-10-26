-- SQL source as supplied; requires environment-specific review before execution.
  /* ============================================================================================
   SHEET 4 - PRODUCT MIX & BRAND PERFORMANCE (15%)  —  CORRECTED / COMPLETE VERSION
   ============================================================================================
   Fixes vs the draft you shared:
   1. Piece-band aggregation now happens PER BILL (SUM of pieces per InvoiceCode+Brand),
      not per raw line item. This avoids double-counting when a bill has multiple line
      items for the same brand.
   2. All 5 named-brand piece bands (CAPRI, HYPRO, OPAL, CAPRI Handwash, HYPE) are now
      PIVOTED into actual output columns using conditional aggregation — nothing is left
      as an unused CTE / "build in Power BI" comment.
   3. BrandValue CTE now applies the same TotalPiecesDelivered > 0 filter as OrderLines,
      so it's consistent with the rest of the sheet.
   4. Date range parameterized as variables at the top instead of hardcoded literals
      scattered through the query — change once, applies everywhere.
   5. "Score of the Day (Weighted)" is STILL a business-logic gap, not a SQL gap — there
      is no weighting formula defined anywhere in the requirement or the original query
      (same open item flagged on Sheets 2 & 3). I have NOT invented a formula. Once you
      get the weights/definition from the client, this becomes a straightforward extra
      column and I can add it in five minutes.
   ============================================================================================
   BEFORE RUNNING: confirm exact Brand.Title spelling for the 5 brands below. If spelling
   doesn't match Brand table exactly (case, spacing), these columns will silently return 0
   instead of erroring — verify with:
       SELECT DISTINCT Title FROM Brand WHERE Title LIKE '%CAPRI%' OR Title LIKE '%HYPRO%'
                                            OR Title LIKE '%OPAL%'  OR Title LIKE '%HYPE%';
   ============================================================================================ */

DECLARE @StartDate DATE = '2026-04-01';
DECLARE @EndDate   DATE = Cast (GetDate()-1 as Date);--'2026-06-01';   -- exclusive upper bound

WITH OrderLines AS
(
    SELECT
        CAST(ss.DeliveryDate AS DATE) AS OrderDate,
        d.Code AS DistributionCode, ob.Code AS OBCode, ob.Name AS OrderBooker,
        ss.InvoiceCode, ss.CustomerID,
        p.ProductID, p.SegmentID, p.BrandID, b.Title AS BrandName,
        ss.TotalPiecesDelivered TotalPiecesDelivered
    FROM SA_SalesOrdersDump ss
    INNER JOIN Product p      ON p.ProductID = ss.ProductID
    LEFT JOIN Brand b         ON b.BrandID = p.BrandID
    INNER JOIN OrderBooker ob ON ob.OrderBookerID = ss.OrderBookerID
    INNER JOIN Distribution d ON d.DistributionID = ob.DistributionID
    WHERE ss.Status = 'Settled'
      --AND ss.Type   = 'Sales'
      AND ss.DeliveryDate >= @StartDate AND ss.DeliveryDate <= @EndDate
      AND ss.TotalPiecesDelivered > 0

),


PerBill AS
(
    SELECT
        OrderDate, DistributionCode, OBCode, OrderBooker, InvoiceCode, CustomerID,
        COUNT(DISTINCT BrandID)   AS BrandsInBill,
        COUNT(DISTINCT SegmentID) AS SegmentsInBill,
        COUNT(DISTINCT ProductID) AS VariantsInBill
    FROM OrderLines
    GROUP BY OrderDate, DistributionCode, OBCode, OrderBooker, InvoiceCode, CustomerID
),


MainKPIs AS
(
    SELECT
        pb.OrderDate, pb.DistributionCode, pb.OBCode, pb.OrderBooker,

        SUM(pb.BrandsInBill)                                        AS TotalBrandsInBill,
        SUM(pb.SegmentsInBill)                                      AS TotalSegmentsInBill,
        SUM(pb.VariantsInBill)                                      AS TotalVariantsInBill,
        COUNT(*)                                                    AS BillCount,
        COUNT(CASE WHEN pb.BrandsInBill > 1 THEN 1 END)             AS CrossBrandBillCount

    FROM PerBill pb
    GROUP BY pb.OrderDate, pb.DistributionCode, pb.OBCode, pb.OrderBooker
),

-- Per-bill, per-named-brand total pieces (fixes the double-counting issue from the draft)
BrandBillTotals AS
(
    SELECT
        OrderDate, DistributionCode, OBCode, OrderBooker, InvoiceCode, BrandName,
        SUM(TotalPiecesDelivered) AS TotalPieces
    FROM OrderLines
    WHERE 
    BrandID IN (306,305,309,313,308)
     --BrandName IN ('CAPRI','HYPRO','OPAL','CAPRI Handwash','HYPE')
    GROUP BY OrderDate, DistributionCode, OBCode, OrderBooker, InvoiceCode, BrandName
),

-- Piece band per bill per brand
BrandPieceBands AS
(
    SELECT
        OrderDate, DistributionCode, OBCode, OrderBooker, InvoiceCode, BrandName,
        CASE WHEN TotalPieces = 1 THEN '1 Piece'
             WHEN TotalPieces = 2 THEN '2 Pieces'
             ELSE '3+ Pieces' END AS PieceBand
    FROM BrandBillTotals
),

-- Pivoted output: one row per OB/day, one column per Brand x Band (15 columns total)
PieceBandPivot AS
(
    SELECT
        OrderDate, DistributionCode, OBCode, OrderBooker,

        COUNT(CASE WHEN BrandName like '%Capri Soap%' AND PieceBand = '1 Piece'   THEN 1 END) AS CAPRI_1Piece,
        COUNT(CASE WHEN BrandName like '%Capri Soap%' AND PieceBand = '2 Pieces'  THEN 1 END) AS CAPRI_2Pieces,
        COUNT(CASE WHEN BrandName like '%Capri Soap%' AND PieceBand = '3+ Pieces' THEN 1 END) AS CAPRI_3PlusPieces,

        COUNT(CASE WHEN BrandName like '%Hypro%' AND PieceBand = '1 Piece'   THEN 1 END) AS HYPRO_1Piece,
        COUNT(CASE WHEN BrandName like '%Hypro%' AND PieceBand = '2 Pieces'  THEN 1 END) AS HYPRO_2Pieces,
        COUNT(CASE WHEN BrandName like '%Hypro%' AND PieceBand = '3+ Pieces' THEN 1 END) AS HYPRO_3PlusPieces,

        COUNT(CASE WHEN BrandName like '%Opal%' AND PieceBand = '1 Piece'   THEN 1 END) AS OPAL_1Piece,
        COUNT(CASE WHEN BrandName like '%Opal%' AND PieceBand = '2 Pieces'  THEN 1 END) AS OPAL_2Pieces,
        COUNT(CASE WHEN BrandName like '%Opal%' AND PieceBand = '3+ Pieces' THEN 1 END) AS OPAL_3PlusPieces,

        COUNT(CASE WHEN BrandName like '%Capri Hand Wash%' AND PieceBand = '1 Piece'   THEN 1 END) AS CAPRIHandwash_1Piece,
        COUNT(CASE WHEN BrandName like '%Capri Hand Wash%' AND PieceBand = '2 Pieces'  THEN 1 END) AS CAPRIHandwash_2Pieces,
        COUNT(CASE WHEN BrandName like '%Capri Hand Wash%' AND PieceBand = '3+ Pieces' THEN 1 END) AS CAPRIHandwash_3PlusPieces,

        COUNT(CASE WHEN BrandName like '%Hype%' AND PieceBand = '1 Piece'   THEN 1 END) AS HYPE_1Piece,
        COUNT(CASE WHEN BrandName like '%Hype%' AND PieceBand = '2 Pieces'  THEN 1 END) AS HYPE_2Pieces,
        COUNT(CASE WHEN BrandName like '%Hype%' AND PieceBand = '3+ Pieces' THEN 1 END) AS HYPE_3PlusPieces

    FROM BrandPieceBands
    GROUP BY OrderDate, DistributionCode, OBCode, OrderBooker
)

-- ============================================================================================
-- FINAL OUTPUT: one row per OrderBooker per day, all 8 required KPIs (Score of the Day pending)
-- ============================================================================================
SELECT
    mk.OrderDate,
    mk.DistributionCode,
    mk.OBCode,
    mk.OrderBooker,

    -- NULL AS ScoreOfTheDay,   -- ⚠ add once weighting formula is confirmed by client

    mk.TotalBrandsInBill,
    mk.TotalSegmentsInBill,
    mk.TotalVariantsInBill,
    mk.BillCount,
    mk.CrossBrandBillCount,   -- bonus KPI, not in original 9 — confirm with client if wanted

    ISNULL(pv.CAPRI_1Piece, 0)          AS CAPRI_1Piece,
    ISNULL(pv.CAPRI_2Pieces, 0)         AS CAPRI_2Pieces,
    ISNULL(pv.CAPRI_3PlusPieces, 0)     AS CAPRI_3PlusPieces,

    ISNULL(pv.HYPRO_1Piece, 0)          AS HYPRO_1Piece,
    ISNULL(pv.HYPRO_2Pieces, 0)         AS HYPRO_2Pieces,
    ISNULL(pv.HYPRO_3PlusPieces, 0)     AS HYPRO_3PlusPieces,

    ISNULL(pv.OPAL_1Piece, 0)           AS OPAL_1Piece,
    ISNULL(pv.OPAL_2Pieces, 0)          AS OPAL_2Pieces,
    ISNULL(pv.OPAL_3PlusPieces, 0)      AS OPAL_3PlusPieces,

    ISNULL(pv.CAPRIHandwash_1Piece, 0)      AS CAPRIHandwash_1Piece,
    ISNULL(pv.CAPRIHandwash_2Pieces, 0)     AS CAPRIHandwash_2Pieces,
    ISNULL(pv.CAPRIHandwash_3PlusPieces, 0) AS CAPRIHandwash_3PlusPieces,

    ISNULL(pv.HYPE_1Piece, 0)           AS HYPE_1Piece,
    ISNULL(pv.HYPE_2Pieces, 0)          AS HYPE_2Pieces,
    ISNULL(pv.HYPE_3PlusPieces, 0)      AS HYPE_3PlusPieces

FROM MainKPIs mk
LEFT JOIN PieceBandPivot pv
    ON  pv.OrderDate         = mk.OrderDate
    AND pv.DistributionCode  = mk.DistributionCode
    AND pv.OBCode            = mk.OBCode
ORDER BY mk.OrderDate, mk.DistributionCode, mk.OBCode;


--/* ============================================================================================
--   OPTIONAL / BONUS QUERIES (not in the original 9-KPI list — keep only if client confirms)
--   ============================================================================================ */

---- Brand value by OB/day (pieces > 0 filter now consistent with OrderLines)
--WITH BrandValue AS
--(
--    SELECT
--        CAST(ss.InvoiceDate AS DATE) AS OrderDate,
--        d.Code AS DistributionCode, ob.Code AS OBCode, ob.Name AS OrderBooker,
--        b.Title AS BrandName,
--        SUM(ss.NetAmount) AS BrandValue
--    FROM SA_SalesDataDump ss
--    INNER JOIN Product p      ON p.ProductID = ss.ProductID
--    LEFT JOIN Brand b         ON b.BrandID = p.BrandID
--    INNER JOIN OrderBooker ob ON ob.OrderBookerID = ss.OrderBookerID
--    INNER JOIN Distribution d ON d.DistributionID = ob.DistributionID
--    WHERE ss.Status = 'Settled'
--      AND ss.Type   = 'Sales'
--      AND ss.TotalPiecesDelivered > 0
--      AND ss.InvoiceDate >= @StartDate AND ss.InvoiceDate < @EndDate
--    GROUP BY CAST(ss.InvoiceDate AS DATE), d.Code, ob.Code, ob.Name, b.Title
--)
--SELECT OrderDate, DistributionCode, OBCode, OrderBooker, BrandName, BrandValue
--FROM
--(
--    SELECT *,
--           ROW_NUMBER() OVER (PARTITION BY OrderDate, OBCode ORDER BY BrandValue DESC) AS rn
--    FROM BrandValue
--) ranked
--WHERE rn = 1
--ORDER BY OrderDate, DistributionCode, OBCode;

---- Brand Penetration % — needs Sheet 1's AppOutletsVisited as denominator.
---- Join BrandValue-level CustomerID counts (distinct outlets buying brand X) against
---- Sheet 1's DailySales.AppOutletsVisited. Left out here deliberately to avoid duplicating
---- Sheet 1 logic — reuse that sheet's output rather than recomputing it.