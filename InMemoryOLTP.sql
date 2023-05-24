/* -- MEMORY OPTIMISED TABLES -- */
SELECT @@VERSION

/*CREATE A MEMORY OPTIMISED TABLE*/
-- 1 Create the database required to host the optimised tables
CREATE DATABASE SQLAuthority		
	ON PRIMARY (					-- data file
    NAME = [SQLAuthority_data]
    ,FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\SQLAuthority.mdf' 
    )

    ,FILEGROUP [SQLAuthority_FG]		-- defining a filegroup named [SQLAuthority_FG] specifically for storing memory-optimized data 
	CONTAINS MEMORY_OPTIMIZED_DATA (
    NAME = [SQLAuthority_dir]			-- [SQLAuthority_dir] specifies the logical name of the file within the filegroup (FILESTREAM)
    ,FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\SQLAuthority_dir'
    ) 

	LOG ON (						-- log file
    NAME = [SQLAuthority_log]
    ,Filename = 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\SQLAuthority_log.ldf'
    )
GO


-- 2 Creat the required table
USE SQLAuthority
GO

-- Disk Based Table
CREATE TABLE DiskBasedTable (
    ID INT IDENTITY NOT NULL PRIMARY KEY NONCLUSTERED
    ,FName VARCHAR(20) NOT NULL
    ,LName VARCHAR(20) NOT NULL
    )
GO

-- Memory Optimize Table (Durable)
CREATE TABLE MemoryOptimizedTable (
    ID INT IDENTITY NOT NULL PRIMARY KEY NONCLUSTERED	-- Memory optimised table don't support Clustered Index on PK
    ,FName VARCHAR(20) NOT NULL
    ,LName VARCHAR(20) NOT NULL
    )
    WITH (									-- HERE: different from Disc based table
            MEMORY_OPTIMIZED = ON
            ,DURABILITY = SCHEMA_AND_DATA	-- (optional, because default)
            )								-- will still contain data even when SQL Restarted
GO


-- Non Durable Memory Optimize Table
CREATE TABLE MemoryOptimizedTableNonDurable (
    ID INT IDENTITY NOT NULL PRIMARY KEY NONCLUSTERED 
    ,FName VARCHAR(20) NOT NULL
    ,LName VARCHAR(20) NOT NULL
    )
    WITH (
            MEMORY_OPTIMIZED = ON
            ,DURABILITY = SCHEMA_ONLY		-- HERE: to make a Memory Optimized Table Non_Durable
            )								-- will not contain any data when SQL Restarted (like Temporary tables)
GO

--  Check DMV to know the Memory Tables Properties ( "Dynamic Management Views" )
SELECT	SCHEMA_NAME(Schema_id) SchemaName, 
		name TableName,
		is_memory_optimized, 
		durability_desc,
		create_date, modify_date
FROM sys.tables
GO


/*CHECK DATABE COMPATIBILITY LEVEL*/
-- 1 setup the database to the  compatbility level
CREATE DATABASE Pluralsight
	ON PRIMARY (
    NAME = [Pluralsight_data]
    ,FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\Pluralsight.mdf'
    )
  	LOG ON (
    NAME = [Pluralsight_log]
    ,Filename = 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\Pluralsight_log.ldf'
    )
GO
-- Change Compatibility Level from 120 to latest 
ALTER DATABASE Pluralsight 
SET COMPATIBILITY_LEVEL = 160	-- Memory Optimzed Table compatible from 120 +
GO								-- Alternatively go to the DB properties > Options > Compatibility Level

-- Database Name and Compatibility Level
SELECT name, compatibility_level
FROM sys.databases
WHERE name = 'Pluralsight'
GO


/*MEMORY OPTIMIZED FILEGROUP*/
-- Can be added after the Memory Optimised Database has been created
-- Add Memory Optimized FileGroup
ALTER DATABASE [Pluralsight] SET AUTO_CLOSE OFF; -- Set AUTO_CLOSE option to OFF because is not compatible with databases that have a filegroup containing memory-optimized data.
ALTER DATABASE [Pluralsight]
	ADD FILEGROUP [Pluralsight_FG] 
	CONTAINS MEMORY_OPTIMIZED_DATA
GO

-- Add File to Memory Optimized FileGroup
ALTER DATABASE [Pluralsight] ADD FILE (
    NAME = N'Pluralsight_dir'
    ,FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\Pluralsight_dir'
    ) TO FILEGROUP [Pluralsight_FG]
GO


