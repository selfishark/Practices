/* -- Optimising SQL Server Instance and Memory Configuration -- */

-- A Memory settings
		-- Buffer Pool Memory Sizing 
-- Check server config to know the allocated min and max server memory
-- value_in_use is the running value of the server config option	
SELECT 
	SERVERPROPERTY('InstanceName') AS myinstance,
	*
FROM
	sys.configurations	-- to query server configurations
WHERE [name] IN
	(
		'max server memory (MB)',	-- the max allowed sized for the buffer to grow, as opposed to the min server memory
		'min server memory (MB)'	-- this prevent SQL Server to shrink below the appointed value to protect the current instance from other processes
	)
GO

-- A-1) --config for MAX SERVER MEMORY*

-- Scenario 1, the preferred scenario: ONLY ONE INSTANCE installed on the server
SELECT physical_memory_kb
FROM sys.dm_os_sys_info		--returns the total amount of physical memory (RAM) in the server - Then decide what to allocate 'Max Server Memory'

GO

sp_configure 'show advanced options', 1
GO
RECONFIGURE
GO
sp_configure 'max server memory (MB)', 12288	-- FORMULA: max server memory (MB) = physical memory (RAM) - 4GB or (-10% whichever is greater tp leave to the OS) - (memory not controlled by Max_Server_Memory)  -- (Here 16gb-4gb-0gb = 12gb) 
RECONFIGURE
GO

-- Scenario 2, Single-instance with shared Max_Server_Memory with other services that creates memory pressure
sp_configure 'show advanced options', 1
GO
RECONFIGURE
GO
sp_configure 'max server memory (MB)', 10240	-- FORMULA: max server memory (MB) = physical memory (RAM) - 4GB or (-10% whichever is greater to leave to the OS) - (memory not controlled by Max_Server_Memory) - (memory for other services sharing Max_Server_Memory)  -- (Here 16gb-4gb-2bg = 10gb)
RECONFIGURE
GO

-- Scenario 3, Multiples-instance shared environement SQL server
sp_configure 'show advanced options', 1
GO
RECONFIGURE
GO
sp_configure 'max server memory (MB)', 12000	-- FORMULA: max server memory (MB) = (physical memory (RAM) - 4GB for the OS)/n -- n being the number of instance; Each instance only gets an equal ratio of the remaining : RAM-4G OR-10% whichever is greater to
RECONFIGURE
GO


-- A-2) -- config for MIN SERVER MEMORY*

-- Scenario 1, the preferred scenario: ONLY ONE INSTANCE installed on the server
SELECT physical_memory_kb
FROM sys.dm_os_sys_info		

GO

sp_configure 'show advanced options', 1
GO
RECONFIGURE
GO
sp_configure 'min server memory (MB)', 1024	-- could depends on the usage 
RECONFIGURE
GO

-- Scenario 2, Single-instance with shared Max_Server_Memory with other services that creates memory pressure
-- Scenario 3, Multiples-instance shared environement SQL server
sp_configure 'show advanced options', 1
GO
RECONFIGURE
GO
sp_configure 'max server memory (MB)', 2048	-- could depends on the usage but the least the server can survive with.
RECONFIGURE
GO


-- A-3) -- LOCK PAGE IN MEMORY*

-- to prenvent external memory pressure, set a group policy on 'LOCK PAGE IN MEMORY' presents in the User Right Assignements
-- to be done only when the problem of memory pressure has already occur on the instance


-- A-4 -- Optimise for Adhoc Workloads
		-- this is connected to the plan cache memory in particular
SELECT *
FROM sys.configurations
WHERE [name] IN
	(
		'optimise for ad hoc workloads'
	)
GO

		-- Apply this config only when the server is full of Plan Cache that are use not often or when expriencing memory pressure problems
sp_configure 'show advanced options', 1
GO
RECONFIGURE
GO
sp_configure 'optimise for ad hoc workloads', 1	-- set 'value_in_use' from 0 to 1
RECONFIGURE
GO

-- get pan cache stats focusing on ad-hoc plan usage
SELECT objtype, cacheobjtype, 
    AVG(usecounts) AS Avg_UseCount,
    SUM(refcounts) AS AllRefObjects,
    SUM(CAST(size_in_bytes AS bigint))/1024/1024 AS SizeInMB
FROM sys.dm_exec_cached_plans
WHERE objtype = 'Adhoc' AND usecounts = 1
GROUP BY objtype, cacheobjtype;

-- OR 

-- get pan cache stats focusing on ad-hoc plan usage in MB
	-- the execution plan of those adhoc queries is partially stored until the next usage
