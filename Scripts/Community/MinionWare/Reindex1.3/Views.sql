IF EXISTS
(
    SELECT name
    FROM sys.objects
    WHERE name = 'IndexMaintLogCurrent'
          AND SCHEMA_NAME(schema_id) = 'Minion'
)
BEGIN
    DROP VIEW Minion.IndexMaintLogCurrent;
END;
GO

/****** Object:  View [Minion].[IndexMaintLogCurrent]    Script Date: 2/23/2017 2:35:15 PM ******/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO


CREATE VIEW [Minion].[IndexMaintLogCurrent]
AS
/* This view provides a look at the latest reindex batch. 

	Use: 
	SELECT * FROM Minion.IndexMaintLogCurrent
	ORDER BY ExecutionDateTime, DBName;

	SELECT * FROM Minion.IndexMaintLogCurrent
	ORDER BY DBName;
*/
SELECT I1.ID,
    I1.ExecutionDateTime,
    I1.Status,
    I1.DBName,
    I1.Tables,
    I1.RunPrepped,
    I1.PrepOnly,
    I1.ReorgMode,
    I1.NumTablesProcessed,
    I1.NumIndexesProcessed,
    I1.NumIndexesRebuilt,
    I1.NumIndexesReorged,
    I1.RecoveryModelChanged,
    I1.RecoveryModelCurrent,
    I1.RecoveryModelReindex,
    I1.SQLVersion,
    I1.SQLEdition,
    I1.DBPreCode,
    I1.DBPostCode,
    I1.DBPreCodeBeginDateTime,
    I1.DBPreCodeEndDateTime,
    I1.DBPostCodeBeginDateTime,
    I1.DBPostCodeEndDateTime,
    I1.DBPreCodeRunTimeInSecs,
    I1.DBPostCodeRunTimeInSecs,
    I1.ExecutionFinishTime,
    I1.ExecutionRunTimeInSecs,
    I1.IncludeDBs,
    I1.ExcludeDBs,
    I1.RegexDBsIncluded,
    I1.RegexDBsExcluded,
    I1.Warnings
FROM Minion.IndexMaintLog I1
WHERE ExecutionDateTime IN
      (
          SELECT MAX(I2.ExecutionDateTime)
          FROM Minion.IndexMaintLog I2
          WHERE I1.DBName = I2.DBName
      );


GO

IF EXISTS
(
    SELECT name
    FROM sys.objects
    WHERE name = 'IndexMaintLogDetailsCurrent'
          AND SCHEMA_NAME(schema_id) = 'Minion'
)
BEGIN
    DROP VIEW Minion.IndexMaintLogDetailsCurrent;
END;
GO

/****** Object:  View [Minion].[IndexMaintLogDetailsCurrent]    Script Date: 2/23/2017 2:35:15 PM ******/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE VIEW [Minion].[IndexMaintLogDetailsCurrent]
AS
/* This view provides a look at the latest reindex batch. 

	Use: 
	SELECT * FROM Minion.IndexMaintLogDetailsCurrent
	ORDER BY ExecutionDateTime, DBName, SchemaName, TableName;
*/
SELECT
    --CASE WHEN ISNULL(PctComplete, 0) IN ( 0, 100 ) THEN NULL
    --                 ELSE DATEDIFF(SECOND, BackupStartDateTime, GETDATE())
    --            END AS [EstRemainingSec]
    --          , CASE WHEN ISNULL(PctComplete, 0) NOT IN ( 0, 100 )
    --                 THEN DATEDIFF(SECOND, BackupStartDateTime, GETDATE())
    --                      * 100 / PctComplete
    --                 ELSE NULL
    --            END AS [EstTotalSec]
    --          , CASE WHEN ISNULL(PctComplete, 0) NOT IN ( 0, 100 )
    --                 THEN DATEADD(SECOND,
    --                              DATEDIFF(SECOND, BackupStartDateTime,
    --                                       GETDATE()) * 100 / PctComplete,
    --                              BackupStartDateTime)
    --                 ELSE NULL
    --            END AS [EstCompleteTime]
    ID,
    ExecutionDateTime,
    Status,
    DBName,
    TableID,
    SchemaName,
    TableName,
    IndexID,
    IndexName,
    IndexTypeDesc,
    IndexScanMode,
    Op,
    ONLINEopt,
    ReorgThreshold,
    RebuildThreshold,
    FILLFACTORopt,
    PadIndex,
    FragLevel,
    Stmt,
    ReindexGroupOrder,
    ReindexOrder,
    PreCode,
    PostCode,
    OpBeginDateTime,
    OpEndDateTime,
    OpRunTimeInSecs,
    TableRowCTBeginDateTime,
    TableRowCTEndDateTime,
    TableRowCTTimeInSecs,
    TableRowCT,
    PostFragBeginDateTime,
    PostFragEndDateTime,
    PostFragTimeInSecs,
    PostFragLevel,
    UpdateStatsBeginDateTime,
    UpdateStatsEndDateTime,
    UpdateStatsTimeInSecs,
    UpdateStatsStmt,
    PreCodeBeginDateTime,
    PreCodeEndDateTime,
    PreCodeRunTimeInSecs,
    PostCodeBeginDateTime,
    PostCodeEndDateTime,
    PostCodeRunTimeInSecs,
    UserSeeks,
    UserScans,
    UserLookups,
    UserUpdates,
    LastUserSeek,
    LastUserScan,
    LastUserLookup,
    LastUserUpdate,
    SystemSeeks,
    SystemScans,
    SystemLookups,
    SystemUpdates,
    LastSystemSeek,
    LastSystemScan,
    LastSystemLookup,
    LastSystemUpdate,
    Warnings
FROM Minion.IndexMaintLogDetails ID1
WHERE ExecutionDateTime IN
      (
          SELECT MAX(ID2.ExecutionDateTime)
          FROM Minion.IndexMaintLogDetails ID2
          WHERE ID1.DBName = ID2.DBName
      );


GO
