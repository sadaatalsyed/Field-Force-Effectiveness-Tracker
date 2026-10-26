-- SQL source as supplied; requires environment-specific review before execution.

WITH InvoiceHeader AS
(
    SELECT
        ss.InvoiceCode,
        (ss.CustomerID)                          AS CustomerID,
        (ss.OrderBookerID)                       AS OrderBookerID,
        (ss.Status)                              AS Status,
        (ss.RouteName)                           AS RouteName,
        (ss.Synchronized)                        AS Synchronized,        -- NEW column, see note above
        (CAST(ss.DeliveryDate AS DATE))          AS OrderDate,
        SUM(ss.NetAmount)                           AS InvoiceNetAmount    -- FIX: SUM, not MIN
    FROM SA_SalesOrdersDump ss
    WHERE 1=1
    --ss.Type = 'Sales'                                            -- exclude Returns
      AND 
      ss.DeliveryDate >= '2026-04-01' AND ss.DeliveryDate <=Cast(GetDate()-1 as Date)
    GROUP BY ss.InvoiceCode,ss.CustomerID,ss.OrderBookerID,ss.Status,ss.RouteName,ss.Synchronized,ss.DeliveryDate
),

--Select * from InvoiceHeader


SalesSplit AS
(
    SELECT
        OrderDate,
        OrderBookerID,
        CustomerID,
        CASE WHEN RouteName = 'Unplaned Route' OR RouteName IS NULL THEN 0 ELSE 1 END AS IsPlanned,
        CASE WHEN Synchronized = 1 THEN 1 ELSE 0 END                                  AS IsApp,
        Status,
        InvoiceNetAmount AS NetAmount
    FROM InvoiceHeader
),

--Select * from SalesSplit


DailySales AS
(
    SELECT
        OrderDate, OrderBookerID,

        -- Booked (Open+Pending+Settled) - all channels - basis for Previous Day figures
        SUM(CASE WHEN Status IN ('Open','Pending','Settled') THEN NetAmount ELSE 0 END) AS OrderBookedValueTotal,
        SUM(CASE WHEN Status IN ('Open','Pending','Settled') THEN 1 ELSE 0 END)         AS BookedOrdersCountTotal,
        SUM(CASE WHEN Status = 'Settled' THEN NetAmount ELSE 0 END)                     AS TotalSalesDelivered,
        SUM(CASE WHEN Status = 'Settled' THEN 1 ELSE 0 END)                             AS DeliveredOrdersCountTotal,
        SUM(CASE WHEN Status IN ('Open','Pending') THEN NetAmount ELSE 0 END) AS LostSalesDueToOperations,

        -- "For the day" - App-specific (Booked basis)
        SUM(CASE WHEN IsApp = 1 AND Status IN ('Open','Pending','Settled') THEN NetAmount ELSE 0 END) AS TotalAppSalesBooked,
        SUM(CASE WHEN IsApp = 0 AND Status IN ('Open','Pending','Settled') THEN NetAmount ELSE 0 END) AS TotalWebSalesBooked,
        COUNT(DISTINCT CASE WHEN IsApp = 1 AND Status IN ('Open','Pending','Settled') THEN CustomerID END) AS AppOutletsVisited,
        COUNT(DISTINCT CASE WHEN IsApp = 0 AND Status IN ('Open','Pending','Settled') THEN CustomerID END) AS WebOutletsVisited,
        SUM(CASE WHEN IsApp = 0 AND Status IN ('Settled') THEN NetAmount ELSE 0 END) AS WebSalesDelivered,
        SUM(CASE  WHEN IsApp = 1 AND Status = 'Settled'   THEN NetAmount ELSE 0 END) AS TotalAppSalesDelivered,

        SUM(CASE WHEN IsApp = 1 AND IsPlanned = 1 AND Status IN ('Open','Pending','Settled') THEN NetAmount ELSE 0 END) AS AppSalesPlanned,
        SUM(CASE WHEN IsApp = 1 AND IsPlanned = 0 AND Status IN ('Open','Pending','Settled') THEN NetAmount ELSE 0 END) AS AppSalesUnplanned
    FROM SalesSplit
    GROUP BY OrderDate, OrderBookerID
),


--Select * from DailySales

-- 80/20 Pareto - "for the day", Booked basis, all channels (per KPI wording, not App-only)
OutletValues AS
(
    SELECT OrderDate, OrderBookerID, CustomerID, SUM(NetAmount) AS OutletValue
    FROM SalesSplit
    WHERE Status IN ('Open','Pending','Settled')
    GROUP BY OrderDate, OrderBookerID, CustomerID
    
),

