-- SQL source as supplied; requires environment-specific review before execution.
/* ============================================================================================
   SHEET 3 - MARKET TIME & GPS (20%)
   v3: Trade Time & First/Last Called At now use AllVisits (Productive + NonProductive).
       Added Strike Rate (Productive Stops / Total Stops).
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
        CAST(ss.CreatedOn AS DATE) AS VisitDate,
        ss.OrderBookerID,
        ss.CustomerID,
        ss.OrderStartTime,
        ss.OrderCompleteTime,
        ss.Lattitude,
        ss.Longitude,
        -- NEW: flag rows where the timestamp doesn't belong to this VisitDate
        CASE
            WHEN CAST(ss.OrderStartTime AS DATE) <> CAST(ss.CreatedOn AS DATE) THEN 1
            ELSE 0
        END AS IsStaleTimestamp
    FROM SA_SalesOrdersDump ss
    WHERE ss.Status <> 'Cancelled'
      AND ss.Synchronized = 1
      AND Cast(ss.CreatedOn as Date) >= '2026-04-01' AND Cast(ss.CreatedOn as Date) <= CAST(GETDATE()-1 AS DATE)
     AND ss.OrderCompleteTime > ss.OrderStartTime
)


,
ProductiveVisits AS
(
    SELECT
        VisitDate, OrderBookerID, CustomerID,
        OrderStartTime, OrderCompleteTime,
        Lattitude, Longitude,IsStaleTimestamp,
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
        npc.Longitude,0 as IsStaleTimestamp,
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
        av.CustomerID, av.OrderStartTime, av.OrderCompleteTime, av.IsStaleTimestamp,   -- carry the flag through
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
    WHERE IsStaleTimestamp = 0   -- exclude BEFORE sequencing, not after
),

VisitMetrics AS
(
    SELECT *,
        -- Idle Time: gap minus 5-min travel allowance, across ALL stops (Productive + NonProductive)
        CASE
            WHEN DATEDIFF(SECOND, PrevVisitEnd, OrderStartTime) IS NULL THEN NULL
            WHEN DATEDIFF(SECOND, PrevVisitEnd, OrderStartTime) - 300 < 0 THEN 0
            ELSE DATEDIFF(SECOND, PrevVisitEnd, OrderStartTime) - 300
        END AS IdleGapSeconds,
        DATEDIFF(SECOND, PrevVisitEnd, OrderStartTime) AS RawGapSeconds,

        -- Travel distance from previous stop (any type)
        CASE
            WHEN Isnull(PrevLat,0)=0 OR Isnull(PrevLng,0)=0  OR isnull(VisitLat,0)=0  OR isnull(VisitLng,0)=0  THEN NULL
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

        -- GPS validity vs outlet's registered location (any type)
        CASE
            WHEN isnull(OutletLat,0)=0  OR isnull(OutletLng,0)=0 OR isnull(VisitLat,0)=0 OR isnull(VisitLng,0)=0 THEN NULL
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

--Select * from VisitMetrics

DailyMetrics AS
(
    SELECT
        vm.VisitDate, vm.DistributionCode, vm.OBCode, vm.OrderBooker,
        att.DayStart, att.DayEnd,

        -- ===== AllVisits-based: Stops, Distance, Idle, GPS =====
        COUNT(DISTINCT vm.CustomerID)                                                    AS UniqueStopsMade,
        COUNT(DISTINCT CASE WHEN vm.VisitType = 'Productive' THEN vm.CustomerID END)      AS ProductiveStopsMade,
        --SUM(vm.TravelMetersFromPrevVisit)                                                 AS TotalTravelMeters,
        --SUM(CASE WHEN vm.IdleGapSeconds > 0 THEN vm.IdleGapSeconds ELSE 0 END)            AS TotalIdleSeconds,
        --MAX(CASE WHEN vm.IdleGapSeconds > 0 THEN vm.IdleGapSeconds END)                  AS LongestIdleSeconds,
        --AVG(vm.IdleGapSeconds)                                                            AS AvgIdleGapSeconds,

        -- Time-based metrics: EXCLUDE stale-timestamp rows
        MIN(CASE WHEN vm.IsStaleTimestamp = 0 THEN vm.OrderStartTime END)   AS FirstOrderStart,
        MAX(CASE WHEN vm.IsStaleTimestamp = 0 THEN vm.OrderCompleteTime END) AS LastOrderComplete,
        MAX(CASE WHEN vm.IsStaleTimestamp = 0 THEN vm.OrderStartTime END) AS LastOrderStart,
        DATEDIFF(SECOND,
            MIN(CASE WHEN vm.IsStaleTimestamp = 0 THEN vm.OrderStartTime END),
            MAX(CASE WHEN vm.IsStaleTimestamp = 0 THEN vm.OrderCompleteTime END)
        ) AS TradeTimeSeconds,

        -- Idle/Distance sums: only count gaps computed between two non-stale consecutive visits
        SUM(CASE WHEN vm.IsStaleTimestamp = 0 AND vm.IdleGapSeconds > 0 THEN vm.IdleGapSeconds ELSE 0 END) AS TotalIdleSeconds,
        MAX(CASE WHEN vm.IsStaleTimestamp = 0 AND vm.IdleGapSeconds > 0 THEN vm.IdleGapSeconds END) AS LongestIdleSeconds,
        SUM(CASE WHEN vm.IsStaleTimestamp = 0 THEN vm.TravelMetersFromPrevVisit END) AS TotalTravelMeters,

        AVG(vm.RawGapSeconds)   AS AvgRawGapSeconds ,     -- true "Avg Time Between Visits"
        COUNT(Distinct CASE WHEN Isnull(vm.OutletLat,0)<>0  AND isnull(vm.OutletLng,0)<>0 THEN vm.CustomerID END) AS ShopsWithGPS,
        COUNT(Distinct CASE WHEN Isnull(vm.OutletLat,0)=0  OR Isnull(vm.OutletLng,0)=0 THEN vm.CustomerID END)          AS ShopsWithoutGPS,
        COUNT(*)                                                                          AS TotalStopRows,
        --SUM(vm.HasValidGPS)                                                               AS ValidGPSCount,
        Count(Distinct Case when Isnull(vm.HasValidGPS,0)=1 then vm.CustomerID end)                                     AS ValidGPSCount,
        AVG(CASE WHEN vm.HasValidGPS IS NOT NULL THEN
                6371000 * ACOS(
                    CASE
                        WHEN (COS(RADIANS(vm.OutletLat))*COS(RADIANS(vm.VisitLat))*COS(RADIANS(vm.VisitLng)-RADIANS(vm.OutletLng)) + SIN(RADIANS(vm.OutletLat))*SIN(RADIANS(vm.VisitLat))) > 1 THEN 1
                        WHEN (COS(RADIANS(vm.OutletLat))*COS(RADIANS(vm.VisitLat))*COS(RADIANS(vm.VisitLng)-RADIANS(vm.OutletLng)) + SIN(RADIANS(vm.OutletLat))*SIN(RADIANS(vm.VisitLat))) < -1 THEN -1
                        ELSE (COS(RADIANS(vm.OutletLat))*COS(RADIANS(vm.VisitLat))*COS(RADIANS(vm.VisitLng)-RADIANS(vm.OutletLng)) + SIN(RADIANS(vm.OutletLat))*SIN(RADIANS(vm.VisitLat)))
                    END
                )
            END)                                                                          AS AvgDistanceFromOutletMeters,

        -- ===== NOW AllVisits-based: Trade Time & First/Last Called At =====
        --MIN(vm.OrderStartTime)                                                            AS FirstOrderStart,
        --MAX(vm.OrderCompleteTime)                                                         AS LastOrderComplete,
        --DATEDIFF(SECOND, MIN(vm.OrderStartTime), MAX(vm.OrderCompleteTime))              AS TradeTimeSeconds,

        -- ===== Still Productive-only: Shop Time metrics =====
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

    --CONVERT(VARCHAR(5), DATEADD(MINUTE, DATEDIFF(MINUTE, dm.DayStart, dm.DayEnd), 0), 108) AS TotalTimeSpentInField_HHMM,
    --CASE 
    --WHEN dm.DayStart IS NULL OR dm.DayEnd IS NULL THEN NULL
    --ELSE CONCAT(
    --    CASE WHEN DATEDIFF(MINUTE, dm.DayStart, dm.DayEnd) < 0 THEN '-' ELSE '' END,
    --    ABS(DATEDIFF(MINUTE, dm.DayStart, dm.DayEnd)) / 60,
    --    ':',
    --    RIGHT('0' + CAST(ABS(DATEDIFF(MINUTE, dm.DayStart, dm.DayEnd)) % 60 AS VARCHAR(2)), 2)
    --)
    -- END AS TotalTimeSpentInField_HHMM,
    dm.UniqueStopsMade      AS TotalStopsMade,
    dm.ProductiveStopsMade  AS ProductiveStopsMade,
    ROUND(dm.ProductiveStopsMade * 100.0 / NULLIF(dm.UniqueStopsMade, 0), 2) AS StrikeRatePercent,

    -- Now AllVisits-based
    --CONVERT(VARCHAR(5), DATEADD(SECOND, dm.TradeTimeSeconds, 0), 108) AS TotalTimeSpentInTrade_HHMM,
    --DATEADD(SECOND, dm.TradeTimeSeconds, 0) AS TotalTimeSpentInTrade_HHMM,
    --CONVERT(VARCHAR(8), dm.FirstOrderStart, 108)   AS FirstShopCalledAt,
    --CONVERT(VARCHAR(8), dm.LastOrderComplete, 108) AS LastShopCalledAt,
    dm.FirstOrderStart  AS FirstShopCalledAt,
    dm.LastOrderComplete AS LastShopCompletedAt,
    dm.LastOrderStart As LastShopCalledAt,
   

    DATEDIFF(SECOND, dm.DayStart, dm.DayEnd)                          AS TotalTimeSpentInField_HHMM, -- FieldTimeSeconds,
       dm.TradeTimeSeconds                                                AS TotalTimeSpentInTrade_HHMM,-- TradeTimeSeconds,
        dm.TotalShopSeconds                                                AS TotalTimeSpentInShops_HHMM,-- ShopTimeSeconds,
        dm.TotalIdleSeconds                                                AS TotalIdlePeriod_HHMM,--IdleSeconds,
        dm.LongestIdleSeconds                                              AS LongestIdlePeriod_HHMMSS,-- LongestIdleSeconds,
        dm.TradeTimeSeconds - dm.TotalIdleSeconds                          AS ActiveMarketTime_HHMM,--ActiveMarketTimeSeconds,
        mc.MedianShopTimeSeconds                                           AS MedianTimePerShop_HHMMSS,-- MedianShopTimeSeconds,
   

    ROUND(dm.TotalTravelMeters / 1000.0, 2) AS TotalDistanceCoveredKm,
    ROUND(dm.AvgRawGapSeconds / 60.0, 2)  AS AvgTimeBetweenVisitsMinutes  ,

    dm.ShopsWithGPS      AS ShopsVisitedWithGPS,
    dm.ShopsWithoutGPS   AS ShopsVisitedWithoutGPS,
     TotalStopRows,Isnull(ValidGPSCount,0) ValidGPSCount,
    ROUND(dm.ShopsWithoutGPS * 100.0 / NULLIF(dm.UniqueStopsMade, 0), 2) AS PercentShopsWithoutGPS,
    ROUND(dm.ValidGPSCount * 100.0 / NULLIF(dm.ShopsWithGPS, 0), 2)   AS GPSCompliancePercent,
    ROUND(dm.AvgDistanceFromOutletMeters, 2)                          AS AvgDistanceFromOutletMeters
    ,dm.DayStart,dm.DayEnd

FROM DailyMetrics dm
LEFT JOIN MedianCalc mc ON mc.VisitDate = dm.VisitDate AND mc.OBCode = dm.OBCode
ORDER BY dm.VisitDate, dm.DistributionCode, dm.OBCode;