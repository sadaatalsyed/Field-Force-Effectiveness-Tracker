-- SQL source as supplied; requires environment-specific review before execution.
/* 
=========================================================================
   SHEET 2 - ROUTE EXECUTION & PRODUCTIVITY (30%)
=========================================================================
 */

WITH PJP AS
(
    SELECT
        CAST(scr.VisitDate AS DATE) AS VisitDate,
        scr.OrderBookerID,
        COUNT(DISTINCT scr.CustomerID) AS PJPShops
    FROM SA_CustomerRoute scr
    INNER JOIN OrderBooker ob   ON ob.OrderBookerID = scr.OrderBookerID
    INNER JOIN AspNetUsers anu  ON anu.Id = ob.UserID
    INNER JOIN Designation desi ON desi.DesignationID = anu.DesignationID
    INNER JOIN Customer c       ON c.CustomerID = scr.CustomerID     -- active customers only
    WHERE 1=1
    and desi.DesignationID = 1
      AND scr.isRoute = 1
      --AND c.Active = 1
         AND scr.VisitDate >= '2026-04-01'
      AND scr.VisitDate <=  Cast(GetDate()-1 as Date)
    GROUP BY CAST(scr.VisitDate AS DATE), scr.OrderBookerID
),

-- Step 1: Collapse product-level rows to invoice level (NetAmount is product-level,
-- one invoice has multiple ProductIDs -> must SUM, never MIN, per established rule)
InvoiceLevel AS
(
    SELECT
        ss.InvoiceCode,
        CAST(ss.InvoiceDate AS DATE) AS VisitDate,
        ss.CustomerID,
        ss.OrderBookerID,
        ss.isPlanned,
        ss.Synchronized as isApp,
        ss.Lattitude,
        ss.Longitude,
        ss.OrderStartTime,
        ss.OrderCompleteTime,
        SUM(ss.NetAmount) AS InvoiceNetAmount
    FROM SA_SalesOrdersDump ss
    WHERE ss.Status<>'Cancelled'
      AND ss.InvoiceDate >= '2026-04-01'
      AND ss.InvoiceDate <=  Cast(GetDate()-1 as Date)
      and ss.NetAmount>0.9
    GROUP BY
        ss.InvoiceCode, CAST(ss.InvoiceDate AS DATE), ss.CustomerID, ss.OrderBookerID,
        ss.isPlanned, ss.Synchronized, ss.Lattitude, ss.Longitude,
        ss.OrderStartTime, ss.OrderCompleteTime
),

-- Step 2: Derive Planned/Unplanned + App/Web flags at invoice level
ProductiveCalls AS
(
    SELECT
        il.VisitDate,
        il.OrderBookerID,
        il.CustomerID,
        isPlanned,
        isApp,
        il.InvoiceNetAmount,
        il.Lattitude,
        il.Longitude
    FROM InvoiceLevel il
),

-- Non-productive calls, same Planned/Unplanned flag (unchanged source table)
NonProductiveCalls AS
(
    SELECT
        CAST(npc.CreatedOn AS DATE) AS VisitDate,
        npc.OrderBookerID,
        npc.CustomerID,
        CASE WHEN npc.CustomersRouteID IS NOT NULL THEN 1 ELSE 0 END AS IsPlanned
    FROM NonProductiveCustomers npc
    WHERE npc.CreatedOn >= '2026-04-01'
      AND npc.CreatedOn <=  Cast(Getdate()-1 as Date)
),

