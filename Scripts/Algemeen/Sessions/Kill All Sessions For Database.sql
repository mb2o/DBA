DECLARE @DbName NVARCHAR(50);

SET @DbName = N'AdventureWorks';

DECLARE @EXECSQL VARCHAR(max);

SET @EXECSQL = '';

SELECT @EXECSQL = @EXECSQL + 'Kill ' + CONVERT(VARCHAR, SPId) + ';'
FROM MASTER..SysProcesses
WHERE DBId = DB_ID(@DbName)
	AND SPId <> @@SPId;

EXEC (@EXECSQL);
