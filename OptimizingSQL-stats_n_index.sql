/* -- OPTIMIZING SQL SERVER STATISTICS AND INDEXES -- */


-- A -- Querying missing indexes in the DMVs
	-- 1 (although, if looking for poor performing queries, it is better start with the query plan instead)
SELECT DB_NAME(mid.database_id) AS DatabaseName,
       OBJECT_SCHEMA_NAME(mid.object_id, mid.database_id) AS SchemaName,
       OBJECT_NAME(mid.object_id, mid.database_id) AS ObjectName,
       migs.avg_user_impact,
       mid.equality_columns,
       mid.inequality_columns,
       mid.included_columns
FROM sys.dm_db_missing_index_groups mig
    INNER JOIN sys.dm_db_missing_index_group_stats migs
        ON migs.group_handle = mig.index_group_handle
    INNER JOIN sys.dm_db_missing_index_details mid
        ON mig.index_handle = mid.index_handle;


-- 1 and 2 -- FIND AND CREATE ANY MISSING INDEXES
SELECT
UPPER(DB_Name()) as 'DATABASE',
Object_Name(SQLOPS_MsgIdxDetails.object_id) as 'OBJECT NAME',
Schema_Name(SQLOPS_SysObj.schema_id) as 'SCHEMA NAME',
'CREATE INDEX '+DB_Name()+'_SQLOPS_'+
Object_Name(SQLOPS_MsgIdxDetails.object_id)+'_' +
CONVERT (varchar, SQLOPS_MsgIdxGrp.index_group_handle) + '_' +
CONVERT (varchar, SQLOPS_MsgIdxDetails.index_handle) + ' ON ' +
SQLOPS_MsgIdxDetails.statement + '
(' + ISNULL (SQLOPS_MsgIdxDetails.equality_columns,'')
+ CASE WHEN SQLOPS_MsgIdxDetails.equality_columns IS NOT NULL
AND SQLOPS_MsgIdxDetails.inequality_columns IS NOT NULL
THEN ',' ELSE '' END + ISNULL (SQLOPS_MsgIdxDetails.inequality_columns, '')
+ ')'
+ ISNULL (' INCLUDE (' + SQLOPS_MsgIdxDetails.included_columns + ');', '')
AS 'CREATE INDEX COMMAND', --Online Index will work only if you have Enterprise edition
Cast(round(SQLOPS_MsgIdxGrpStats.avg_total_user_cost,2) as varchar)+'%'
as 'ESTIMATED CURRENT COST',
Cast(SQLOPS_MsgIdxGrpStats.avg_user_impact as varchar)+'%' as 'CAN BE IMPROVED',
SQLOPS_MsgIdxGrpStats.last_user_seek as 'LAST USER SEEK',
'SCRIPT PROVIDED BY HTTPS://SQLOPS.COM' as 'CREDITS'
FROM sys.dm_db_missing_index_groups AS SQLOPS_MsgIdxGrp
INNER JOIN sys.dm_db_missing_index_group_stats AS SQLOPS_MsgIdxGrpStats
ON SQLOPS_MsgIdxGrpStats.group_handle = SQLOPS_MsgIdxGrp.index_group_handle
INNER JOIN sys.dm_db_missing_index_details AS SQLOPS_MsgIdxDetails
ON SQLOPS_MsgIdxGrp.index_handle = SQLOPS_MsgIdxDetails.index_handle
INNER JOIN sys.objects as SQLOPS_SysObj
ON SQLOPS_MsgIdxDetails.object_id = SQLOPS_SysObj.object_id
ORDER BY 4 desc

-- 2 create the missing index (here based on the recommendation from SQLOPS.COM ^^
-- CREATE INDEX Pluralsight_SQLOPS_DiskBasedTable_8_7 ON [Pluralsight].[dbo].[DiskBasedTable]  ([ID]) INCLUDE ([FName], [LName]);


-- 3 -- Analyse impact of the created index in the Query Store
/* Query Store is not enabled by default for SQL Server 2016, 2017, 2019 (15.x). It is enabled by default in the READ_WRITE mode for new databases starting with SQL Server 2022 (16.x).

		ALTER DATABASE Pluralsight		
		SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE);

*/

		-- CONVERT THE DATABASE INTO READ-ONLY WHEN TESTING THE DTA RECOMMENDATIONS 
		ALTER DATABASE [SQLAuthority] -- example: AdventureWorksLT2022
		SET QUERY_STORE = ON (OPERATION_MODE = READ_ONLY);


-- B -- Can also collect missing index by analysing the all the transaction from a TRACE FILE (.trc) and analysing it in the DTA.

-- 1-- example of index optimisation from the DTA
use [SQLAuthority]
go

/*	here are two example the recommendation of index to create on the table made by the DTA
	although the need their name adjusted
	
-- 13 represents the DataBase id of SQLAuthority; 901578250 is the object id of the table DiskBasedTable; K1 is the id of the key column
CREATE CLUSTERED INDEX [_dta_index_DiskBasedTable_c_13_901578250__K1] ON [dbo].[DiskBasedTable]	
(
	[ID] ASC
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]
go

CREATE NONCLUSTERED COLUMNSTORE INDEX [_dta_index_DiskBasedTable_13_901578250__col__] ON [dbo].[DiskBasedTable]
(
	[ID],
	[FName],
	[LName]
)WITH (DROP_EXISTING = OFF, COMPRESSION_DELAY = 0) ON [PRIMARY]
go

*/

-- 2-- Implementation of the recommended Indexes
/* before implementing any of these, you should test their impact on the DB in READ ONLY Mode

CREATE CLUSTERED INDEX [idx_SQLAuthority_DiskBasedTable] ON [dbo].[DiskBasedTable]	
(
	[ID] ASC
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]
go

CREATE NONCLUSTERED COLUMNSTORE INDEX [cmp_idx_SQLAuthority_DiskBasedTable] ON [dbo].[DiskBasedTable]
(
	[ID],
	[FName],
	[LName]
)WITH (DROP_EXISTING = OFF, COMPRESSION_DELAY = 0) ON [PRIMARY]
go

*/
-- 3 checking the impact of the index 
		-- CONVERT THE DATABASE INTO READ-ONLY WHEN TESTING THE DTA RECOMMENDATIONS 
		ALTER DATABASE [SQLAuthority] -- example: AdventureWorksLT2022
		SET QUERY_STORE = ON (OPERATION_MODE = READ_ONLY);

		-- Query to test and compare
SET STATISTICS IO, time ON

	SELECT mot1.ID, mot1.FName, mot2.LName	-- Query without the table indexed yet
	FROM [dbo].[DiskBasedTable] mot1
	INNER JOIN [dbo].[DiskBasedTable] mot2 ON mot1.ID = mot2.ID
		/*	(500000 rows affected)
			Table 'DiskBasedTable'. Scan count 18, logical reads 3258
			CPU time = 188 ms,  elapsed time = 5895 ms.
		
		*/
	
	INSERT INTO [dbo].[DiskBasedTable] (FName, LName)
	SELECT TOP 500000  'Bob',				
						CASE WHEN ROW_NUMBER() OVER (ORDER BY a.name)%123456 = 1 THEN 'Baker' 
							 WHEN ROW_NUMBER() OVER (ORDER BY a.name)%10 = 1 THEN 'Marley' 
							WHEN  ROW_NUMBER() OVER (ORDER BY a.name)%10 = 5 THEN 'Ross' 
							WHEN  ROW_NUMBER() OVER (ORDER BY a.name)%10 = 3 THEN 'Dylan' 
						ELSE 'Hope' END
	FROM sys.all_objects a
	CROSS JOIN sys.all_objects b
		/*	(500000 rows affected)
			Table 'DiskBasedTable'. Scan count 0, logical reads 2100987
			CPU time = 4500 ms,  elapsed time = 8382 ms.
		*/

-- 4 Now creating the index recommended (it is best to pick just one of the two to save index space in the whole Server Instance, only600 rows overall are available)
CREATE CLUSTERED INDEX [idx_SQLAuthority_DiskBasedTable] ON [dbo].[DiskBasedTable]	-- not so good
(
	[ID] ASC
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]
go

CREATE NONCLUSTERED COLUMNSTORE INDEX [cmp_idx_SQLAuthority_DiskBasedTable] ON [dbo].[DiskBasedTable]	-- The composite index seems better
(
	[ID],
	[FName],
	[LName]
)WITH (DROP_EXISTING = OFF, COMPRESSION_DELAY = 0) ON [PRIMARY]
go


-- B -- Querying unused indexes in the DMVs
	-- 1 -- Use the Index Usage Stats to identify unused indexes (with a focus on how the user uses them, not the system)
			-- if user_updates are higher than user_seeks and user_scans then this index should be dropped as it increase overhead.   
			-- if an index is neither used in a seek, scan, lookups and update, it can also be dropped
SELECT OBJECT_NAME(i.object_id) AS TableName,
       i.index_id,
	   i.[name],
	   i.is_unique,								-- unique indexes should never be dropped
       ISNULL(user_seeks, 0) AS UserSeeks,		-- the number of full scans on the index since last server starts 
       ISNULL(user_scans, 0) AS UserScans,		-- the number of full scans on the index since last server starts
       ISNULL(user_lookups, 0) AS UserLookups,	-- 0 for nonclustered indexes, and for clustered indexes it is the number of Keylookups done to that index
       ISNULL(user_updates, 0) AS UserUpdates	-- the number of modification done to that index (inserts, or updates, or deletes)
FROM sys.indexes i
    LEFT OUTER JOIN sys.dm_db_index_usage_stats ius		-- left join because the index shows up in the DMV once it has been used at least once since the last server starts
        ON ius.object_id = i.object_id AND ius.index_id = i.index_id
WHERE OBJECTPROPERTY(i.object_id, 'IsMSShipped') = 0;


	-- 2 -- Check in the Query Store which query use the identified index before dropping them
-- get each query's Id
SELECT * FROM sys.query_store_plan
WHERE query_plan LIKE '%[IX_MOT_I_Hash]%'	-- name of the index

SELECT * FROM sys.query_store_plan
WHERE query_plan LIKE '%[PK__DummyTab__3214EC2700693E4F]%'	-- name of the index, ID 1

-- use the query Id to identity the text of the Query to see what it is all about.
SELECT 
	qt.query_sql_text,
	q.last_execution_time
FROM sys.query_store_plan q 
	INNER JOIN sys.query_store_query_text qt
	ON qt.query_text_id = q.plan_id -- q.query_text_id	-- to be verified
WHERE q.query_id IN (13, 20, 23)

SELECT * FROM SYS.QUERY_STORE_QUERY_TEXT QT
SELECT * FROM SYS.QUERY_STORE_PLAN Q
SELECT * FROM sys.query_store_plan q 
	INNER JOIN sys.query_store_query_text qt
	ON qt.query_text_id = q.plan_id
	WHERE q.query_id =1 --IN (13, 20, 23)



-- C -- Querying duplicate (redundant) indexes in the DMVs

	-- 1 -- Get the list from which I can find duplicate indexes in a particular DB
			-- check the name and the KelCols to find similarities
SELECT OBJECT_SCHEMA_NAME(i.object_id) AS SchemaName,
       OBJECT_NAME(i.object_id) AS TableName,
       i.name,
       i.type_desc,
       STRING_AGG(c.name, ', ') WITHIN GROUP (ORDER BY key_ordinal) AS KeyCols
FROM sys.indexes i
    INNER JOIN sys.index_columns ic
        ON ic.object_id = i.object_id
           AND ic.index_id = i.index_id
    INNER JOIN sys.columns c
        ON c.object_id = i.object_id
           AND c.column_id = ic.column_id
WHERE OBJECTPROPERTYEX(i.object_id, 'IsMSShipped') = 0
      AND ic.is_included_column = 0
GROUP BY i.object_id,
         i.name,
         i.type_desc;
 
	-- 2 -- verify the index usage of the redundants indexes
		 -- check user seeks
SELECT OBJECT_NAME(i.object_id) AS TableName,
       i.index_id,
	   i.[name],
	   i.is_unique,								
       ISNULL(user_seeks, 0) AS UserSeeks,		
       ISNULL(user_scans, 0) AS UserScans,		
       ISNULL(user_lookups, 0) AS UserLookups,	
       ISNULL(user_updates, 0) AS UserUpdates	
FROM sys.indexes i
    LEFT OUTER JOIN sys.dm_db_index_usage_stats ius		
        ON ius.object_id = i.object_id AND ius.index_id = i.index_id
WHERE OBJECTPROPERTY(i.object_id, 'IsMSShipped') = 0
	AND i.name IN('[PK_Orders_OrderYear_OrderID]','[PK_Orders2018_OrderYear_OrderID]')	-- EXAMPLE

		-- check the query text (compare the Stats IO and TIME of retried query to identify which redundant to drop
SELECT 
	qt.query_sql_text,
	q.last_execution_time
FROM sys.query_store_plan q 
	INNER JOIN sys.query_store_query_text qt
	ON qt.query_text_id = q.plan_id -- q.query_text_id	-- to be verified
WHERE query_plan LIKE '%[PK_Orders_OrderYear_OrderID]%' OR query_plan LIKE '%[PK_Orders2018_OrderYear_OrderID]%' -- EXAMPLE	