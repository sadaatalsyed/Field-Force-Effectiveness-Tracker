/* ============================================================================================
   SHEET 3 - MARKET TIME & GPS (20%)
   ICE Daily Tracker

   Grain produced: one row per OrderBooker per VisitDate.

   Design notes:
   - Trade Time & First/Last Called At use AllVisits (Productive + NonProductive).
   - Shop Time / Median Shop Time use Productive visits only
     (NonProductive has no real start/end — see business-kpis.md).
   - All duration outputs are kept as raw INT seconds (not pre-formatted text/datetime).
     Formatting (HH:MM, HH:MM:SS, AM/PM) is handled entirely in DAX display measures —
     never in SQL — so Power BI can aggregate (MEDIANX/MAXX/SUM) correctly.
   ============================================================================================ */

WITH Attendance AS
(
    SELECT
        sl.CreatedBy,
        CAST(sl.CreatedOn AS DATE) AS VisitDate,
        MIN(CASE WHEN sl.SyncType = 'SyncDown' THEN sl.CreatedOn END) AS DayStart,
        MAX(CASE WHEN sl.SyncType = 'SyncUp'   THEN sl.CreatedOn END) AS DayEnd
    FROM SyncLogs sl
    WHERE CAST(sl.CreatedOn AS DATE) >= '2026-04-01' AND CAST(sl.CreatedOn AS DATE) <= CAST(GETDATE()-1 AS DATE)
      AND sl.SyncType IN ('SyncDown','SyncUp') AND sl.IsBuddy = 0
    GROUP BY sl.CreatedBy, CAST(sl.CreatedOn AS DATE)
),

ProductiveInvoiceLevel AS
(
    SELECT DISTINCT
        ss.InvoiceCode,
        CAST(ss.InvoiceDate AS DATE) AS VisitDate,
        ss.OrderBookerID,
        ss.CustomerID,
        ss.OrderStartTime,
        ss.OrderCompleteTime,
        ss.Lattitude,
        ss.Longitude
    FROM SA_SalesOrdersDump ss
    WHERE ss.Status <> 'Cancelled'
      AND ss.Synchronized = 1
      AND ss.InvoiceDate >= '2026-04-01' AND ss.InvoiceDate <= CAST(GETDATE()-1 AS DATE)
      AND ss.OrderCompleteTime > ss.OrderStartTime
),

ProductiveVisits AS
(
    SELECT
        VisitDate, OrderBookerID, CustomerID,
        OrderStartTime, OrderCompleteTime,
        Lattitude, Longitude,
        'Productive' AS VisitType
    FROM ProductiveInvoiceLevel
),

NonProductiveVisits AS
(
    SELECT
        CAST(npc.CreatedOn AS DATE) AS VisitDate,
        npc.OrderBookerID,
        npc.CustomerID,
        npc.CreatedOn AS OrderStartTime,
        npc.CreatedOn AS OrderCompleteTime,
        npc.Lattitude,
        npc.Longitude,
        'NonProductive' AS VisitType
    FROM NonProductiveCustomers npc
    WHERE npc.Synchronized = 1
      AND CAST(npc.CreatedOn AS DATE) >= '2026-04-01' AND CAST(npc.CreatedOn AS DATE) <= CAST(GETDATE()-1 AS DATE)
),

AllVisits AS
(
    SELECT * FROM ProductiveVisits
    UNION ALL
    SELECT * FROM NonProductiveVisits
),

VisitSequence AS
(
    SELECT
        av.VisitDate, av.VisitType,
        d.Code AS DistributionCode, ob.Code AS OBCode, ob.Name AS OrderBooker,
        av.CustomerID, av.OrderStartTime, av.OrderCompleteTime,
        TRY_CAST(av.Lattitude AS FLOAT) AS VisitLat, TRY_CAST(av.Longitude AS FLOAT) AS VisitLng,
        TRY_CAST(c.Lattitude AS FLOAT)  AS OutletLat, TRY_CAST(c.Longitude AS FLOAT) AS OutletLng
    FROM AllVisits av
    INNER JOIN Customer c     ON c.CustomerID = av.CustomerID
    INNER JOIN OrderBooker ob ON ob.OrderBookerID = av.OrderBookerID
    INNER JOIN Distribution d ON d.DistributionID = ob.DistributionID
),