SaleInvoiceSummary AS
(
    SELECT
        VisitDate,
        OrderBookerID,
        COUNT(DISTINCT CustomerID)                                                       AS ProductiveVisited,
        COUNT(DISTINCT CASE WHEN IsPlanned = 1 AND IsApp = 1 THEN CustomerID END)         AS PlannedProductiveShopsApp,
        COUNT(DISTINCT CASE WHEN IsPlanned = 1 THEN CustomerID END)         AS PlannedProductiveShopsOverall,
        COUNT(DISTINCT CASE WHEN IsPlanned = 0 AND IsApp = 1 THEN CustomerID END)         AS UnplannedProductiveShopsApp,
        COUNT(DISTINCT CASE WHEN IsPlanned = 1 AND IsApp = 0 THEN CustomerID END)         AS PlannedProductiveShopsWeb,
        COUNT(DISTINCT CASE WHEN IsPlanned = 0 AND IsApp = 0 THEN CustomerID END)         AS UnplannedProductiveShopsWeb,
        COUNT(DISTINCT CASE WHEN IsPlanned = 0 THEN CustomerID END)         AS UnplannedProductiveShopsOverall,
        SUM(CASE WHEN IsPlanned = 1 AND IsApp = 1 THEN InvoiceNetAmount ELSE 0 END)        AS PlannedOrderValueApp,
        SUM(CASE WHEN IsPlanned = 0 AND IsApp = 1 THEN InvoiceNetAmount ELSE 0 END)        AS UnplannedOrderValueApp,
        SUM(CASE WHEN IsPlanned = 1 AND IsApp = 0 THEN InvoiceNetAmount ELSE 0 END)        AS PlannedOrderValueWeb,
        SUM(CASE WHEN IsPlanned = 0 AND IsApp = 0 THEN InvoiceNetAmount ELSE 0 END)        AS UnplannedOrderValueWeb,
        COUNT(DISTINCT CASE WHEN InvoiceNetAmount <=500 THEN CustomerID END)              AS ProductiveOutletsUnder500,
        COUNT(DISTINCT CASE WHEN InvoiceNetAmount > 500 THEN CustomerID END)              AS ProductiveOutletsOver500,
        SUM(InvoiceNetAmount)                                                             AS TotalProductiveOrderValue
    FROM ProductiveCalls
    GROUP BY VisitDate, OrderBookerID
)
,
--Select * from SaleInvoiceSummary
-- All calls (productive + non-productive) = TRUE total visits, planned vs unplanned
AllVisits AS
(
    SELECT Distinct VisitDate, OrderBookerID, CustomerID, IsPlanned FROM ProductiveCalls
    UNION
    SELECT Distinct VisitDate, OrderBookerID, CustomerID, IsPlanned FROM NonProductiveCalls
),
VisitedShops AS
(
    SELECT
        VisitDate,
        OrderBookerID,
        COUNT(DISTINCT CustomerID)                                             AS ShopsVisited,
        COUNT(DISTINCT CASE WHEN IsPlanned = 1 THEN CustomerID END)            AS TotalVisitsPlanned,
        COUNT(DISTINCT CASE WHEN IsPlanned = 0 THEN CustomerID END)            AS TotalVisitsUnplanned
    FROM AllVisits
    GROUP BY VisitDate, OrderBookerID
),

Base AS
(
    SELECT VisitDate, OrderBookerID FROM PJP
    UNION
    SELECT VisitDate, OrderBookerID FROM SaleInvoiceSummary
    UNION
    SELECT VisitDate, OrderBookerID FROM VisitedShops
),

-- Attendance / trade-time, needed for Productive Calls per Hour
-- ASSUMPTION: still sourced from SyncLogs (day-level login/logout),
-- since OrderStartTime/OrderCompletionTime are treated as per-invoice timestamps.
Attendance AS
(
    SELECT
        sl.CreatedBy,
        CAST(sl.CreatedOn AS DATE) AS VisitDate,
        MIN(CASE WHEN sl.SyncType = 'SyncDown' THEN sl.CreatedOn END) AS DayStart,
        MAX(CASE WHEN sl.SyncType = 'SyncUp'   THEN sl.CreatedOn END) AS DayEnd
    FROM SyncLogs sl
    WHERE Cast(sl.CreatedOn as Date) >= '2026-04-01' AND Cast(sl.CreatedOn as Date) <= Cast(GetDate()-1 as Date)
      AND sl.SyncType IN ('SyncDown','SyncUp') AND sl.IsBuddy = 0
      
    GROUP BY sl.CreatedBy, CAST(sl.CreatedOn AS DATE)

),