/* SNAPSHOT ISOLATION */
-- Check current isolation level
DBCC useroptions
GO

--	Memory-optimized tables support Snapshot isolation with explicit and implicit transactions; Solution: SET MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT = ON
	--	while Read-committed isolation is supported with auto-commit transactions.
USE [Pluralsight]
GO

-- Change isolation to MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT
-- for Cross Container Transactions
ALTER DATABASE CURRENT		-- specified the DB with USE command
    SET MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT = ON
GO

-- Check isolation level
SELECT name, is_read_committed_snapshot_on, is_memory_optimized_elevate_to_snapshot_on
FROM sys.databases

-- Selects with Explicit Commit
BEGIN TRANSACTION 
SELECT *
FROM [dbo].[MemoryOptimizedTable] mt 
INNER JOIN [dbo].[DiskBasedTable] dt ON mt.ID = dt.ID
GO
COMMIT TRANSACTION
GO


/* INDEXES ON MEMORY OPTIMISED TABLES */
-- Memory Optimized Index
CREATE TABLE [MemoryOptimizedTable_I_Mem] (
    ID INT IDENTITY NOT NULL 
		PRIMARY KEY NONCLUSTERED 
    ,FName VARCHAR(20) NOT NULL
    ,LName VARCHAR(20) NOT NULL
    )
    WITH (
            MEMORY_OPTIMIZED = ON
            ,DURABILITY = SCHEMA_AND_DATA
            )
GO

-- Hash Index
CREATE TABLE [MemoryOptimizedTable_I_Hash] (
    ID INT IDENTITY NOT NULL 
		PRIMARY KEY NONCLUSTERED HASH WITH (BUCKET_COUNT = 1000000) -- should be twice the number disctinct rows to insert in the table; but too large is not good either
    ,FName VARCHAR(20) NOT NULL
    ,LName VARCHAR(20) NOT NULL
    )
    WITH (
            MEMORY_OPTIMIZED = ON
            ,DURABILITY = SCHEMA_AND_DATA
            )
GO

-- Inserting Data
INSERT INTO [MemoryOptimizedTable_I_Mem] (FName, LName)
SELECT TOP 500000  'Bob',				
					CASE WHEN ROW_NUMBER() OVER (ORDER BY a.name)%123456 = 1 THEN 'Baker' 
						 WHEN ROW_NUMBER() OVER (ORDER BY a.name)%10 = 1 THEN 'Marley' 
						WHEN  ROW_NUMBER() OVER (ORDER BY a.name)%10 = 5 THEN 'Ross' 
						WHEN  ROW_NUMBER() OVER (ORDER BY a.name)%10 = 3 THEN 'Dylan' 
					ELSE 'Hope' END
FROM sys.all_objects a
CROSS JOIN sys.all_objects b
GO

INSERT INTO [MemoryOptimizedTable_I_Hash] (FName, LName)
SELECT TOP 500000  'Bob', 					
					CASE WHEN ROW_NUMBER() OVER (ORDER BY a.name)%123456 = 1 THEN 'Baker' 
						 WHEN ROW_NUMBER() OVER (ORDER BY a.name)%10 = 1 THEN 'Marley' 
						WHEN  ROW_NUMBER() OVER (ORDER BY a.name)%10 = 5 THEN 'Ross' 
						WHEN  ROW_NUMBER() OVER (ORDER BY a.name)%10 = 3 THEN 'Dylan' 
					ELSE 'Hope' END
FROM sys.all_objects a
CROSS JOIN sys.all_objects b
GO

SET STATISTICS IO, TIME ON		-- this will confirm there is no in memory action when woking with OLTP 
-------------
-- Test 1
-- Index on Identity Only
SELECT *
FROM [MemoryOptimizedTable_I_Mem]
WHERE LName BETWEEN 'A' AND 'E'
GO

SELECT *
FROM [MemoryOptimizedTable_I_Hash]
WHERE LName BETWEEN 'A' AND 'E'
GO
---------
-- Creating Index on LName
-- Memory Optimized Index
ALTER TABLE [MemoryOptimizedTable_I_Mem]  
     ADD INDEX  IX_MOT_I_Mem  
     NONCLUSTERED (LName);  
GO

-- Hash Index
ALTER TABLE [MemoryOptimizedTable_I_Hash]  
    ADD INDEX IX_MOT_I_Hash  
    HASH (LName) WITH (BUCKET_COUNT = 128);  -- twice the number of row to insert
GO

