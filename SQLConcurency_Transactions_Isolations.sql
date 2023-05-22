use BobsShoes
go

SELECT @@VERSION as [VERSION]
GO

/* TRANSACTION WITH SAVEPOINTS */

BEGIN TRANSACTION MathsConstants;	-- MUST have the same name as the outter most COMMIT TRAN  
	-- [transaction-1]
	INSERT INTO [dbo].[TestSavePoints] ([ConstantName], [ConstantValue])
		VALUES	('one', 1),
				('two', 2),
				('one half', 0.5), 
				('pi', 3.14159);

	-- [savepoint-1] save the above transaction
	SAVE TRANSACTION TheFirstfourConstants;

	-- [transaction-2]
	INSERT INTO [dbo].[TestSavePoints] ([ConstantName], [ConstantValue])
		VALUES	('tau', 6.28318);

	-- show the table set at current stage of transaction
	SELECT 'Present the table set at the first transaction, before rollback-1' AS [When], * FROM [dbo].[TestSavePoints];

	-- [rollback-1] returns to the first savepoint
	ROLLBACK TRANSACTION TheFirstfourConstants;

	-- show the table set at current stage after the first rollback
	SELECT 'Present the table set, after rollback-1' AS [When], * FROM [dbo].[TestSavePoints];

	-- [transaction-3]
	INSERT INTO [dbo].[TestSavePoints] ([ConstantName], [ConstantValue])
		VALUES	('square root of 2', 1.41421);

	-- sysname is a built in datatype limited to 128 Unicode characters used primarily to store object names when creating scripts; Similarly, when declaring stored procedure parameters, you can use @ParameterName sysname to store the name of a table or column that needs to be referenced
	DECLARE @MyTableName sysname = N'ConstantsTransactions';

	-- [savepoint-2] save the above transaction (omitting the rolled back transaction)
	SAVE TRANSACTION @MyTableName;

	-- [transaction-4]
	INSERT INTO [dbo].[TestSavePoints] ([ConstantName], [ConstantValue])
		VALUES	('square root of 3', 1.73205);

	-- show the table set at current stage of transaction
	SELECT 'Present the table set at the fourth transaction, before rollback-2' AS [When], * FROM [dbo].[TestSavePoints];

	-- [rollback-2] returns to the first savepoint
	ROLLBACK TRANSACTION @MyTableName;

COMMIT TRANSACTION MathsConstants;	-- MUST have the same name as the outter most BEGIN TRAN

-- show the table set at current stage after the second rollback
SELECT 'Present the table set, after rollback-2' AS [When], * FROM [dbo].[TestSavePoints];
GO


-- This query view to determine the current isolation level in application 
 SELECT 
    CASE transaction_isolation_level 
        WHEN 0 THEN 'Unspecified' 
        WHEN 1 THEN 'ReadUncommitted' 
        WHEN 2 THEN 'ReadCommitted' 
        WHEN 3 THEN 'Repeatable' 
        WHEN 4 THEN 'Serializable' 
        WHEN 5 THEN 'Snapshot' 
    END AS TRANSACTION_ISOLATION_LEVEL 
FROM sys.dm_exec_sessions 
WHERE session_id = @@SPID;

GO



 /* READ UNCOMMITTED (NOLOCK) */

 -- SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

 -- SELECT * FROM [dbo].[TestSavePoints] (NOLOCK) WHERE Id = 1;						-- this table hint allows to read uncommitted data
 -- SELECT * FROM [dbo].[TestSavePoints] WITH (READUNCOMMITTED) WHERE Id = 1;		-- this table hint allows to read uncommitted (READUNCOMMITTED) or committed (COMMITTED) data


  
  /* READ COMMITTED (DEFAULT LOCK) */

 -- SET TRANSACTION ISOLATION LEVEL READ COMMITTED;



/* REPEATED READ  */

 -- SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;		-- prevents LOST UPDATE and NON REPEATABLE READ anomalies when same data are read and update simultaneouly


 /* SERIALIZABLE */							

 -- SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;		-- prevents PHANTOM READS


 -- example of PHANTOM READ									-- 
	-- phantom read happens even under READ COMMITTED isolation
BEGIN TRANSACTION;