-- GPS validity per productive visit (order/visit lat-long now comes from SA_SalesDataDump)
GpsCheck AS
(
    SELECT
        pc.VisitDate,
        pc.OrderBookerID,
        pc.CustomerID,
        --Distance.DistanceMeters,
        --pc.Lattitude,pc.Longitude,c.Lattitude Clat,c.Longitude CLong,
        CASE WHEN Distance.DistanceMeters <= 100 THEN 1 ELSE 0 END AS IsUnder100m
    FROM ProductiveCalls pc
    Left JOIN Customer c ON c.CustomerID = pc.CustomerID
    CROSS APPLY
(
    SELECT CASE
        WHEN TRY_CAST(c.Lattitude AS FLOAT) IS NULL OR TRY_CAST(c.Longitude AS FLOAT) IS NULL
             OR TRY_CAST(pc.Lattitude AS FLOAT) IS NULL OR TRY_CAST(pc.Longitude AS FLOAT) IS NULL
        THEN NULL
        ELSE 6371000 * ACOS(
                -- clamp between -1 and 1 to avoid floating point rounding errors
                CASE 
                    WHEN (COS(RADIANS(TRY_CAST(c.Lattitude AS FLOAT))) * COS(RADIANS(TRY_CAST(pc.Lattitude AS FLOAT))) *
                          COS(RADIANS(TRY_CAST(pc.Longitude AS FLOAT)) - RADIANS(TRY_CAST(c.Longitude AS FLOAT))) +
                          SIN(RADIANS(TRY_CAST(c.Lattitude AS FLOAT))) * SIN(RADIANS(TRY_CAST(pc.Lattitude AS FLOAT)))) > 1 THEN 1
                    WHEN (COS(RADIANS(TRY_CAST(c.Lattitude AS FLOAT))) * COS(RADIANS(TRY_CAST(pc.Lattitude AS FLOAT))) *
                          COS(RADIANS(TRY_CAST(pc.Longitude AS FLOAT)) - RADIANS(TRY_CAST(c.Longitude AS FLOAT))) +
                          SIN(RADIANS(TRY_CAST(c.Lattitude AS FLOAT))) * SIN(RADIANS(TRY_CAST(pc.Lattitude AS FLOAT)))) < -1 THEN -1
                    ELSE (COS(RADIANS(TRY_CAST(c.Lattitude AS FLOAT))) * COS(RADIANS(TRY_CAST(pc.Lattitude AS FLOAT))) *
                          COS(RADIANS(TRY_CAST(pc.Longitude AS FLOAT)) - RADIANS(TRY_CAST(c.Longitude AS FLOAT))) +
                          SIN(RADIANS(TRY_CAST(c.Lattitude AS FLOAT))) * SIN(RADIANS(TRY_CAST(pc.Lattitude AS FLOAT))))
                END
            )
    END AS DistanceMeters
) Distance
),
GpsSummary AS
(
    SELECT VisitDate, OrderBookerID,
           COUNT(DISTINCT CustomerID)                                             AS ProductiveOutletsOverall,
           COUNT(DISTINCT CASE WHEN IsUnder100m = 1 THEN CustomerID END)          AS ProductiveOutletsUnder100m
    FROM GpsCheck
    GROUP BY VisitDate, OrderBookerID
)