SELECT objtype	AS [CacheType],
	COUNT_BIG(*) AS [Total Plans],
	SUM(CAST(size_in_bytes AS DECIMAL(18, 2))) / 1024 / 2014 AS [Total MBs],
	AVG(usecounts) AS [Avg Use Counts],
	SUM(CAST((CASE WHEN usecounts = 1 THEN size_in_bytes
		ELSE 0
		END) AS DECIMAL(18, 2))) / 1024 / 2014 AS [Total MBs - USE Count 1],
	SUM(CASE WHEN usecounts = 1 THEN 1
	ELSE 0
	END) AS [Total Plans - USE Count 1]
FROM sys.dm_exec_cached_plans
GROUP BY objtype
ORDER BY [Total MBs - USE Count 1] DESC
GO


-- B Parallelism settings
	-- Max Degree of Parallelism: MAXDOP
SELECT *
FROM sys.configurations
WHERE [name] IN
	(
		'max degree of parallelism'
	)
GO

	-- configure the defaul MAXDOP at instance level
sp_configure 'show advanced options', 1
GO
RECONFIGURE
GO
sp_configure 'max degree of parallelism', 4	-- set 'value' to 4 out of 8 'value_in_use' 
RECONFIGURE
GO

	-- override instance level MAXDOP with database scoped configuration in the current DB
			-- can also set the MAXDOP at query level when needed
ALTER DATABASE SCOPED CONFIGURATION SET MAXDOP = 2
GO
	-- check the current DB MAXDOP
SELECT *
FROM sys.database_scoped_configurations

GO

	-- check the list of available schedulers
SELECT *
FROM sys.dm_os_schedulers

GO

	-- set the threshold for parllelism, when facing limitation
SELECT *
FROM sys.configurations
WHERE [name] IN
	(
		'cost threshold for parallelism'	-- you can increase the default value of 5 to a higher value in case you don't want parallelism to kick in at lower query cost ranges
	)
GO

sp_configure 'show advanced options', 1
GO
RECONFIGURE
GO
sp_configure 'cost threshold for parallelism', 50	-- the value of 50 determines the cost at which SQL Server decides to use parallel execution plans for queries. Queries with a cost equal to or higher than this threshold will be eligible for parallelism.
RECONFIGURE
GO



--	C Autogrowth Settings
	-- C-1) Database File  Zero Initialisation (Volume Maintenance)

-- check if Instant File Initialization is enabled
SELECT servicename, instant_file_initialization_enabled 
FROM sys.dm_server_services
WHERE servicename like 'SQL Server (%';

-- OR
SELECT servicename, startup_type_desc, status_desc, last_startup_time, service_account, is_clustered, instant_file_initialization_enabled 
FROM sys.dm_server_services

-- OR, check if the SERVER INSTANCE is in the User or Group of Perform Volume Maintenance Task Property in the Local Security Policy 


	-- C-2) Database Filegrowth Settings
-- check the Database Filegrowth Settings for the entire instance
SELECT -- for each value of '1' in 'is_percent_growth', make sure you configure a fixed value growth
	database_id, [file_id], [type_desc], [name], physical_name, state_desc, size, max_size, growth, is_percent_growth
FROM 
	sys.master_files


-- check the Database Filegrowth Settings for a specific database
USE tempdb
GO
-- FORMULA = growth * page_size => 8192 * 8KB = 65536KB = 64MB (if Instant Filegrowth Settings is DISABLE)
-- Max Server Memory is for data file growth as log file doesn't grow.
SELECT -- for each value of '1' in 'is_percent_growth', make sure you configure a fixed value growth
	[file_id], [type_desc], [name], physical_name, state_desc, size, max_size, growth, is_percent_growth
FROM 
	sys.database_files


-- modify the Filegrowth of a Databse with fixed value (RECOMMENDED)
-- Set fixed size for a data file AND log file
ALTER DATABASE YourDatabaseName
MODIFY FILE (
    NAME = 'YourDataFileLogicalName',
    SIZE = <desired_size> -- Specify the size in MB or GB
);

-- Set fixed size for a log file
ALTER DATABASE [training-test]
MODIFY FILE (
    NAME = 'training-test_Log',
    SIZE = 13MB, -- Specify the size in MB or GB
	MAXSIZE = 14MB,
	FILEGROWTH = 0
);

ALTER DATABASE [training-test]
MODIFY FILE (
    NAME = 'training-test_Log',
    SIZE = 13MB, -- Specify the size in MB or GB
	MAXSIZE = 14MB,
	FILEGROWTH = 0
);
