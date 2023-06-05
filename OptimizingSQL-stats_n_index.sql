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

		ALTER DATABASE [AdventureWorksLT2022]		
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





/* -- MAINTAINING ROWSTORE INDEXES -- */

	-- 1 -- Identify which index is fragmented enough to need maintenance
		 -- in LIMITED MODE the leaf level of the page is not read so the [AVG_PAGE_SPACE_USED_IN_PERCENT] can't be computed
		 -- for the evaluation the bigger, the concern: So check the %OF FRAGMENTATION, then THE PAGE COUNT, then in detailled mode check THE SIZE OF THE PAGE
SELECT OBJECT_SCHEMA_NAME(i.object_id) AS SchemaName, OBJECT_NAME(i.object_id) TableName, 
	i.name,
	ips.partition_number, 
	ips.index_type_desc, 
	ips.index_level,					-- 0 for Leaves, 1 for Intermediate, 2  for Root (the highest the lower the page count)
	ips.avg_fragmentation_in_percent,	-- page fragmentation
	ips.page_count,						-- from 1000 + (it becomes a concern for the rebuild)
	ips.avg_page_space_used_in_percent	-- percentage of page full
	FROM sys.indexes i 
		INNER JOIN sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'detailed') ips --  limited or detailed / sampled  
			ON ips.object_id = i.object_id AND ips.index_id = i.index_id
	--WHERE ips.avg_fragmentation_in_percent >30 AND ips.page_count > 1000	--[FILTER]
	--WHERE ips.object_id = i.object_id AND ips.index_id = i.index_id
	--WHERE i.name = 'idx_ShipmentDetails_ShipmentID';

-- OR 

SELECT OBJECT_SCHEMA_NAME(ips.object_id) AS schema_name,
       OBJECT_NAME(ips.object_id) AS object_name,
       i.name AS index_name,
       i.type_desc AS index_type,
       ips.avg_fragmentation_in_percent,
       ips.avg_page_space_used_in_percent,
       ips.page_count,
       ips.alloc_unit_type_desc
FROM sys.dm_db_index_physical_stats(DB_ID(), default, default, default, 'SAMPLED') AS ips
INNER JOIN sys.indexes AS i 
ON ips.object_id = i.object_id
   AND
   ips.index_id = i.index_id
ORDER BY page_count DESC;


	-- 2 Syntax for Index Rebuilds

-- Syntax for SQL Server and Azure SQL Database


ALTER INDEX PK_Product_ProductID ON [AdventureWorksLT2022].[SalesLT].[Product]	-- can use option ALL to rebuild all indexes associated with the table or view regardless of the index type
REBUILD
WITH
(
	PAD_INDEX = OFF						-- PAD_INDEX is ON, free space is allocated on intermediate-level index pages based on the specified or default fill factor value. When PAD_INDEX is OFF or fill factor is not specified, the pages are filled to near capacity, leaving space for at least one maximum-sized row based on the index's keys.
	FILLFACTOR = fillfactor				-- (creates the page split) The intermediate-level pages are filled to near capacity from 0 to 100 / The default is 0. the desired level of fullness for index pages during their creation or alteration. The specified fill factor applies only during the initial operation and is not dynamically maintained afterward.
	SORT_IN_TEMPDB = OFF				-- Determines where intermediate sort results are stored during index building. Here's a summary; ON: Intermediate sort results are stored in tempdb. This can improve index creation time if tempdb is on separate disks, but increases disk space usage; OFF: Intermediate sort results are stored in the same database as the index.
	ONLINE = OFF						-- { ON [ ( <low_priority_lock_wait> ) ] | OFF } -- Specifies whether underlying tables and associated indexes are available for queries and data modification during the index operation. The default is OFF.
	RESUMABLE = ON						-- Specifies whether an online index operation is resumable. ON Index operation is resumable; OFF Index operation isn't resumable.
	MAX_DURATION = 60					-- <time> [MINUTES} -- used with RESUMABLE = ON (requires ONLINE = ON)
	MAXDOP = max_degree_of_parallelism	-- Use MAXDOP to limit the number of processors used in a parallel plan execution. The maximum is 64 processors.
);