VisitGaps AS
(
    SELECT *,
        LAG(OrderCompleteTime) OVER (PARTITION BY VisitDate, OBCode ORDER BY OrderStartTime) AS PrevVisitEnd,
        LAG(VisitLat) OVER (PARTITION BY VisitDate, OBCode ORDER BY OrderStartTime)           AS PrevLat,
        LAG(VisitLng) OVER (PARTITION BY VisitDate, OBCode ORDER BY OrderStartTime)           AS PrevLng
    FROM VisitSequence
),

VisitMetrics AS
(
    SELECT *,
        -- Idle Time: gap minus 5-min travel allowance, across ALL stops
        CASE
            WHEN DATEDIFF(SECOND, PrevVisitEnd, OrderStartTime) IS NULL THEN NULL
            WHEN DATEDIFF(SECOND, PrevVisitEnd, OrderStartTime) - 300 < 0 THEN 0
            ELSE DATEDIFF(SECOND, PrevVisitEnd, OrderStartTime) - 300
        END AS IdleGapSeconds,
        DATEDIFF(SECOND, PrevVisitEnd, OrderStartTime) AS RawGapSeconds,

        -- Travel distance from previous stop (Haversine, ACOS-clamped)
        CASE
            WHEN PrevLat IS NULL OR PrevLng IS NULL OR VisitLat IS NULL OR VisitLng IS NULL THEN NULL
            ELSE 6371000 * ACOS(
                CASE
                    WHEN (COS(RADIANS(PrevLat))*COS(RADIANS(VisitLat))*COS(RADIANS(VisitLng)-RADIANS(PrevLng)) + SIN(RADIANS(PrevLat))*SIN(RADIANS(VisitLat))) > 1 THEN 1
                    WHEN (COS(RADIANS(PrevLat))*COS(RADIANS(VisitLat))*COS(RADIANS(VisitLng)-RADIANS(PrevLng)) + SIN(RADIANS(PrevLat))*SIN(RADIANS(VisitLat))) < -1 THEN -1
                    ELSE (COS(RADIANS(PrevLat))*COS(RADIANS(VisitLat))*COS(RADIANS(VisitLng)-RADIANS(PrevLng)) + SIN(RADIANS(PrevLat))*SIN(RADIANS(VisitLat)))
                END
            )
        END AS TravelMetersFromPrevVisit,

        -- ShopTimeSeconds: 0 for NonProductive (Start=Complete), only meaningful for Productive
        DATEDIFF(SECOND, OrderStartTime, OrderCompleteTime) AS ShopTimeSeconds,

        -- GPS validity vs outlet's registered location (Haversine <= 100m)
        CASE
            WHEN OutletLat IS NULL OR OutletLng IS NULL OR VisitLat IS NULL OR VisitLng IS NULL THEN NULL
            WHEN 6371000 * ACOS(
                CASE
                    WHEN (COS(RADIANS(OutletLat))*COS(RADIANS(VisitLat))*COS(RADIANS(VisitLng)-RADIANS(OutletLng)) + SIN(RADIANS(OutletLat))*SIN(RADIANS(VisitLat))) > 1 THEN 1
                    WHEN (COS(RADIANS(OutletLat))*COS(RADIANS(VisitLat))*COS(RADIANS(VisitLng)-RADIANS(OutletLng)) + SIN(RADIANS(OutletLat))*SIN(RADIANS(VisitLat))) < -1 THEN -1
                    ELSE (COS(RADIANS(OutletLat))*COS(RADIANS(VisitLat))*COS(RADIANS(VisitLng)-RADIANS(OutletLng)) + SIN(RADIANS(OutletLat))*SIN(RADIANS(VisitLat)))
                END
            ) <= 100 THEN 1
            ELSE 0
        END AS HasValidGPS
    FROM VisitGaps
),