SELECT
    b.VisitDate,
    l1.Name AS Region,
    l2.Name AS Area,
    l3.Name AS Territory,
    d.Code  AS DistributionCode,
    d.LegalName AS Distribution,
    ob.Code AS OBCode,
    ob.Name AS OrderBooker,

    ISNULL(pjp.PJPShops, 0)                                 AS PlannedShopsInPJP,
    --ISNULL(sis.PlannedProductiveShopsApp,0) + ISNULL(sis.PlannedProductiveShopsWeb,0)      AS ActualPlannedProductiveShopsVisited,
    Isnull(sis.PlannedProductiveShopsOverall,0) as ActualPlannedProductiveShopsVisited,
    --ISNULL(sis.UnplannedProductiveShopsApp,0) + ISNULL(sis.UnplannedProductiveShopsWeb,0)
    --                                                         AS UnplannedProductiveShopsVisited,
     Isnull(UnplannedProductiveShopsOverall,0) as UnplannedProductiveShopsVisited,
    ISNULL(vs.TotalVisitsPlanned, 0)                        AS TotalVisitsPlanned_InclNonProductive,
    ISNULL(vs.TotalVisitsUnplanned, 0)                      AS TotalVisitsUnplanned_InclNonProductive,
    ISNULL(vs.ShopsVisited, 0)                              AS TotalVisits_InclNonProductive,
    ISNULL(sis.PlannedProductiveShopsApp,0) PlannedProductiveShopsApp,ISNULL(sis.PlannedProductiveShopsWeb,0)PlannedProductiveShopsWeb,
    ISNULL(sis.UnplannedProductiveShopsApp,0) UnplannedProductiveShopsApp,ISNULL(sis.UnplannedProductiveShopsWeb,0)UnplannedProductiveShopsWeb,

    ---- PJP Compliance % = planned shops actually visited / planned shops in PJP
    --ROUND( (ISNULL(sis.PlannedProductiveShopsApp,0) + ISNULL(sis.PlannedProductiveShopsWeb,0)) * 100.0
    --        / NULLIF(pjp.PJPShops, 0), 2)                   AS PJPCompliancePercent,

       -- PJP Compliance % = planned shops actually visited (producitve+non_productive) / planned shops in PJP
    ROUND( (TotalVisitsPlanned) * 100.0
            / NULLIF(pjp.PJPShops, 0), 2)                   AS PJPCompliancePercent,
    -- Missed outlets = planned in PJP but never converted to a productive visit
    --(ISNULL(pjp.PJPShops,0) - (ISNULL(sis.PlannedProductiveShopsApp,0) + ISNULL(sis.PlannedProductiveShopsWeb,0)))
    --                                                         AS MissedOutlets,
 (ISNULL(pjp.PJPShops,0) - isnull(sis.PlannedProductiveShopsOverall,0))
                                                             AS MissedOutlets,
    -- Missed Possible Order Value = Missed Outlets x SAME-DAY avg order value per productive outlet
    Isnull(sis.ProductiveVisited,0) ProductiveVisited,
    ISNULL(sis.TotalProductiveOrderValue,0) TotalProductiveOrderValue,
    --ROUND(
    --    (ISNULL(pjp.PJPShops,0) - (ISNULL(sis.PlannedProductiveShopsApp,0) + ISNULL(sis.PlannedProductiveShopsWeb,0)))
    --    * (ISNULL(sis.TotalProductiveOrderValue,0) * 1.0 / NULLIF(sis.ProductiveVisited,0))
    --, 2)                                                     AS MissedPossibleOrderValuePKR,
    ROUND(
        (ISNULL(pjp.PJPShops,0) - ISNULL(sis.PlannedProductiveShopsOverall,0))
        * (ISNULL(sis.TotalProductiveOrderValue,0) * 1.0 / NULLIF(sis.ProductiveVisited,0))
    , 2)                                                     AS MissedPossibleOrderValuePKR,
    -- Strike Rate Overall = productive outlets / total outlets called on (productive+non-productive)
   
    --ROUND(ISNULL(gs.ProductiveOutletsOverall,0) * 100.0 / NULLIF(vs.ShopsVisited,0), 2)       AS StrikeRateOverallPercent2,
    ROUND(ISNULL(gs.ProductiveOutletsUnder100m,0) * 100.0 / NULLIF(vs.ShopsVisited,0), 2)     AS StrikeRateUnder100mPercent,
     

    ROUND(ISNULL(sis.ProductiveVisited,0) * 100.0 / NULLIF(vs.ShopsVisited,0), 2)       AS StrikeRateOverallPercent,


    --ISNULL(gs.ProductiveOutletsOverall, 0)                  AS ProductiveOutletsOverall,
    
    ISNULL(sis.ProductiveVisited, 0)                  AS ProductiveOutletsOverall,
    ISNULL(gs.ProductiveOutletsUnder100m, 0)                AS ProductiveOutletsUnder100m,

    ISNULL(sis.ProductiveOutletsUnder500, 0)                AS ProductiveOutletsUnder500Bill,
    ROUND(ISNULL(sis.ProductiveOutletsUnder500,0) * 100.0 / NULLIF(sis.ProductiveVisited,0), 2)
                                                             AS ProductiveOutletsUnder500BillPercent,
    ISNULL(sis.ProductiveOutletsOver500, 0)                 AS ProductiveOutletsOver500Bill,
    ROUND(ISNULL(sis.ProductiveOutletsOver500,0) * 100.0 / NULLIF(sis.ProductiveVisited,0), 2)
                                                             AS ProductiveOutletsOver500BillPercent,

    -- Route Completion % (suggested)
    --ROUND(ISNULL(vs.ShopsVisited,0) * 100.0 / NULLIF(pjp.PJPShops,0), 2)                       AS RouteCompletionPercent,
    --ROUND(ISNULL(vs.TotalVisitsPlanned,0) * 100.0 / NULLIF(pjp.PJPShops,0), 2)                       AS RouteCompletionPercent,

    -- Productive Calls per Hour (suggested) - still based on SyncLogs Attendance
    ROUND(ISNULL(gs.ProductiveOutletsOverall,0) * 1.0
          / NULLIF(DATEDIFF(MINUTE, att.DayStart, att.DayEnd) / 60.0, 0), 2)                   AS ProductiveCallsPerHour,
         att.DayStart,att.DayEnd,

    ISNULL(sis.PlannedOrderValueApp,0)   AS PlannedOrderValueApp,
    ISNULL(sis.UnplannedOrderValueApp,0) AS UnplannedOrderValueApp,
    ISNULL(sis.PlannedOrderValueWeb,0)   AS PlannedOrderValueWeb,
    ISNULL(sis.UnplannedOrderValueWeb,0) AS UnplannedOrderValueWeb

FROM Base b
INNER JOIN OrderBooker ob   ON ob.OrderBookerID = b.OrderBookerID
INNER JOIN Distribution d   ON d.DistributionID = ob.DistributionID
INNER JOIN Level1 l1        ON d.Level1ID = l1.Level1ID
INNER JOIN Level2 l2        ON d.Level2ID = l2.Level2ID
INNER JOIN Level3 l3        ON d.Level3ID = l3.Level3ID
LEFT JOIN PJP pjp                  ON pjp.VisitDate = b.VisitDate AND pjp.OrderBookerID = b.OrderBookerID
LEFT JOIN SaleInvoiceSummary sis   ON sis.VisitDate = b.VisitDate AND sis.OrderBookerID = b.OrderBookerID
LEFT JOIN VisitedShops vs          ON vs.VisitDate = b.VisitDate AND vs.OrderBookerID = b.OrderBookerID
LEFT JOIN GpsSummary gs            ON gs.VisitDate = b.VisitDate AND gs.OrderBookerID = b.OrderBookerID
LEFT JOIN Attendance att           ON att.CreatedBy = ob.Code AND att.VisitDate = b.VisitDate and att.DayStart<att.DayEnd
ORDER BY b.VisitDate, d.Code, ob.Code;