ALTER INDEX PK_Product_ProductID ON [AdventureWorksLT2022].[SalesLT].[Product]
REBUILD
WITH 
(
    FILLFACTOR = 90,
    SORT_IN_TEMPDB = OFF,
    ONLINE = OFF,
    RESUMABLE = ON,
    MAX_DURATION = 60,
    MAXDOP = 8
);


	-- 2' Syntax for Index Reorganise
ALTER INDEX PK_Product_ProductID ON [AdventureWorksLT2022].[SalesLT].[Product]	-- option ALL to regorganise all indexes associated with the table or view regardless
   REORGANIZE
   WITH
   (
	LOB_COMPACTION = ON		-- only applies to indexes that contain LOB data types (VARCHARMAX, NVARCHARMAX, VARBINARYMAX or XML). it determines is those large datatype are stored out of rows are compacted or not. Can help reduce space usage
   );


/*  (SAMPLE_QUERY) RESTORE A DATABASE FROM DISK
USE [MASTER]

ALTER DATABASE [basics] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

RESTORE DATABASE [basics] FROM DISK = N'D:\Local\MSSQL\Backup\basics.bak' WITH REPLACE, NOUNLOAD, STATS = 5

GO
*/


	-- 3 for optimal maintenance use: The SQL Server Maintenance Solution
			-- by Ola Hallengren

/*

Download MaintenanceSolution.sql. This script creates all the objects and jobs that you need.

You can also download the objects as separate scripts:

DatabaseBackup: SQL Server Backup
DatabaseIntegrityCheck: SQL Server Integrity Check
IndexOptimize: SQL Server Index and Statistics Maintenance
CommandExecute: Stored procedure to execute and log commands
CommandLog: Table to log commands
Note that you always need CommandExecute; DatabaseBackup, DatabaseIntegrityCheck, and IndexOptimize are using it. You need CommandLog if you are going to use the option to log commands to a table.

Supported versions: SQL Server 2008, SQL Server 2008 R2, SQL Server 2012, SQL Server 2014, SQL Server 2016, SQL Server 2017, SQL Server 2019, SQL Server 2022, Azure SQL Database, and Azure SQL Managed Instance

Documentation
Backup: https://ola.hallengren.com/sql-server-backup.html
Integrity Check: https://ola.hallengren.com/sql-server-integrity-check.html
Index and Statistics Maintenance: https://ola.hallengren.com/sql-server-index-and-statistics-maintenance.html

*/






/* -- MAINTAINING COLUMNSTORE INDEXES -- */

	-- 1 -- Identify which columnstore index is fragmented enough to need maintenance
SELECT OBJECT_SCHEMA_NAME(i.object_id) AS schema_name,
       OBJECT_NAME(i.object_id) AS object_name,
       i.name AS index_name,
       i.type_desc AS index_type,
       100.0 * (ISNULL(SUM(rgs.deleted_rows), 0)) / NULLIF(SUM(rgs.total_rows), 0) AS avg_fragmentation_in_percent
FROM sys.indexes AS i
INNER JOIN sys.dm_db_column_store_row_group_physical_stats AS rgs
ON i.object_id = rgs.object_id
   AND
   i.index_id = rgs.index_id
WHERE rgs.state_desc = 'COMPRESSED'
GROUP BY i.object_id, i.index_id, i.name, i.type_desc
ORDER BY schema_name, object_name, index_name, index_type;



		 -- Identifying Columnstore with deleted rows
SELECT OBJECT_SCHEMA_NAME(rg.object_id) AS SchemaName,
       OBJECT_NAME(rg.object_id) AS TableName,
       i.name AS IndexName,
       i.type_desc AS IndexType,
       rg.partition_number,
       rg.state_description,
       COUNT(*) AS NumberOfRowgroups,
       SUM(rg.total_rows) AS TotalRows,
       SUM(rg.size_in_bytes) AS TotalSizeInBytes,
       SUM(rg.deleted_rows) AS TotalDeletedRows