RankedOutlets AS
(
    SELECT *,
        SUM(OutletValue) OVER (PARTITION BY OrderDate, OrderBookerID ORDER BY OutletValue DESC
                                ROWS UNBOUNDED PRECEDING) AS RunningValue,
        SUM(OutletValue) OVER (PARTITION BY OrderDate, OrderBookerID) AS TotalValue
    FROM OutletValues
),


--Select * from RankedOutlets
ParetoFlagged AS
(
    SELECT *,
        CASE WHEN RunningValue - OutletValue < 0.8 * TotalValue THEN 'Top80' ELSE 'Bottom20' END AS ParetoGroup
    FROM RankedOutlets
),
ParetoSummary AS
(
    SELECT
        OrderDate, OrderBookerID,
        COUNT(CASE WHEN ParetoGroup = 'Top80' THEN 1 END)             AS OutletsContributing80Pct,
        SUM(CASE WHEN ParetoGroup = 'Top80' THEN OutletValue END)     AS ValueFromTop80PctOutlets,
        COUNT(CASE WHEN ParetoGroup = 'Bottom20' THEN 1 END)          AS OutletsContributing20Pct,
        SUM(CASE WHEN ParetoGroup = 'Bottom20' THEN OutletValue END)  AS ValueFromBottom20PctOutlets,
        COUNT(*)                                                      AS TotalOutlets
    FROM ParetoFlagged
    GROUP BY OrderDate, OrderBookerID
)
SELECT
    ds.OrderDate,
    d.Code AS DistributionCode, d.LegalName AS Distribution,
    ob.Code AS OBCode, ob.Name AS OrderBooker,

    -- ============ PREVIOUS DAY (D-1) via self-join ============
    ISNULL(ds.OrderBookedValueTotal, 0)                            AS TodayOrderBookedPKR,
    ISNULL(ds.TotalSalesDelivered, 0)                              AS TotalSalesDelivered,
    ISNULL(ds.LostSalesDueToOperations, 0)                         AS LostSalesDueToOperationsPKR,
    Isnull(TotalAppSalesDelivered,0) TotalAppSalesDelivered,
  
    -- ============ FOR THE DAY (D) - App-specific ============
    ds.TotalAppSalesBooked                                             AS TotalSalesBookedForTheDayApp,
    ds.TotalWebSalesBooked                                             AS TotalSalesBookedForTheDayWeb,
    --ROUND(ds.TotalAppSalesBooked / NULLIF(ds.AppOutletsVisited, 0), 2) AS AvgOrderPerOutletVisitedApp,
    ds.BookedOrdersCountTotal ,ds.AppOutletsVisited,ds.WebOutletsVisited,
    ds.WebSalesDelivered                                                   AS WebSalesDelivered,

    ds.AppSalesPlanned                                                 AS TotalAppSalesFromPlannedShopsPKR,
    ds.AppSalesUnplanned                                               AS TotalAppSalesFromUnplannedShopsPKR,
    ROUND(ds.AppSalesPlanned * 100.0 / NULLIF(ds.TotalAppSalesBooked,0),2) AS PercentAppSalesFromPlannedShops,

    -- ============ FOR THE DAY (D) - 80/20 Pareto ============
    ps.TotalOutlets,
    ISNULL(ps.OutletsContributing80Pct, 0)                             AS OutletsContributing80PctValue,
    ROUND(ISNULL(ps.OutletsContributing80Pct,0) * 100.0 / NULLIF(ps.TotalOutlets,0), 2)
                                                                        AS PercentOutletsContributing80PctValue,

    ISNULL(ps.OutletsContributing20Pct, 0)                             AS OutletsContributing20PctValue,
    ROUND(ps.ValueFromTop80PctOutlets / NULLIF(ps.OutletsContributing80Pct,0), 2)
                                                                        AS AvgOrderPerOutlet_Top80PctGroup,
    ROUND(ps.ValueFromBottom20PctOutlets / NULLIF(ps.OutletsContributing20Pct,0), 2)
                                                                        AS AvgOrderPerOutlet_Bottom20PctGroup
   ,ps.ValueFromTop80PctOutlets,ps.ValueFromBottom20PctOutlets

FROM DailySales ds
INNER JOIN OrderBooker ob ON ob.OrderBookerID = ds.OrderBookerID
INNER JOIN Distribution d ON d.DistributionID = ob.DistributionID
LEFT JOIN ParetoSummary ps ON ps.OrderDate = ds.OrderDate AND ps.OrderBookerID = ds.OrderBookerID
--LEFT JOIN DailySales dsPrev
--       ON dsPrev.OrderBookerID = ds.OrderBookerID
--      AND dsPrev.OrderDate = DATEADD(DAY, -1, ds.OrderDate)
ORDER BY ds.OrderDate, d.Code, ob.Name;