-- transaction 1, first read, before the concurrent insert operation
SELECT * FROM [Orders].[Orders]
WHERE OrderDate BETWEEN '2021-01-01' AND '2025-12-01';

WAITFOR DELAY '00:00:08'		-- simulate operation delay of 08 sec

-- transaction 2, second read after the concurrent insert in the same table
SELECT * FROM [Orders].[Orders]
WHERE OrderDate BETWEEN '2021-01-01' AND '2025-12-01';

COMMIT TRANSACTION;    

GO




/* SNAPSHOTS */

-- 1, enable the RCSI (Read Commit Snapshot Isolation)
USE BobsShoes;
GO

ALTER DATABASE BobsShoes SET READ_COMMITTED_SNAPSHOT ON;
GO


-- 2, check the current Snapshot Isolation settings for selected database
	-- Show snapshot settings
SELECT DB_NAME(database_id), 
    is_read_committed_snapshot_on,
    snapshot_isolation_state_desc 
    
FROM sys.databases
WHERE database_id = DB_ID();


-- 3, grant permission to commands that need Snapshot Isolation
ALTER DATABASE BobsShoes SET ALLOW_SNAPSHOT_ISOLATION ON;
GO
-- SET TRANSACTION ISOLATION LEVEL SNAPSHOT;		-- for the transaction permission


-- trial

BEGIN TRANSACTION;

-- transaction 1, first read, before the concurrent insert operation
SELECT * FROM [Orders].[Orders]
WHERE OrderDate BETWEEN '2021-01-01' AND '2025-12-01';

WAITFOR DELAY '00:00:08'		-- simulate operation delay of 08 sec

-- transaction 2, second read after the concurrent insert in the same table
SELECT * FROM [Orders].[Orders]
WHERE OrderDate BETWEEN '2021-01-01' AND '2025-12-01';

COMMIT TRANSACTION;    

GO

/* DYNAMIC MANAGEMENT VIEWS (DMVs)  */
--  Show the active snapshot transactions
SELECT DB_NAME(database_id) AS DatabaseName, t.*
FROM sys.dm_tran_active_snapshot_database_transactions t
    JOIN sys.dm_exec_sessions s
    ON t.session_id = s.session_id;

-- Show space usage in tempdb
SELECT DB_NAME(vsu.database_id) AS DatabaseName,
    vsu.reserved_page_count, 
    vsu.reserved_space_kb, 
    tu.total_page_count as tempdb_pages, 
    vsu.reserved_page_count * 100. / tu.total_page_count AS [Snapshot %],
    tu.allocated_extent_page_count * 100. / tu.total_page_count AS [tempdb % used]
FROM sys.dm_tran_version_store_space_usage vsu
    CROSS JOIN tempdb.sys.dm_db_file_space_usage tu
WHERE vsu.database_id = DB_ID(DB_NAME());

-- Show the contents of the current version store (expensive)
SELECT DB_NAME(database_id) AS DatabaseName, *
FROM sys.dm_tran_version_store;

-- Show objects producing most versions (expensive)
SELECT DB_NAME(database_id) AS DatabaseName, *
FROM sys.dm_tran_top_version_generators;


/* -- LOCKING -- */

-- sp_WhoIsActive is a useful custom stored procedure and gives important insights from the user sessions in SQL Server with information such as lead blocker, execution plan, wait stats, query text.
EXEC dbo.sp_WhoIsActive;

----------------------
USE BobsShoes;
GO

-----
BEGIN TRAN;

INSERT INTO orders.OrderItems
    (OrderID, OrderYear, StockID, Quantity, Discount)
SELECT TOP (10000) v.*
    FROM (VALUES (1, 2019, 1, 1, 0)) v(a,b,c,d,e)
 CROSS JOIN sys.columns c1
 CROSS JOIN sys.columns c2;

ROLLBACK;

--- Transaction for user ARTHUR
DECLARE @Context varbinary(10) = CAST('Arthur' as varbinary);
SET CONTEXT_INFO @Context;
SET TRAN ISOLATION LEVEL REPEATABLE READ;
SET LOCK_TIMEOUT -1;	-- -1 is indefinite time out


BEGIN TRAN;
    SELECT * FROM Orders.Orders
    WHERE OrderID = 1;