FROM sys.column_store_row_groups AS rg INNER JOIN sys.indexes AS i ON i.object_id = rg.object_id AND i.index_id = rg.index_id
GROUP BY rg.object_id,
         i.name,
         i.type_desc,
         rg.partition_number,
         rg.state_description
ORDER BY TableName,
         IndexName,
         rg.partition_number;


		-- Indentify columnstore with open rowgroup (The DELTASTORE)
SELECT OBJECT_SCHEMA_NAME(rg.object_id) AS SchemaName,
       OBJECT_NAME(rg.object_id) AS TableName,
       i.name AS IndexName,
       i.type_desc AS IndexType,
       rg.partition_number,
       rg.row_group_id,
       rg.total_rows,
       rg.size_in_bytes,
       rg.deleted_rows,
       rg.[state],
       rg.state_description
FROM sys.column_store_row_groups AS rg
    INNER JOIN sys.indexes AS i ON i.object_id = rg.object_id AND i.index_id = rg.index_id
WHERE state_description != 'TOMBSTONE' --	TOMBSTONE(Left-over comlumnstore after Tuple-mover has compressesed closed group)
ORDER BY TableName,
         IndexName,
         rg.partition_number,
         rg.row_group_id;


	-- 2 -- REORGANISE COLUMNSTORE INDEX
ALTER INDEX PK_Product_ProductID ON [AdventureWorksLT2022].[SalesLT].[Product]
    REORGANIZE 
	WITH 
	(
		COMPRESS_ALL_ROW_GROUPS = ON	-- This command will force all closed and open row groups into columnstore.
	);


/* -- MAINTAINING STATISTICS -- */

	-- 1 -- Examine what information statistics contain
DBCC SHOW_STATISTICS('[SalesLT].[Product]', 'PK_Product_ProductID')		-- take a table name and an index as  input and returns tree output stats related to that index
/*
	First output: the overall stats for the column that the statistic is built from (i.e: last update date, total row number
	Second output: the list of densities (the measure of uniqueness) of the left-based subsets of the columns involved in the stats (density= 1/number of unique value)
	Third output: the histogram (RANGE_HI_KEY: the value present in the indexed column; RANGE_ROWS: the pace between the value present a row and the one before it, EQ_ROWS: the number of rows matching that value exactly; DISTINCT_RANGE_ROWS: the number of unique value between the HI_KEY value and the value before it; AVG_RANGE_ROWS is for that range how many row will match HI_KEY value

*/		

DBCC SHOW_STATISTICS('[Orders].[Orders2018]', '[PK_Orders2018_OrderYear_OrderID]')	


		 -- Query Sensitive Bad Statistics
DBCC SHOW_STATISTICS
SET STATISTICS IO, TIME ON
GO

DBCC FREEPROCCACHE
GO

SELECT * FROM [SalesLT].[vProductModelCatalogDescription]
WHERE [ModifiedDate] > '2005'



		-- Turn Statistcs Update OFF/ON
ALTER DATABASE InterstellarTransport SET AUTO_UPDATE_STATISTICS OFF
GO

	-- 2 -- MANUAL STATISTICS UPDATE
UPDATE STATISTICS [SalesLT].[Product] PK_Product_ProductID -- or Not specifying an index will update for all indexes associated to that table
WITH
FULLSCAN, -- or SAMPLE or RESAMPLE // SAMPLE 10 or 100 PERCENT or SAMPLE 1000 ROWS if rows concerned, // or WITH FULLSCAN, COLUMNS // RESAMPLE means using the last sample update parameters
NORECOMPUTE, -- Not good because it disables automatic stats updates on the statistics object
INCREMENTAL = ON	-- or OFF
