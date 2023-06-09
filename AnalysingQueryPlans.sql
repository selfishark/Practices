
/* -- ACTUAL EXECUTION PLANS -- */
-- can be saved as .sqlplan and shared

-- 1 -- Graphical Execution Plans
-- CTRL+M
SELECT *
FROM WideWorldImporters.Sales.Invoices
GO

-- 2 -- Text Execution Plans (good for query comparison)
SET STATISTICS PROFILE ON
GO
SELECT *
FROM WideWorldImporters.Sales.Invoices
GO
SET STATISTICS PROFILE OFF
GO


-- 3 -- XML Execution Plans (XML file could be sent via email or other attachment)
SET STATISTICS XML ON
GO
SELECT *
FROM WideWorldImporters.Sales.Invoices
GO
SET STATISTICS XML OFF
GO


/* -- SQL PROFILER AND TRACE FILE -- */
-- 1 -- start the SQL Profiler, initiate a new trace
		-- Generate a workload, trace it and save the trace as SQL
-- 2 -- open the .sql trace file in SSMS
		-- replace the text InsertFileNameHere to a desired location i.e N'D:\Local\TraceFileBck'
		-- execute the tracefile 

exec sp_trace_setstatus 2, 1 -- Start the Trace of ID 2, to be working behind the scene to capture all the trace even if the profiler is not open (saved trace will be in N'D:\Local\TraceFileBck'
GO
exec sp_trace_setstatus 2, 0 -- Stop the Trace of ID 2
GO
exec sp_trace_setstatus 2, 2 -- Delete the Trace of ID 2
GO

-- 3 -- Extented Events
		-- Create a new session event and choose the schedule  of the events tracking
		-- select and add the action name in the event library (choose per category to make it simpler and broader)
		-- configure the global fields to come with the action tracking
		-- Specifiy the Event_file as the target, the Data Storage and limit its size (enable file rollover)

CREATE EVENT SESSION [SelfisharkEE] ON SERVER 
ADD EVENT sqlserver.query_pre_execution_showplan(
    ACTION(sqlserver.database_name,sqlserver.nt_username,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.session_id,sqlserver.sql_text))
ADD TARGET package0.event_file(SET filename=N'D:\Local\TraceFileBckSelfisharkEE')
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO



/* -- IDENTIFYING POORLY PERFORMING QUERY PLAN OPERATORS  -- */
-- 1 -- sample query
		-- check: N0 Rows (bottom left); 
		-- Check for each operator: Operation cost and actual N0 of Rows, Physical and Logical reads, Warnings and Slow performing operation (Scans, Parallelism, Implicit conversion)
		-- 
USE WideWorldImporters
GO

SELECT *
FROM Sales.Invoices i
INNER JOIN Sales.InvoiceLines il ON i.InvoiceID = il.InvoiceID
INNER JOIN Sales.Orders o ON o.OrderID = i.OrderID
WHERE BillToCustomerID > 100
GO

-- 2 -- SLOW PERFORMING OPERATORS
	 -- a -- SCANS , IMPLICIT CONVERSION

USE WideWorldImporters
GO
SET STATISTICS IO, TIME ON
GO


SELECT i.AccountsPersonID, i.CustomerPurchaseOrderNumber, il.LastEditedWhen
FROM Sales.Invoices i
INNER JOIN Sales.InvoiceLines il ON i.InvoiceID = il.InvoiceID
WHERE i.CustomerPurchaseOrderNumber = '17500'		--'17500' -- Use quotes to compare with a string value to improve Query Plan
GO

-- By enclosing the value '17500' in quotes, you are treating it as a string literal instead of an expression that requires type conversion. This can help improve the cardinality estimate and query plan choice. // THIS ALSO SOLVE IMPLICIT CONVERSION

-- Finds the query id to analyse it in the query store
SELECT 
    qsq.query_id,
    qsq.last_execution_time,
    qsqt.query_sql_text
FROM sys.query_store_query qsq
    INNER JOIN sys.query_store_query_text qsqt
        ON qsq.query_text_id = qsqt.query_text_id
WHERE
    qsqt.query_sql_text LIKE '%SELECT i.AccountsPersonID, i.CustomerPurchaseOrderNumber, il.LastEditedWhen
FROM Sales.Invoices i%';
--ORDER BY qsq.last_execution_time DESC	-- optional, can be used if no where clause

GO

-- Create missing index from DTA recommendation to improve Poorly Performing Query Plan
-- index recommendation 1
SET ANSI_PADDING ON

DROP INDEX IF EXISTS cmpIX_Invoices_SalesInvoices ON [Sales].[Invoices];
CREATE NONCLUSTERED INDEX cmpIX_Invoices_SalesInvoices ON [Sales].[Invoices]
(
	[InvoiceID] ASC,
	[CustomerPurchaseOrderNumber] ASC
)
INCLUDE([AccountsPersonID]) WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [USERDATA]

GO

-- index recommendation 2
DROP INDEX IF EXISTS cmpIX_InvoiceLines_SalesInvoiceLines ON [Sales].[InvoiceLines];
CREATE NONCLUSTERED INDEX cmpIX_InvoiceLines_SalesInvoiceLines ON [Sales].[InvoiceLines]
(
	[InvoiceID] ASC
)
INCLUDE([InvoiceLineID],[LastEditedWhen]) WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [USERDATA]

GO

-- index recommendation 3 - From SSMS itself
DROP INDEX IF EXISTS IX_CustomerPurchaseOrderNumber_SalesInvoices ON [Sales].[Invoices];
CREATE NONCLUSTERED INDEX IX_CustomerPurchaseOrderNumber_SalesInvoices
ON [Sales].[Invoices] ([CustomerPurchaseOrderNumber])

GO


-- after index creation, update Statistics
-- Update statistics for Sales.Invoices table
UPDATE STATISTICS Sales.Invoices
WITH FULLSCAN;

-- Update statistics for Sales.InvoiceLines table
UPDATE STATISTICS Sales.InvoiceLines
WITH FULLSCAN;

-- By enclosing the value '17500' in quotes, you are treating it as a string literal instead of an expression that requires type conversion. This can help improve the cardinality estimate and query plan choice.



	 -- b -- PARALLELISM
	
USE WideWorldImporters
GO
SET STATISTICS IO, TIME ON
GO


SELECT i.AccountsPersonID, il.Description, o.OrderID
FROM Sales.Invoices i
INNER JOIN Sales.InvoiceLines il ON i.InvoiceID = il.InvoiceID
INNER JOIN Sales.Orders o ON o.OrderID = i.OrderID
WHERE i.BillToCustomerID > 100
--OPTION (MAXDOP 1)		-- this HINT restrict the query to a single processor, preventing parallel query execution (HINTS NOT RECOMMENDED)
GO

-- dropping the previous index to see the impact/difference
DROP INDEX IF EXISTS cmpIX_Invoices_SalesInvoices ON [Sales].[Invoices];
DROP INDEX IF EXISTS cmpIX_InvoiceLines_SalesInvoiceLines ON [Sales].[InvoiceLines];
DROP INDEX IF EXISTS IX_CustomerPurchaseOrderNumber_SalesInvoices ON [Sales].[Invoices];


-- Finds the query id to analyse it in the query store
SELECT 
    qsq.query_id,
    qsq.last_execution_time,
    qsqt.query_sql_text
FROM sys.query_store_query qsq
    INNER JOIN sys.query_store_query_text qsqt
        ON qsq.query_text_id = qsqt.query_text_id
WHERE
    qsqt.query_sql_text LIKE '%SELECT i.AccountsPersonID, il.Description, o.OrderID
FROM Sales.Invoices i%';
--ORDER BY qsq.last_execution_time DESC	-- optional, can be used if no where clause

GO

-- Create missing index from DTA recommendation to improve Poorly Performing Query Plan
-- index recommendation 1 - From SSMS itself
DROP INDEX IF EXISTS cmpIX_BillToCustomerID_SalesInvoices ON [Sales].[Invoices];
CREATE NONCLUSTERED INDEX cmpIX_BillToCustomerID_SalesInvoices
ON [Sales].[Invoices] ([BillToCustomerID])
INCLUDE ([OrderID],[AccountsPersonID])
GO

/* 
-- Create missing index from DTA recommendation to improve Poorly Performing Query Plan
-- index recommendation 2
DROP INDEX IF EXISTS cmp2IX_InvoiceLines_SalesInvoiceLines ON [Sales].[InvoiceLines];
CREATE NONCLUSTERED INDEX cmp2IX_InvoiceLines_SalesInvoiceLines ON [Sales].[InvoiceLines]
(
	[InvoiceID] ASC
)
INCLUDE([Description]) WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [USERDATA]

GO

-- index recommendation 3
DROP INDEX IF EXISTS cmp2IX_Invoices_SalesInvoices ON [Sales].[Invoices];
CREATE NONCLUSTERED INDEX cmp2IX_Invoices_SalesInvoices ON [Sales].[Invoices]
(
	[BillToCustomerID] ASC,
	[InvoiceID] ASC,
	[OrderID] ASC
)
INCLUDE([AccountsPersonID]) WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [USERDATA]

GO

-- index recommendation 4
DROP INDEX IF EXISTS IX_Orders_SalesOrders ON [Sales].[Orders]
CREATE NONCLUSTERED INDEX IX_Orders_SalesOrders ON [Sales].[Orders]
(
	[OrderID] ASC
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [USERDATA]

GO

-- Indexe created but not as useful, so index 1 was retained; Besides SQL Server has a limited number of 600 rows indexes per instance
*/


/* -- CREATE EFFICIENT QUERY PLANS USING QUERY STORE -- */
-- Convert the database into read-only when testing improvement recommendations 
	-- in this case news stats cannot be saved
		ALTER DATABASE [SQLAuthority] -- example
		SET QUERY_STORE = ON (OPERATION_MODE = READ_ONLY);
		
-- check which Database has the Query Store Actived for tracking
SELECT name, is_query_store_on FROM sys.databases
GO


-- Use case of parameter sniffing; how to solve it
	-- how to get optimal performance from a query at all time, with all parameters
USE WideWorldImporters
GO

-- create the parameterised procedure to test with
CREATE OR ALTER PROCEDURE usp_GetAccounts (@AccountPersonID INT)
AS 
BEGIN
	SELECT [CustomerID],[BillToCustomerID],[OrderID],
			[DeliveryMethodID],[ContactPersonID]
	FROM  Sales.Invoices
	WHERE AccountsPersonID = @AccountPersonID
	ORDER BY AccountsPersonID
END
GO

DBCC FREEPROCCACHE		-- it removes all the execution plans from the procedure cache, forcing SQL Server to recompile the SQL statements the next time they are executed. DB Cache (NOT RECOMMENDED IN PRODUCTION ENV.)
GO

SET STATISTICS IO, TIME ON
GO
-- Small Account result
EXEC usp_GetAccounts 3260
GO
-- Huge Account result
EXEC usp_GetAccounts 1001
GO


DBCC FREEPROCCACHE		-- Clear procedure cache once more (NOT RECOMMENDED IN PRODUCTION ENV.)
GO
-- reverse the order to spot the execution plan cached with the paramter with the huge account result
-- Huge Account result
EXEC usp_GetAccounts 1001
GO

-- Small Account result
EXEC usp_GetAccounts 3260
GO

-- create the index to solve the parameter sniffing
CREATE NONCLUSTERED INDEX [IX_Invoices_AccountsPersonID]
ON [Sales].[Invoices] ([AccountsPersonID])
GO

CREATE NONCLUSTERED INDEX [IX_Invoices_AccountsPersonID_incl]
ON [Sales].[Invoices] ([AccountsPersonID])
INCLUDE ([CustomerID],[BillToCustomerID],
[OrderID],[DeliveryMethodID],[ContactPersonID])
GO



/* -- COMPARE ESTIMATED AND ACTUAL EXECUTION PLAN -- */
USE WideWorldImporters
GO

-- Long Query
SELECT *
FROM [Sales].[InvoiceLines] il 
INNER JOIN [Sales].[Invoices] i ON i.InvoiceID = il.InvoiceID
INNER JOIN [Sales].[OrderLines] ol ON ol.OrderID = i.OrderID
INNER JOIN [Sales].[Orders] o ON o.OrderID = ol.OrderID
GO

-- Query with Insert
CREATE TABLE #Test (ID INT)
INSERT INTO #Test (ID)
SELECT OrderID
FROM [Sales].[Orders]
GO
DROP TABLE #Test
GO

-- Activate Estimated Execution Plan
	-- ACTIVE ONLY ONE AT A TIME
	-- NOT COMPATIBLE WITH OTHER EXECUTION MODE
SET SHOWPLAN_ALL ON
SET SHOWPLAN_XML ON

SET SHOWPLAN_ALL OFF
SET SHOWPLAN_XML OFF

-- Analyse Execution Plans:
-- Long Query (save execution plan 1)
SELECT *
FROM [Sales].[InvoiceLines] il 
INNER JOIN [Sales].[Invoices] i ON i.InvoiceID = il.InvoiceID
WHERE il.StockItemID > 100
GO

-- Long Query (save execution plan 2)
SELECT *
FROM [Sales].[InvoiceLines] il 
INNER JOIN [Sales].[Invoices] i ON i.InvoiceID = il.InvoiceID
WHERE i.ConfirmedReceivedBy  = 'Alinne Matos'
GO