-- SQL source as supplied; requires environment-specific review before execution.


    SELECT 
        l1.Attribute1 AS Zone,
        l1.name AS Region,
        l2.name AS Area,
        l3.name AS Territory,
        l4.name AS Town,
        L.LocalityNames AS 'Sub-Area',
        SL.SubLocalityNames AS 'Sub-Territory',
        ob.Id AS OrderBookerUserID,
        o.code AS OBCode,
        ob.UserName,
        ob.Name AS OrderBooker,
        d.DistributionID,
        d.Code AS DistributionCode,
        d.Active,
        d.LegalName AS DistributionName,
        dc.ClassName AS DistributionClass,
        TM.Name AS TSO,
        TM.UserName AS TMUsername,
        ASM.Name AS ASM,
        ASM.UserName AS ASMUsername,
        RSM.Name AS RSM,
        RSM.UserName AS RSMUsername,
        GSM.Name AS GSM,
        GSM.UserName AS GSMUsername

    FROM Distribution AS d
    LEFT JOIN orderbooker AS o ON o.DistributionID = d.DistributionID
    JOIN DistributionClass dc ON d.DistributionClassID = dc.DistributionClassID
    LEFT JOIN AspNetUsers AS ob ON ob.id = o.UserID
    LEFT JOIN level1 AS l1 ON l1.level1ID = d.level1ID
    LEFT JOIN level2 AS l2 ON l2.level2ID = d.level2ID
    LEFT JOIN level3 AS l3 ON l3.level3ID = d.level3ID
    LEFT JOIN level4 AS l4 ON l4.level4ID = d.level4ID

    ----------------------------------------------------------
    -- Locality (comma-separated)
    ----------------------------------------------------------
    OUTER APPLY
    (
        SELECT STUFF((
            SELECT ', ' + l.LocalityName
            FROM AspNetUserLocality anul
            JOIN Locality l ON l.LocalityID = anul.LocalityID
            WHERE anul.UserID = ob.Id
            ORDER BY l.LocalityName
            FOR XML PATH(''), TYPE
        ).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS LocalityNames
    ) L

    ----------------------------------------------------------
    -- SubLocality (comma-separated)
    ----------------------------------------------------------
    OUTER APPLY
    (
        SELECT STUFF((
            SELECT ', ' + sl.SubLocalityName
            FROM AspNetUserSubLocality anusl
            JOIN SubLocality sl ON sl.SubLocalityID = anusl.SubLocalityID
            WHERE anusl.UserID = ob.Id
            ORDER BY sl.SubLocalityName
            FOR XML PATH(''), TYPE
        ).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS SubLocalityNames
    ) SL

    ----------------------------------------------------------
    -- TM
    ----------------------------------------------------------
    OUTER APPLY
    (
        SELECT TOP (1)
            tm.Id,
            tm.Name,
            tm.UserName
        FROM AspNetUsers tm
        INNER JOIN AspNetUserDistributions aud
            ON aud.UserID = tm.Id
           AND aud.DistributionID = ob.DistributionID
        WHERE
            tm.DesignationID = 24
            AND tm.Active = 1
            AND EXISTS
            (
                SELECT 1
                FROM AspNetUserLocality obl
                INNER JOIN AspNetUserLocality tml
                    ON tml.LocalityID = obl.LocalityID
                WHERE
                    obl.UserID = ob.Id
                    AND tml.UserID = tm.Id
            )
            AND EXISTS
            (
                SELECT 1
                FROM AspNetUserSubLocality obs
                INNER JOIN AspNetUserSubLocality tms
                    ON tms.SubLocalityID = obs.SubLocalityID
                WHERE
                    obs.UserID = ob.Id
                    AND tms.UserID = tm.Id
            )
        ORDER BY tm.Name
    ) TM

    ----------------------------------------------------------
    -- ASM
    ----------------------------------------------------------
    OUTER APPLY
    (
        SELECT TOP (1)
            asm.Id,
            asm.Name,
            asm.UserName
        FROM AspNetUsers asm
        INNER JOIN AspNetUserDistributions aud
            ON aud.UserID = asm.Id
           AND aud.DistributionID = ob.DistributionID
        WHERE
            asm.DesignationID = 9
            AND asm.Active = 1
            AND EXISTS
            (
                SELECT 1
                FROM AspNetUserLocality obl
                INNER JOIN AspNetUserLocality asml
                    ON asml.LocalityID = obl.LocalityID
                WHERE
                    obl.UserID = ob.Id
                    AND asml.UserID = asm.Id
            )
            AND EXISTS
            (
                SELECT 1
                FROM AspNetUserSubLocality obs
                INNER JOIN AspNetUserSubLocality asms
                    ON asms.SubLocalityID = obs.SubLocalityID
                WHERE
                    obs.UserID = ob.Id
                    AND asms.UserID = asm.Id
            )
        ORDER BY asm.Name
    ) ASM

    ----------------------------------------------------------
    -- RSM
    ----------------------------------------------------------
    OUTER APPLY
    (
        SELECT TOP (1)
            rsm.Id,
            rsm.Name,
            rsm.Username
        FROM AspNetUsers rsm
        INNER JOIN AspNetUserDistributions aud
            ON aud.UserID = rsm.Id
           AND aud.DistributionID = ob.DistributionID
        WHERE
            rsm.DesignationID = 18
            AND rsm.Active = 1
            AND EXISTS
            (
                SELECT 1
                FROM AspNetUserLocality obl
                INNER JOIN AspNetUserLocality rsml
                    ON rsml.LocalityID = obl.LocalityID
                WHERE
                    obl.UserID = ob.Id
                    AND rsml.UserID = rsm.Id
            )
            AND EXISTS
            (
                SELECT 1
                FROM AspNetUserSubLocality obs
                INNER JOIN AspNetUserSubLocality rsms
                    ON rsms.SubLocalityID = obs.SubLocalityID
                WHERE
                    obs.UserID = ob.Id
                    AND rsms.UserID = rsm.Id
            )
        ORDER BY rsm.Name
    ) RSM

    ----------------------------------------------------------
    -- GSM
    ----------------------------------------------------------
    OUTER APPLY
    (
        SELECT TOP (1)
            gsm.Id,
            gsm.Name,
            gsm.Username
        FROM AspNetUsers gsm
        INNER JOIN AspNetUserDistributions aud
            ON aud.UserID = gsm.Id
           AND aud.DistributionID = ob.DistributionID
        WHERE
            gsm.DesignationID = 23
            AND gsm.Active = 1
            AND EXISTS
            (
                SELECT 1
                FROM AspNetUserLocality obl
                INNER JOIN AspNetUserLocality gsml
                    ON gsml.LocalityID = obl.LocalityID
                WHERE
                    obl.UserID = ob.Id
                    AND gsml.UserID = gsm.Id
            )
            AND EXISTS
            (
                SELECT 1
                FROM AspNetUserSubLocality obs
                INNER JOIN AspNetUserSubLocality gsms
                    ON gsms.SubLocalityID = obs.SubLocalityID
                WHERE
                    obs.UserID = ob.Id
                    AND gsms.UserID = gsm.Id
            )
        ORDER BY gsm.Name
    ) GSM

    WHERE
        ob.DesignationID = 1
        AND ob.Active = 1
        AND d.Active = 1

    ORDER BY
        d.Code,
        ob.Name;