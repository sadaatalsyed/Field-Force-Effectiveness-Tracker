-- SQL source as supplied; requires environment-specific review before execution.


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
)

SELECT
    OrderDate, DistributionCode, OBCode, OrderBooker,
    BrandName AS Brand,
    PieceBand,
    COUNT(*) AS Lines
FROM BrandPieceBands
GROUP BY OrderDate, DistributionCode, OBCode, OrderBooker, BrandName, PieceBand
ORDER BY OrderDate, DistributionCode, OBCode, BrandName, PieceBand;