ROLLBACK;

--- Transaction for user TRILLIAN

DECLARE @Context varbinary(10) = CAST('Trillian' as varbinary);
SET CONTEXT_INFO @Context;
SET TRAN ISOLATION LEVEL REPEATABLE READ;
SET LOCK_TIMEOUT -1;

BEGIN TRAN;
    SELECT * FROM Orders.Orders
    -- UPDATE Orders.Orders SET OrderIsExpedited = 1
    WHERE OrderID = 1;
ROLLBACK;


---- Transaction Granularity  for Session Trillian and Arthur
SELECT
    IIF(request_session_id = 53, 'Trillian', 'Arthur') AS SessionName,
    resource_type, 
    request_type, 
    request_mode,
    request_status
    
FROM sys.dm_tran_locks
WHERE request_session_id IN (53, 54)
ORDER BY request_session_id, resource_type;


---	VIEW the transaction lock per session, resourse, request and object
SELECT 
    CAST(es.context_info AS varchar(30)) AS [Session],
    tl.resource_type,
    tl.request_mode,
    tl.request_status,
    CASE tl.resource_type
        WHEN 'OBJECT' THEN OBJECT_NAME(tl.resource_associated_entity_id)
        WHEN 'KEY' THEN (
            SELECT OBJECT_NAME(p.object_id) 
            FROM sys.partitions p
            WHERE p.hobt_id = tl.resource_associated_entity_id
			)
    END AS ObjectName

FROM sys.dm_tran_locks tl
JOIN sys.dm_exec_sessions es
  ON tl.request_session_id = es.session_id
WHERE es.context_info <> 0x00
ORDER BY es.context_info, resource_type;

---	VIEW the lock escallation in BobsShoes Database
SELECT resource_type, 
       request_mode, 
       request_status, 
       resource_associated_entity_id
FROM sys.dm_tran_locks
WHERE resource_database_id = db_id(N'BobsShoes')

SELECT OBJECT_NAME(1429580131, db_id(N'BobsShoes'))


/*-- Optimising concurrency and Locking behaviour -- */ 

-- SYSTEM HEATH SESSION

-- Server event session
SELECT name, startup_state FROM sys.server_event_sessions;
-- find : xml_deadlock_report in Management > Extended Events > System health

-- Get XML deadlock reports (Run this query In Azure Database)
SELECT deadlock.reports.query('deadlock')
FROM sys.dm_xe_session_targets st 
JOIN sys.dm_xe_sessions s 
    ON s.address = st.event_session_address 
CROSS APPLY (SELECT CAST(st.target_data AS XML)) as t(d)
CROSS APPLY t.d.nodes
    ('RingBufferTarget/event[@name="xml_deadlock_report"]/data/value') 
    AS deadlock(reports)
WHERE s.name = 'system_health' 
    AND st.target_name = 'ring_buffer';


-- Create a Custom Event Session to collect all deadlock 
-- Create extended event session
CREATE EVENT SESSION [Deadlocks] ON SERVER		-- Create the Event Session [Deadlocks]

ADD EVENT sqlserver.xml_deadlock_report			-- add event of interest

ADD TARGET package0.asynchronous_file_target
    (SET filename = N'c:\temp\Deadlocks\Deadlocks.xel');	-- specific location folder
GO

-- Start the new session
ALTER EVENT SESSION [Deadlocks] ON SERVER STATE = START;	-- Start the deadloack


SELECT *
FROM sys.fn_xe_file_target_read_file('C:\temp\Deadlocks\Deadlocks.xel', NULL, NULL, NULL); -- to read the report file from disk


--- example of Deadlock Priority setting
SET LOCK_TIMEOUT -1;
SET DEADLOCK_PRIORITY HIGH;
    -- NORMAL, HIGH, -10 to 10, char or int variable

BEGIN TRAN;
    UPDATE Orders.Orders 
        SET OrderIsExpedited = 1
        WHERE OrderID = 1;

    WAITFOR DELAY '00:00:10';
    
    UPDATE Orders.OrderItems 
        SET Quantity += 1
        WHERE OrderID = 1
ROLLBACK;

---
EXEC sp_readerrorlog