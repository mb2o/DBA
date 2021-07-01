DECLARE @databaseList AS CURSOR;
DECLARE @databaseName AS NVARCHAR(500);
DECLARE @tsql AS NVARCHAR(2000);

CREATE TABLE ##FreeSpace (
	[DbName] VARCHAR(1000)
	,[FreeSpaceInMb] DECIMAL(12, 2)
	,[Name] VARCHAR(1000)
	,[Filename] VARCHAR(1000)
	);

SET @databaseList = CURSOR LOCAL FORWARD_ONLY STATIC READ_ONLY
FOR

SELECT QUOTENAME([name])
FROM master.dbo.sysdatabases -- FOR SQL Server 2000 if you are doing archeological sql work. there is no sys.databases
WHERE DATABASEPROPERTYEX([name], 'Status') = 'ONLINE' -- version will be zero if the database is offline.
	AND [name] <> 'tempdb'

OPEN @databaseList;

FETCH NEXT
FROM @databaseList
INTO @databaseName;

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @tsql = N'
    USE ' + @databaseName + ';
    INSERT INTO ##FreeSpace
    SELECT ''' + @databaseName + ''' as DbName,
            CAST(CONVERT(DECIMAL(12,2),
                Round((t1.size-Fileproperty(t1.name,''SpaceUsed''))/128.000,2)) AS VARCHAR(10)) AS [FreeSpaceMB],
           CAST(t1.name AS VARCHAR(500)) AS [Name], 
           Filename
    FROM ' + @databaseName + '.dbo.sysfiles t1;';

	EXECUTE (@tsql);

	FETCH NEXT
	FROM @databaseList
	INTO @databaseName;
END

CLOSE @databaseList;

DEALLOCATE @databaseList;

SELECT *
FROM ##FreeSpace
ORDER BY FreeSpaceInMb DESC;

DROP TABLE ##FreeSpace;