DailyMetrics AS
(
    SELECT
        vm.VisitDate, vm.DistributionCode, vm.OBCode, vm.OrderBooker,
        att.DayStart, att.DayEnd,

        COUNT(DISTINCT vm.CustomerID)                                                    AS UniqueStopsMade,
        COUNT(DISTINCT CASE WHEN vm.VisitType = 'Productive' THEN vm.CustomerID END)      AS ProductiveStopsMade,
        SUM(vm.TravelMetersFromPrevVisit)                                                 AS TotalTravelMeters,
        SUM(CASE WHEN vm.IdleGapSeconds > 0 THEN vm.IdleGapSeconds ELSE 0 END)            AS TotalIdleSeconds,
        MAX(CASE WHEN vm.IdleGapSeconds > 0 THEN vm.IdleGapSeconds END)                  AS LongestIdleSeconds,
        AVG(vm.RawGapSeconds)                                                             AS AvgRawGapSeconds,
        COUNT(CASE WHEN Isnull(vm.OutletLat,0)<>0  AND isnull(vm.OutletLng,0)<>0 THEN 1 END) AS ShopsWithGPS,
        COUNT(CASE WHEN Isnull(vm.OutletLat,0)=0  OR Isnull(vm.OutletLat,0)=0 THEN 1 END)          AS ShopsWithoutGPS,
        COUNT(*)                                                                          AS TotalStopRows,
        SUM(vm.HasValidGPS)                                                               AS ValidGPSCount,

        MIN(vm.OrderStartTime)                                                            AS FirstOrderStart,
        MAX(vm.OrderCompleteTime)                                                         AS LastOrderComplete,
        DATEDIFF(SECOND, MIN(vm.OrderStartTime), MAX(vm.OrderCompleteTime))              AS TradeTimeSeconds,

        SUM(CASE WHEN vm.VisitType = 'Productive' THEN vm.ShopTimeSeconds END)            AS TotalShopSeconds

    FROM VisitMetrics vm
    LEFT JOIN Attendance att ON att.CreatedBy = vm.OBCode AND att.VisitDate = vm.VisitDate
    GROUP BY vm.VisitDate, vm.DistributionCode, vm.OBCode, vm.OrderBooker, att.DayStart, att.DayEnd
),

MedianCalc AS
(
    SELECT DISTINCT
        vm.VisitDate, vm.OBCode,
        CAST(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY vm.ShopTimeSeconds)
             OVER (PARTITION BY vm.VisitDate, vm.OBCode) AS INT) AS MedianShopTimeSeconds
    FROM VisitMetrics vm
    WHERE vm.VisitType = 'Productive'
)

SELECT
    dm.VisitDate, dm.DistributionCode, dm.OBCode, dm.OrderBooker,

    -- Raw datetimes — kept as-is, no formatting, no wrapping
    dm.DayStart,
    dm.DayEnd,
    dm.FirstOrderStart   AS FirstShopCalledAt,
    dm.LastOrderComplete AS LastShopCalledAt,

    -- Raw INT seconds — all formatting handled in DAX display measures
    DATEDIFF(SECOND, dm.DayStart, dm.DayEnd)         AS FieldTimeSeconds,
    dm.TradeTimeSeconds                              AS TradeTimeSeconds,
    dm.TotalShopSeconds                              AS ShopTimeSeconds,
    mc.MedianShopTimeSeconds                         AS MedianShopTimeSeconds,
    dm.TotalIdleSeconds                              AS IdleSeconds,
    dm.LongestIdleSeconds                            AS LongestIdleSeconds,
    (dm.TradeTimeSeconds - dm.TotalIdleSeconds)      AS ActiveMarketTimeSeconds,

    dm.UniqueStopsMade      AS TotalStopsMade,
    dm.ProductiveStopsMade  AS ProductiveStopsMade,
    ROUND(dm.ProductiveStopsMade * 100.0 / NULLIF(dm.UniqueStopsMade, 0), 2) AS StrikeRatePercent,

    ROUND(dm.TotalTravelMeters / 1000.0, 2)          AS TotalDistanceCoveredKm,
    ROUND(dm.AvgRawGapSeconds / 60.0, 2)             AS AvgTimeBetweenVisitsMinutes,

    dm.ShopsWithGPS       AS ShopsWithGPS,
    dm.ShopsWithoutGPS    AS ShopsWithoutGPS,
    dm.TotalStopRows      AS TotalStopRows,
    dm.ValidGPSCount      AS ValidGPSCount

FROM DailyMetrics dm
LEFT JOIN MedianCalc mc ON mc.VisitDate = dm.VisitDate AND mc.OBCode = dm.OBCode
ORDER BY dm.VisitDate, dm.DistributionCode, dm.OBCode;