-- Test 2, TO TEST THE VALUE RANGE when retrieving data
-- Index on LastName Only RANGE
SELECT *
FROM [MemoryOptimizedTable_I_Mem]	-- NONCLUSTERED INDEX IS BEST CHOICE
WHERE LName BETWEEN 'A' AND 'E'
GO

SELECT *
FROM [MemoryOptimizedTable_I_Hash]
WHERE LName BETWEEN 'A' AND 'E'
GO

-- Test 3, TO TEST EQUALITY PREDICATE when retrieving data
-- Index on LastName Equality
SELECT *
FROM [MemoryOptimizedTable_I_Mem]
WHERE LName = 'Baker'
GO

SELECT *
FROM [MemoryOptimizedTable_I_Hash]		-- HASH INDEX IS BEST CHOICE (lower query cost)
WHERE LName = 'Baker'
GO







/* -- NATIVE STORED PROCEDURES -- */
-- Set up - Load the Data
USE Pluralsight
GO
-- Inserting Data
INSERT INTO [dbo].[DiskBasedTable] (FName, LName)
SELECT TOP 500000  'Bob',				
					CASE WHEN ROW_NUMBER() OVER (ORDER BY a.name)%123456 = 1 THEN 'Baker' 
						 WHEN ROW_NUMBER() OVER (ORDER BY a.name)%10 = 1 THEN 'Marley' 
						WHEN  ROW_NUMBER() OVER (ORDER BY a.name)%10 = 5 THEN 'Ross' 
						WHEN  ROW_NUMBER() OVER (ORDER BY a.name)%10 = 3 THEN 'Dylan' 
					ELSE 'Hope' END
FROM sys.all_objects a
CROSS JOIN sys.all_objects b
GO

INSERT INTO [dbo].[MemoryOptimizedTable] (FName, LName)
SELECT TOP 500000  'Bob', 					
					CASE WHEN ROW_NUMBER() OVER (ORDER BY a.name)%123456 = 1 THEN 'Baker' 
						 WHEN ROW_NUMBER() OVER (ORDER BY a.name)%10 = 1 THEN 'Marley' 
						WHEN  ROW_NUMBER() OVER (ORDER BY a.name)%10 = 5 THEN 'Ross' 
						WHEN  ROW_NUMBER() OVER (ORDER BY a.name)%10 = 3 THEN 'Dylan' 
					ELSE 'Hope' END
FROM sys.all_objects a
CROSS JOIN sys.all_objects b
GO

-- Create first Native Compiled Stored Procedure
CREATE OR ALTER PROCEDURE [dbo].[NativeSP] @iID INT, @jID INT    
    WITH NATIVE_COMPILATION		-- HERE: this line must be mentionned
        ,SCHEMABINDING			-- HERE: this line must be mentionned
        ,EXECUTE AS OWNER		-- HERE: this line is Optional but works for Secrutiy measures
AS
BEGIN ATOMIC
    WITH (
            TRANSACTION ISOLATION LEVEL = SNAPSHOT		-- HERE: this line must be mentionned
			,LANGUAGE = 'us_english')					-- HERE: this line must be mentionned
	SELECT ID, FName, LName
	FROM [dbo].[MemoryOptimizedTable]
	WHERE ID >= @iID AND ID <= @jID
END
GO

SET STATISTICS IO, TIME ON
GO
-- Testing and checking the Statistics IO results to see the speed obtained by combining Natively Compiled Stored Procedure with Memory Optimised Table
-- Test 1 
EXEC [dbo].[NativeSP] 555, 555		-- fast, no logical reads, no CPU use
GO

-- Test 2
EXEC [dbo].[NativeSP] 1000, 100000
GO

-- Test 3
EXEC [dbo].[NativeSP] 1234, 4321
GO

-- Create Interpreted T-SQL Stored Procedure
CREATE OR ALTER PROCEDURE [dbo].[InterpretedSP] @iID INT, @jID INT    
AS
BEGIN 
	SELECT ID, FName, LName
	FROM [dbo].[DiskBasedTable]
	WHERE ID >= @iID AND ID <= @jID		-- OPTION(OPTIMIZE FOR UNKNOWN)
END
GO

-- Running SP
EXEC [dbo].[InterpretedSP] 555, 555		-- this gives quick and fast result but not as fast as the Natively Compiled Stored Procedures because it has logical read and CPU use
GO
EXEC [dbo].[InterpretedSP] 1000, 100000
GO
EXEC [dbo].[InterpretedSP] 1234, 4321
GO


