SELECT OBJECT_NAME(IX.OBJECT_ID) TableName,
	IX.name AS IndexName,
	IX.type_desc IndexType,
	SUM(PS.[used_page_count]) * 8 AS IndexSizeKB,
	IXUS.user_seeks AS NumOfSeeks,
	IXUS.user_scans AS NumOfScans,
	IXUS.user_lookups AS NumOfLookups,
	IXUS.user_updates AS NumOfUpdates,
	IXUS.last_user_seek AS LastSeek,
	IXUS.last_user_scan AS LastScan,
	IXUS.last_user_lookup AS LastLookup,
	IXUS.last_user_update AS LastUpdate
FROM sys.indexes IX
INNER JOIN sys.dm_db_index_usage_stats IXUS ON IXUS.index_id = IX.index_id
	AND IXUS.OBJECT_ID = IX.OBJECT_ID
INNER JOIN sys.dm_db_partition_stats PS ON PS.object_id = IX.object_id
WHERE OBJECTPROPERTY(IX.OBJECT_ID, 'IsUserTable') = 1
GROUP BY OBJECT_NAME(IX.OBJECT_ID),
	IX.name,
	IX.type_desc,
	IXUS.user_seeks,
	IXUS.user_scans,
	IXUS.user_lookups,
	IXUS.user_updates,
	IXUS.last_user_seek,
	IXUS.last_user_scan,
	IXUS.last_user_lookup,
	IXUS.last_user_update
