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

--  Check DMV to know the Memory Tables Properties
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