--- EXAMPLE OF WORKAROUND OF HASH JOINS WITH NATIVELY COMPILED PROCEDURES
-- Create NativeSP
CREATE OR ALTER PROCEDURE [NativeSP-Stream]
WITH NATIVE_COMPILATION
        ,SCHEMABINDING
        ,EXECUTE AS OWNER
AS
BEGIN ATOMIC
    WITH (
            TRANSACTION ISOLATION LEVEL = SNAPSHOT
			,LANGUAGE = 'us_english')
	SELECT mot1.ID, mot1.FName, mot2.LName
	FROM [dbo].[MemoryOptimizedTable] mot1
	INNER JOIN [dbo].[MemoryOptimizedTable] mot2 ON mot1.ID = mot2.ID
END
GO

-- Create Interpreted SP
CREATE OR ALTER PROCEDURE [InterpretedSP-Hash]
AS
	SELECT mot1.ID, mot1.FName, mot2.LName
	FROM [dbo].[DiskBasedTable] mot1
	INNER JOIN [dbo].[DiskBasedTable] mot2 ON mot1.ID = mot2.ID
GO

SET STATISTICS IO, TIME ON
-- Execute SP
EXEC [NativeSP-Stream]			-- small I/O which mean it is faster
GO
EXEC [InterpretedSP-Hash]		-- Here the I/O is Higher than
GO

-- Execute SP
SET SHOWPLAN_XML ON				-- Help to see the execution of natively compiled procedures - Start with ON and close with OFF
GO
EXEC [NativeSP-Stream]
GO
SET SHOWPLAN_XML OFF			-- close
GO 
EXEC [InterpretedSP-Hash]
GO

-- To see DMV Stats
SELECT * FROM SYS.dm_exec_query_stats
SELECT * FROM SYS.dm_exec_procedure_stats

-- -----------------------------------------------------
-- Procecure Level Statisitcs Collection
-- -----------------------------------------------------
-- Current Status of Statistics Collection
DECLARE @Status BIT;
EXEC sys.sp_xtp_control_proc_exec_stats @old_collection_value=@Status output
SELECT @Status AS 'Current Status of Statistics Collection (SP Level)'
GO

-- Enable Statistics Collection for Natively Compiled SP at SP Level
EXEC sys.sp_xtp_control_proc_exec_stats @new_collection_value = 1
GO

-- Current Status of Statistics Collection
DECLARE @Status BIT;
EXEC sys.sp_xtp_control_proc_exec_stats @old_collection_value=@Status output
SELECT @Status AS 'Current Status of Statistics Collection (SP Level)'
GO

-- Azure 
ALTER DATABASE
    SCOPED CONFIGURATION
    SET XTP_PROCEDURE_EXECUTION_STATISTICS = ON
GO

-- -----------------------------------------------------
-- Query Level Statisitcs Collection
-- -----------------------------------------------------
	-- @new_collection_value / @database_id / @xtp_objec_id can also be added in the EXEC to collect those granular information
DECLARE @Status BIT;
EXEC sys.sp_xtp_control_query_exec_stats @old_collection_value=@Status output
SELECT @Status AS 'Current Status of Statistics Collection (Query Level)'
GO

-- Enable Statistics Collection for Natively Compiled SP at SP Level
EXEC sys.sp_xtp_control_query_exec_stats @new_collection_value = 1
GO

-- Current Status of Statistics Collection
DECLARE @Status BIT;
EXEC sys.sp_xtp_control_query_exec_stats @old_collection_value=@Status output
SELECT @Status AS 'Current Status of Statistics Collection (Query Level)'
GO

-- Azure 
ALTER DATABASE
    SCOPED CONFIGURATION
    SET XTP_QUERY_EXECUTION_STATISTICS = ON
GO 


-- Collecting Proc Level Statistics
SELECT  OBJECT_ID,
        OBJECT_NAME(OBJECT_ID) AS [object name],
        cached_time, last_execution_time, execution_count,
        total_worker_time, last_worker_time,
        min_worker_time, max_worker_time,
        total_elapsed_time, last_elapsed_time,
        min_elapsed_time, max_elapsed_time
FROM sys.dm_exec_procedure_stats
WHERE database_id = DB_ID() AND
        OBJECT_ID IN
            (   SELECT OBJECT_ID
                FROM sys.sql_modules
                WHERE uses_native_compilation=1)
ORDER BY total_worker_time DESC;
GO

-- Collecting Query Level Statistics
	-- this include the Query text of Native SP
