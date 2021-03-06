USE DBA;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROC dbo.usp_DriveSpace
    @xp_fixeddrivesCompat BIT = 0, -- return results matching the format of xp_fixeddrives, allows use as a drop in replacement for xp_fixeddrives
    @unit VARCHAR(4) = 'GB'        -- BYTE, KB, MB, GB or TB - ignored if @xp_fixeddrivesCompat = 1
AS
BEGIN

    IF OBJECT_ID('tempdb..#driveinfo') IS NOT NULL
        DROP TABLE #driveinfo;

    -- check for valid unit value
    IF @unit NOT IN ( 'BYTE', 'KB', 'MB', 'TB', 'GB' )
        RAISERROR(N'Invalid Unit Specified, Must Be BYTE, KB, MB, GB or TB', 15, 1);

    -- set divisor, to be used when converting units
    DECLARE @divisor BIGINT;
    SELECT @divisor = CASE @unit
                          WHEN 'BYTE' THEN
                              1
                          WHEN 'KB' THEN
                              1024
                          WHEN 'MB' THEN
                              POWER(1024, 2)
                          WHEN 'GB' THEN
                              POWER(1024, 3)
                          WHEN 'TB' THEN
                              POWER(CAST(1024 AS BIGINT), 4)
                      END;

    CREATE TABLE #driveinfo
    (
        volume_mount_point NVARCHAR(512),
        available_bytes BIGINT,
        total_bytes BIGINT,
        logical_volume_name NVARCHAR(512)
    );

    -- DistinctDrives derived table updated to show all database_id and file_id combinations grouped by file path.
    -- Row number is applied so that we can filter just one database_id and file_id combination per file path and then these 
    -- combinations are passed to the sys.dm_os_volume_stats system TVF , the reason for the filtering within the derived table is
    -- to reduce the number of executions performed by the TVF because on instances with lots of databases this can slow execution.

    INSERT INTO #driveinfo
    (
        volume_mount_point,
        available_bytes,
        total_bytes,
        logical_volume_name
    )
    SELECT      DISTINCT
                volumestats.volume_mount_point,
                volumestats.available_bytes,
                volumestats.total_bytes,
                logical_volume_name
    FROM
                (
                    SELECT database_id,
                           file_id,
                           ROW_NUMBER() OVER (PARTITION BY SUBSTRING(
                                                                        physical_name,
                                                                        1,
                                                                        LEN(physical_name) - CHARINDEX('\', REVERSE(physical_name))
                                                                        + 1
                                                                    )
                                              ORDER BY SUBSTRING(
                                                                    physical_name,
                                                                    1,
                                                                    LEN(physical_name) - CHARINDEX('\', REVERSE(physical_name)) + 1
                                                                ) ASC
                                             ) AS "RowNum"
                    FROM   sys.master_files
                    WHERE  database_id IN
                           (
                               SELECT database_id FROM sys.databases WHERE state = 0
                           )
                ) AS DistinctDrives
    CROSS APPLY sys.dm_os_volume_stats(DistinctDrives.database_id, DistinctDrives.file_id) AS volumestats
    WHERE       DistinctDrives.RowNum = 1;

    IF @xp_fixeddrivesCompat = 1
    BEGIN
        SELECT volume_mount_point,
               available_bytes / 1024 / 1024 AS "MB free"
        FROM   #driveinfo;
    END;
    ELSE
    BEGIN
        SELECT volume_mount_point,
               CAST(CAST(available_bytes AS DECIMAL(20, 2)) / @divisor AS DECIMAL(20, 2)) AS "Available",
               CAST(CAST(total_bytes AS DECIMAL(20, 2)) / @divisor AS DECIMAL(20, 2)) AS "Total",
               CAST(available_bytes AS DECIMAL(20, 2)) / CAST(total_bytes AS DECIMAL(20, 2)) * 100 AS "PercentFree"
        FROM   #driveinfo;
    END;
END;
GO