SELECT st.objectid,
       OBJECT_NAME(st.objectid) AS [object name],
       SUBSTRING(st.text,
            (qs.statement_start_offset/2) + 1,
            ((qs.statement_end_offset-qs.statement_start_offset)/2) + 1
            ) AS [query text],
       qs.creation_time, qs.last_execution_time, qs.execution_count,
       qs.total_worker_time, qs.last_worker_time,
       qs.min_worker_time, qs.max_worker_time,
       qs.total_elapsed_time, qs.last_elapsed_time,
       qs.min_elapsed_time, qs.max_elapsed_time
FROM sys.dm_exec_query_stats qs
		 CROSS APPLY sys.dm_exec_sql_text(sql_handle) st
WHERE st.dbid = DB_ID() AND
        st.objectid IN
            (	SELECT OBJECT_ID
                FROM sys.sql_modules
                WHERE uses_native_compilation=1)
ORDER BY qs.total_worker_time DESC;
GO







---- CONVICE YOUR BOSS OR CLIENT  DEMO
-- ------------------------------------------------------
-- How to get started with OLTP In-Memory Table?
-- Subscribe to newsletter at https://go.sqlauthority.com 
-- Questions: pinal@sqlauthority.com 
-- ------------------------------------------------------

/*
Simple demo to showcase Memory Optimized Data with SQL Server
*/

SET STATISTICS IO ON
GO

CREATE DATABASE InMemory
ON PRIMARY(NAME = InMemoryData, 
FILENAME = 'D:\Data\InMemoryData.mdf', size=200MB), 
-- Memory Optimized Data
FILEGROUP [InMem_FG] CONTAINS MEMORY_OPTIMIZED_DATA(
NAME = [InMemory_InMem_dir], 
FILENAME = 'D:\Data\InMemory_InMem_dir') 
--
LOG ON (name = [InMem_demo_log], Filename='D:\Data\InMemory.ldf', size=100MB)
GO

USE InMemory
GO
-- Create a Simple Table
CREATE TABLE DummyTable (ID INT NOT NULL PRIMARY KEY, 
Name VARCHAR(100) NOT NULL)

-- Create a Memeory Optimized Table
CREATE TABLE DummyTable_Mem (ID INT NOT NULL, 
Name VARCHAR(100) NOT NULL
CONSTRAINT ID_Clust_DummyTable_Mem PRIMARY KEY NONCLUSTERED HASH (ID) WITH (BUCKET_COUNT=1000000))
WITH (MEMORY_OPTIMIZED=ON)
GO

-- Simple table to insert 100,000 Rows
CREATE PROCEDURE Simple_Insert_test
AS
BEGIN
SET NOCOUNT ON
DECLARE @counter AS INT = 1
DECLARE @start DATETIME
SELECT @start = GETDATE()
 
    WHILE (@counter <= 100000)
        BEGIN
            INSERT INTO DummyTable VALUES(@counter, 'SQLAuthority')
            SET @counter = @counter + 1
         END
SELECT DATEDIFF(SECOND, @start, GETDATE() ) [Simple_Insert in sec]
END
GO

-- Inserting same 100,000 rows using InMemory Table
CREATE PROCEDURE ImMemory_Insert_test
WITH NATIVE_COMPILATION, SCHEMABINDING,EXECUTE AS OWNER
AS 
BEGIN ATOMIC WITH (TRANSACTION ISOLATION LEVEL=SNAPSHOT, LANGUAGE='english')
DECLARE @counter AS INT = 1
DECLARE @start DATETIME
SELECT @start = GETDATE()
 
    WHILE (@counter <= 100000)
        BEGIN
            INSERT INTO dbo.DummyTable_Mem VALUES(@counter, 'SQLAuthority')
            SET @counter = @counter + 1
         END
SELECT DATEDIFF(SECOND, @start, GETDATE() ) [InMemory_Insert in sec]
END
GO

-- Making sure there are no rows
SELECT COUNT(*) FROM dbo.DummyTable
GO
SELECT COUNT(*) FROM dbo.DummyTable_Mem
GO

-- Running the test for Insert
EXEC Simple_Insert_test
GO
EXEC ImMemory_Insert_test
GO

-- Check if rows got inserted
SELECT COUNT(*) FROM dbo.DummyTable
GO
SELECT COUNT(*) FROM dbo.DummyTable_Mem
GO

-- Clean up
USE master
GO
ALTER DATABASE InMemory
SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DROP DATABASE InMemory
GO
