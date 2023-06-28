/* -- SQL SERVER TROUBLESHOOTING TOOLS -- */

-- A -- WAIT STATISTICS
/*	-- https://www.sqlskills.com/blogs/paul/wait-statistics-or-please-tell-me-where-it-hurts/
	One of the most under-utilized performance troubleshooting methodologies in the SQL Server world is one called “waits and queues” (also known as “SQL Server wait statistics” or simply “wait stats”). The basic premise is that SQL Server is permanently tracking why execution threads have to wait. You can ask SQL Server for this information and then use the results to narrow down where to start digging to unearth the cause of performance issues. The “waits” are what SQL Server tracks. The “queues” are the resources that the threads are waiting for. There are a myriad of waits in the system and they all indicate different resources being waited for. For example, a PAGEIOLATCH_EX wait means a thread is waiting for a data page to be read into the buffer pool from disk. An LCK_M_X wait means a thread is waiting to be granted an exclusive lock on something
 */


-- Wait Statistics performance object contains performance counters that report information about broad categorizations of waits.
SELECT * FROM sys.dm_os_performance_counters
WHERE object_name LIKE '%Wait Statistics%';

-- Reset the aggregated statistics
DBCC SQLPERF ('sys.dm_os_wait_stats', CLEAR);


-- SQL Server for the cumulative wait statistics using the sys.dm_os_wait_stats
	-- On AZURE SQL DATABASE – you need to REPLACE sys.dm_os_wait_stats WITH SYS.DM_DB_WAIT_STATS
	-- This will show the waits grouped together as a percentage of all waits on the system, in decreasing order. The waits to be concerned about (potentially) are those at the top of the list as this represents the majority of where SQL Server is spending it’s time waiting.
-- Last updated October 1, 2021 
WITH [Waits] AS
    (SELECT
        [wait_type],
        [wait_time_ms] / 1000.0 AS [WaitS],
        ([wait_time_ms] - [signal_wait_time_ms]) / 1000.0 AS [ResourceS],
        [signal_wait_time_ms] / 1000.0 AS [SignalS],
        [waiting_tasks_count] AS [WaitCount],
        100.0 * [wait_time_ms] / SUM ([wait_time_ms]) OVER() AS [Percentage],
        ROW_NUMBER() OVER(ORDER BY [wait_time_ms] DESC) AS [RowNum]
    FROM sys.dm_os_wait_stats		-- On AZURE SQL DATABASE – you need to REPLACE sys.dm_os_wait_stats WITH SYS.DM_DB_WAIT_STATS
    WHERE [wait_type] NOT IN (
        -- These wait types are almost 100% never a problem and so they are
        -- filtered out to avoid them skewing the results. Click on the URL
        -- for more information.
        N'BROKER_EVENTHANDLER', -- https://www.sqlskills.com/help/waits/BROKER_EVENTHANDLER
        N'BROKER_RECEIVE_WAITFOR', -- https://www.sqlskills.com/help/waits/BROKER_RECEIVE_WAITFOR
        N'BROKER_TASK_STOP', -- https://www.sqlskills.com/help/waits/BROKER_TASK_STOP
        N'BROKER_TO_FLUSH', -- https://www.sqlskills.com/help/waits/BROKER_TO_FLUSH
        N'BROKER_TRANSMITTER', -- https://www.sqlskills.com/help/waits/BROKER_TRANSMITTER
        N'CHECKPOINT_QUEUE', -- https://www.sqlskills.com/help/waits/CHECKPOINT_QUEUE
        N'CHKPT', -- https://www.sqlskills.com/help/waits/CHKPT
        N'CLR_AUTO_EVENT', -- https://www.sqlskills.com/help/waits/CLR_AUTO_EVENT
        N'CLR_MANUAL_EVENT', -- https://www.sqlskills.com/help/waits/CLR_MANUAL_EVENT
        N'CLR_SEMAPHORE', -- https://www.sqlskills.com/help/waits/CLR_SEMAPHORE
 
        -- Maybe comment this out if you have parallelism issues
        N'CXCONSUMER', -- https://www.sqlskills.com/help/waits/CXCONSUMER
 
        -- Maybe comment these four out if you have mirroring issues
        N'DBMIRROR_DBM_EVENT', -- https://www.sqlskills.com/help/waits/DBMIRROR_DBM_EVENT
        N'DBMIRROR_EVENTS_QUEUE', -- https://www.sqlskills.com/help/waits/DBMIRROR_EVENTS_QUEUE
        N'DBMIRROR_WORKER_QUEUE', -- https://www.sqlskills.com/help/waits/DBMIRROR_WORKER_QUEUE
        N'DBMIRRORING_CMD', -- https://www.sqlskills.com/help/waits/DBMIRRORING_CMD
        N'DIRTY_PAGE_POLL', -- https://www.sqlskills.com/help/waits/DIRTY_PAGE_POLL
        N'DISPATCHER_QUEUE_SEMAPHORE', -- https://www.sqlskills.com/help/waits/DISPATCHER_QUEUE_SEMAPHORE
        N'EXECSYNC', -- https://www.sqlskills.com/help/waits/EXECSYNC
        N'FSAGENT', -- https://www.sqlskills.com/help/waits/FSAGENT
        N'FT_IFTS_SCHEDULER_IDLE_WAIT', -- https://www.sqlskills.com/help/waits/FT_IFTS_SCHEDULER_IDLE_WAIT
        N'FT_IFTSHC_MUTEX', -- https://www.sqlskills.com/help/waits/FT_IFTSHC_MUTEX
  
       -- Maybe comment these six out if you have AG issues
        N'HADR_CLUSAPI_CALL', -- https://www.sqlskills.com/help/waits/HADR_CLUSAPI_CALL
        N'HADR_FILESTREAM_IOMGR_IOCOMPLETION', -- https://www.sqlskills.com/help/waits/HADR_FILESTREAM_IOMGR_IOCOMPLETION
        N'HADR_LOGCAPTURE_WAIT', -- https://www.sqlskills.com/help/waits/HADR_LOGCAPTURE_WAIT
        N'HADR_NOTIFICATION_DEQUEUE', -- https://www.sqlskills.com/help/waits/HADR_NOTIFICATION_DEQUEUE
        N'HADR_TIMER_TASK', -- https://www.sqlskills.com/help/waits/HADR_TIMER_TASK
        N'HADR_WORK_QUEUE', -- https://www.sqlskills.com/help/waits/HADR_WORK_QUEUE
 
        N'KSOURCE_WAKEUP', -- https://www.sqlskills.com/help/waits/KSOURCE_WAKEUP
        N'LAZYWRITER_SLEEP', -- https://www.sqlskills.com/help/waits/LAZYWRITER_SLEEP
        N'LOGMGR_QUEUE', -- https://www.sqlskills.com/help/waits/LOGMGR_QUEUE
        N'MEMORY_ALLOCATION_EXT', -- https://www.sqlskills.com/help/waits/MEMORY_ALLOCATION_EXT
        N'ONDEMAND_TASK_QUEUE', -- https://www.sqlskills.com/help/waits/ONDEMAND_TASK_QUEUE
        N'PARALLEL_REDO_DRAIN_WORKER', -- https://www.sqlskills.com/help/waits/PARALLEL_REDO_DRAIN_WORKER
        N'PARALLEL_REDO_LOG_CACHE', -- https://www.sqlskills.com/help/waits/PARALLEL_REDO_LOG_CACHE
        N'PARALLEL_REDO_TRAN_LIST', -- https://www.sqlskills.com/help/waits/PARALLEL_REDO_TRAN_LIST
        N'PARALLEL_REDO_WORKER_SYNC', -- https://www.sqlskills.com/help/waits/PARALLEL_REDO_WORKER_SYNC
        N'PARALLEL_REDO_WORKER_WAIT_WORK', -- https://www.sqlskills.com/help/waits/PARALLEL_REDO_WORKER_WAIT_WORK
        N'PREEMPTIVE_OS_FLUSHFILEBUFFERS', -- https://www.sqlskills.com/help/waits/PREEMPTIVE_OS_FLUSHFILEBUFFERS
        N'PREEMPTIVE_XE_GETTARGETSTATE', -- https://www.sqlskills.com/help/waits/PREEMPTIVE_XE_GETTARGETSTATE
        N'PVS_PREALLOCATE', -- https://www.sqlskills.com/help/waits/PVS_PREALLOCATE
        N'PWAIT_ALL_COMPONENTS_INITIALIZED', -- https://www.sqlskills.com/help/waits/PWAIT_ALL_COMPONENTS_INITIALIZED
        N'PWAIT_DIRECTLOGCONSUMER_GETNEXT', -- https://www.sqlskills.com/help/waits/PWAIT_DIRECTLOGCONSUMER_GETNEXT
        N'PWAIT_EXTENSIBILITY_CLEANUP_TASK', -- https://www.sqlskills.com/help/waits/PWAIT_EXTENSIBILITY_CLEANUP_TASK
        N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP', -- https://www.sqlskills.com/help/waits/QDS_PERSIST_TASK_MAIN_LOOP_SLEEP
        N'QDS_ASYNC_QUEUE', -- https://www.sqlskills.com/help/waits/QDS_ASYNC_QUEUE
        N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP',
            -- https://www.sqlskills.com/help/waits/QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP
        N'QDS_SHUTDOWN_QUEUE', -- https://www.sqlskills.com/help/waits/QDS_SHUTDOWN_QUEUE
        N'REDO_THREAD_PENDING_WORK', -- https://www.sqlskills.com/help/waits/REDO_THREAD_PENDING_WORK
        N'REQUEST_FOR_DEADLOCK_SEARCH', -- https://www.sqlskills.com/help/waits/REQUEST_FOR_DEADLOCK_SEARCH
        N'RESOURCE_QUEUE', -- https://www.sqlskills.com/help/waits/RESOURCE_QUEUE
        N'SERVER_IDLE_CHECK', -- https://www.sqlskills.com/help/waits/SERVER_IDLE_CHECK
        N'SLEEP_BPOOL_FLUSH', -- https://www.sqlskills.com/help/waits/SLEEP_BPOOL_FLUSH
        N'SLEEP_DBSTARTUP', -- https://www.sqlskills.com/help/waits/SLEEP_DBSTARTUP
        N'SLEEP_DCOMSTARTUP', -- https://www.sqlskills.com/help/waits/SLEEP_DCOMSTARTUP
        N'SLEEP_MASTERDBREADY', -- https://www.sqlskills.com/help/waits/SLEEP_MASTERDBREADY
        N'SLEEP_MASTERMDREADY', -- https://www.sqlskills.com/help/waits/SLEEP_MASTERMDREADY
        N'SLEEP_MASTERUPGRADED', -- https://www.sqlskills.com/help/waits/SLEEP_MASTERUPGRADED
        N'SLEEP_MSDBSTARTUP', -- https://www.sqlskills.com/help/waits/SLEEP_MSDBSTARTUP
        N'SLEEP_SYSTEMTASK', -- https://www.sqlskills.com/help/waits/SLEEP_SYSTEMTASK
        N'SLEEP_TASK', -- https://www.sqlskills.com/help/waits/SLEEP_TASK
        N'SLEEP_TEMPDBSTARTUP', -- https://www.sqlskills.com/help/waits/SLEEP_TEMPDBSTARTUP
        N'SNI_HTTP_ACCEPT', -- https://www.sqlskills.com/help/waits/SNI_HTTP_ACCEPT
        N'SOS_WORK_DISPATCHER', -- https://www.sqlskills.com/help/waits/SOS_WORK_DISPATCHER
        N'SP_SERVER_DIAGNOSTICS_SLEEP', -- https://www.sqlskills.com/help/waits/SP_SERVER_DIAGNOSTICS_SLEEP
        N'SQLTRACE_BUFFER_FLUSH', -- https://www.sqlskills.com/help/waits/SQLTRACE_BUFFER_FLUSH
        N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP', -- https://www.sqlskills.com/help/waits/SQLTRACE_INCREMENTAL_FLUSH_SLEEP
        N'SQLTRACE_WAIT_ENTRIES', -- https://www.sqlskills.com/help/waits/SQLTRACE_WAIT_ENTRIES
        N'VDI_CLIENT_OTHER', -- https://www.sqlskills.com/help/waits/VDI_CLIENT_OTHER
        N'WAIT_FOR_RESULTS', -- https://www.sqlskills.com/help/waits/WAIT_FOR_RESULTS
        N'WAITFOR', -- https://www.sqlskills.com/help/waits/WAITFOR
        N'WAITFOR_TASKSHUTDOWN', -- https://www.sqlskills.com/help/waits/WAITFOR_TASKSHUTDOWN
        N'WAIT_XTP_RECOVERY', -- https://www.sqlskills.com/help/waits/WAIT_XTP_RECOVERY
        N'WAIT_XTP_HOST_WAIT', -- https://www.sqlskills.com/help/waits/WAIT_XTP_HOST_WAIT
        N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG', -- https://www.sqlskills.com/help/waits/WAIT_XTP_OFFLINE_CKPT_NEW_LOG
        N'WAIT_XTP_CKPT_CLOSE', -- https://www.sqlskills.com/help/waits/WAIT_XTP_CKPT_CLOSE
        N'XE_DISPATCHER_JOIN', -- https://www.sqlskills.com/help/waits/XE_DISPATCHER_JOIN
        N'XE_DISPATCHER_WAIT', -- https://www.sqlskills.com/help/waits/XE_DISPATCHER_WAIT
        N'XE_TIMER_EVENT' -- https://www.sqlskills.com/help/waits/XE_TIMER_EVENT
        )
    AND [waiting_tasks_count] > 0
    )
SELECT
    MAX ([W1].[wait_type]) AS [WaitType],
    CAST (MAX ([W1].[WaitS]) AS DECIMAL (16,2)) AS [Wait_S],
    CAST (MAX ([W1].[ResourceS]) AS DECIMAL (16,2)) AS [Resource_S],
    CAST (MAX ([W1].[SignalS]) AS DECIMAL (16,2)) AS [Signal_S],
    MAX ([W1].[WaitCount]) AS [WaitCount],
    CAST (MAX ([W1].[Percentage]) AS DECIMAL (5,2)) AS [Percentage],
    CAST ((MAX ([W1].[WaitS]) / MAX ([W1].[WaitCount])) AS DECIMAL (16,4)) AS [AvgWait_S],
    CAST ((MAX ([W1].[ResourceS]) / MAX ([W1].[WaitCount])) AS DECIMAL (16,4)) AS [AvgRes_S],
    CAST ((MAX ([W1].[SignalS]) / MAX ([W1].[WaitCount])) AS DECIMAL (16,4)) AS [AvgSig_S],
    CAST ('https://www.sqlskills.com/help/waits/' + MAX ([W1].[wait_type]) as XML) AS [Help/Info URL]
FROM [Waits] AS [W1]
INNER JOIN [Waits] AS [W2] ON [W2].[RowNum] <= [W1].[RowNum]
GROUP BY [W1].[RowNum]
HAVING SUM ([W2].[Percentage]) - MAX( [W1].[Percentage] ) < 95; -- percentage threshold

GO


-- B -- DMV (Dynamic Management Views)
/*	-- https://www.sqlskills.com/blogs/paul/how-to-examine-io-subsystem-latencies-from-within-sql-server/
	-- the major factor in server performance is its ability to perform I/O operations quickly.
	-- If you find that I/O latency has increased, look to a change in SQL Server behavior before blaming the I/O subsystem.
	-- Using performance counters, you can see at the physical disk level what the latencies are (looking at the Avg. Disk sec/Read and Avg. Disk sec/Write counters) but if you have your databases spread across a few LUNs, that doesn’t help you pinpointing which database files are experiencing latency issues and driving the most I/Os to the I/O subsystem.
	-- This is where sys.dm_io_virtual_file_stats comes in.
*/
-- B-1) WHICH DATABASE FILES ARE EXPERIENCING LATENCY ISSUES AND DRIVING THE MOST I/OS TO THE I/O SUBSYSTEM.
	-- Viewing Aggregate Information
		-- It allows me to filter on read or write latencies and it joins with sys.master_files to get database names and file paths.
		-- Beware: This information is the aggregate of all I/Os performed since the database was brought online, so the I/O times reported by the script are averages. The longer the time the data set covers, the more likely that transient latency spikes will be masked. The best way to use this data for analysis is to periodically capture snapshots of the sys.dm_db_io_virtual_file stats data and then examine the averages over that small time period. That way you’ll be able to see latency spikes.
-- last updated 2011
SELECT
    [ReadLatency] =
        CASE WHEN [num_of_reads] = 0
            THEN 0 ELSE ([io_stall_read_ms] / [num_of_reads]) END,
    [WriteLatency] =
        CASE WHEN [num_of_writes] = 0
            THEN 0 ELSE ([io_stall_write_ms] / [num_of_writes]) END,
    [Latency] =
        CASE WHEN ([num_of_reads] = 0 AND [num_of_writes] = 0)
            THEN 0 ELSE ([io_stall] / ([num_of_reads] + [num_of_writes])) END,
    [AvgBPerRead] =
        CASE WHEN [num_of_reads] = 0
            THEN 0 ELSE ([num_of_bytes_read] / [num_of_reads]) END,
    [AvgBPerWrite] =
        CASE WHEN [num_of_writes] = 0
            THEN 0 ELSE ([num_of_bytes_written] / [num_of_writes]) END,
    [AvgBPerTransfer] =
        CASE WHEN ([num_of_reads] = 0 AND [num_of_writes] = 0)
            THEN 0 ELSE
                (([num_of_bytes_read] + [num_of_bytes_written]) /
                ([num_of_reads] + [num_of_writes])) END,
    LEFT ([mf].[physical_name], 2) AS [Drive],
    DB_NAME ([vfs].[database_id]) AS [DB],
    [mf].[physical_name]
FROM
    sys.dm_io_virtual_file_stats (NULL,NULL) AS [vfs]	-- sys.master_files AS [mf] ; to see from the entire db
JOIN sys.master_files AS [mf]
    ON [vfs].[database_id] = [mf].[database_id]
    AND [vfs].[file_id] = [mf].[file_id]
-- WHERE [vfs].[file_id] = 2 -- log files
-- ORDER BY [Latency] DESC
-- ORDER BY [ReadLatency] DESC
ORDER BY [WriteLatency] DESC;

GO


-- B-2) CAPTURING IO LATENCIES FOR A PERIOD OF TIME
-- https://www.sqlskills.com/blogs/paul/capturing-io-latencies-period-time/
-- Use this data to periodically analysis snapshots captures of the sys.dm_db_io_virtual_file stats data and then examine the averages over that small time period. That way you’ll be able to see latency spikes.
-- last updated 2014
/*============================================================================
  File:     ShortPeriodIOLatencies.sql
 
  Summary:  Short snapshot of I/O latencies
 
  SQL Server Versions: 2005 onwards
------------------------------------------------------------------------------
  Written by Paul S. Randal, SQLskills.com
 
  (c) 2014, SQLskills.com. All rights reserved.
 
  For more scripts and sample code, check out http://www.SQLskills.com
 
  You may alter this code for your own *non-commercial* purposes (e.g. in a
  for-sale commercial tool). Use in your own environment is encouraged.
  You may republish altered code as long as you include this copyright and
  give due credit, but you must obtain prior permission before blogging
  this code.
 
  THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF
  ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED
  TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
  PARTICULAR PURPOSE.
============================================================================*/
  
 
IF EXISTS (SELECT * FROM [tempdb].[sys].[objects]
    WHERE [name] = N'##SQLskillsStats1')
    DROP TABLE [##SQLskillsStats1];
 
IF EXISTS (SELECT * FROM [tempdb].[sys].[objects]
    WHERE [name] = N'##SQLskillsStats2')
    DROP TABLE [##SQLskillsStats2];
GO
 
SELECT [database_id], [file_id], [num_of_reads], [io_stall_read_ms],
       [num_of_writes], [io_stall_write_ms], [io_stall],
       [num_of_bytes_read], [num_of_bytes_written], [file_handle]
INTO ##SQLskillsStats1
FROM sys.dm_io_virtual_file_stats (NULL, NULL);
GO
 
WAITFOR DELAY '00:30:00';
GO
 
SELECT [database_id], [file_id], [num_of_reads], [io_stall_read_ms],
       [num_of_writes], [io_stall_write_ms], [io_stall],
       [num_of_bytes_read], [num_of_bytes_written], [file_handle]
INTO ##SQLskillsStats2
FROM sys.dm_io_virtual_file_stats (NULL, NULL);
GO
 
WITH [DiffLatencies] AS
(SELECT
-- Files that weren't in the first snapshot
        [ts2].[database_id],
        [ts2].[file_id],
        [ts2].[num_of_reads],
        [ts2].[io_stall_read_ms],
        [ts2].[num_of_writes],
        [ts2].[io_stall_write_ms],
        [ts2].[io_stall],
        [ts2].[num_of_bytes_read],
        [ts2].[num_of_bytes_written]
    FROM [##SQLskillsStats2] AS [ts2]
    LEFT OUTER JOIN [##SQLskillsStats1] AS [ts1]
        ON [ts2].[file_handle] = [ts1].[file_handle]
    WHERE [ts1].[file_handle] IS NULL
UNION
SELECT
-- Diff of latencies in both snapshots
        [ts2].[database_id],
        [ts2].[file_id],
        [ts2].[num_of_reads] - [ts1].[num_of_reads] AS [num_of_reads],
        [ts2].[io_stall_read_ms] - [ts1].[io_stall_read_ms] AS [io_stall_read_ms],
        [ts2].[num_of_writes] - [ts1].[num_of_writes] AS [num_of_writes],
        [ts2].[io_stall_write_ms] - [ts1].[io_stall_write_ms] AS [io_stall_write_ms],
        [ts2].[io_stall] - [ts1].[io_stall] AS [io_stall],
        [ts2].[num_of_bytes_read] - [ts1].[num_of_bytes_read] AS [num_of_bytes_read],
        [ts2].[num_of_bytes_written] - [ts1].[num_of_bytes_written] AS [num_of_bytes_written]
    FROM [##SQLskillsStats2] AS [ts2]
    LEFT OUTER JOIN [##SQLskillsStats1] AS [ts1]
        ON [ts2].[file_handle] = [ts1].[file_handle]
    WHERE [ts1].[file_handle] IS NOT NULL)
SELECT
    DB_NAME ([vfs].[database_id]) AS [DB],
    LEFT ([mf].[physical_name], 2) AS [Drive],
    [mf].[type_desc],
    [num_of_reads] AS [Reads],
    [num_of_writes] AS [Writes],
    [ReadLatency(ms)] =
        CASE WHEN [num_of_reads] = 0
            THEN 0 ELSE ([io_stall_read_ms] / [num_of_reads]) END,
    [WriteLatency(ms)] =
        CASE WHEN [num_of_writes] = 0
            THEN 0 ELSE ([io_stall_write_ms] / [num_of_writes]) END,
    -- [Latency] =
        -- CASE WHEN ([num_of_reads] = 0 AND [num_of_writes] = 0)
            -- THEN 0 ELSE ([io_stall] / ([num_of_reads] + [num_of_writes])) END,
    [AvgBPerRead] =
        CASE WHEN [num_of_reads] = 0
            THEN 0 ELSE ([num_of_bytes_read] / [num_of_reads]) END,
    [AvgBPerWrite] =
        CASE WHEN [num_of_writes] = 0
            THEN 0 ELSE ([num_of_bytes_written] / [num_of_writes]) END,
    -- [AvgBPerTransfer] =
        -- CASE WHEN ([num_of_reads] = 0 AND [num_of_writes] = 0)
            -- THEN 0 ELSE
                -- (([num_of_bytes_read] + [num_of_bytes_written]) /
                -- ([num_of_reads] + [num_of_writes])) END,
    [mf].[physical_name]
FROM [DiffLatencies] AS [vfs]
JOIN sys.master_files AS [mf]
    ON [vfs].[database_id] = [mf].[database_id]
    AND [vfs].[file_id] = [mf].[file_id]
-- ORDER BY [ReadLatency(ms)] DESC
ORDER BY [WriteLatency(ms)] DESC;
GO
 
-- Cleanup
IF EXISTS (SELECT * FROM [tempdb].[sys].[objects]
    WHERE [name] = N'##SQLskillsStats1')
    DROP TABLE [##SQLskillsStats1];
 
IF EXISTS (SELECT * FROM [tempdb].[sys].[objects]
    WHERE [name] = N'##SQLskillsStats2')
    DROP TABLE [##SQLskillsStats2];
GO




-- C -- QUERY STORE

------------------------

-- D -- System_Health Session Trace
 exec sp_server_diagnostics
 GO

-- E -- Performance Monitor Counters
 
 SELECT * FROM sys.dm_os_performance_counters
 WHERE counter_name LIKE N'page life%'	-- filter for page life expectancy

 GO

/* FURTHER CONFIGURATION*/

-- for Configuring In-memory Tempdb Metadata
ALTER SERVER CONFIGURATION SET MEMORY_OPTIMIZED
TEMPDB_METADATA = ON;	-- turn it on depending on your workload

SELECT SERVERPROPERTY('IsTempdbMetadataMemoryOptimized');

-- Custom Capture Policy for Query Store
	-- QUERY_CAPTURE_MODE, when set to 'CUSTOM', it captures custom Query Store policies uptimisation
	-- QUERY_CAPTURE_POLICY, made to set the custom capture policy

ALTER DATABASE [WideWorldImporters] SET QUERY_STORE = ON
(
	OPERATION_MODE = READ_WRITE,
	QUERY_CAPTURE_MODE = CUSTOM,
	QUERY_CAPTURE_POLICY = (
		STALE_CAPTURE_POLICY_THRESHOLD = 24 HOURS,
		EXECUTION_COUNT = 30,
		TOTAL_COMPILE_CPU_TIME_MS = 1000,
		TOTAL_EXECUTION_CPU_TIME_MS = 100)
);
GO
 
-- ACCELERATED DATABASE RECOVERY SETTING
	-- it is disable by default for on-premises installation
ALTER DATABASE [WideWorldImporters]
SET ACCELERATED_DATABASE_RECOVERY = ON;

SELECT [name], is_accelerated_database_recovery_on
FROM sys.databases
GO

-- OPTIMISE FOR SEQUENTIAL KEY
	-- to avoid bottleneck call LAST PAGE HOTSPOT or LAST PAGE (PAGELATCH_EX contention)
USE Pluralsight
GO

CREATE TABLE dbo.Cities(
	CityId INT NOT NULL,
	CityName NVARCHAR (50) NOT NULL,
	CONSTRAINT PK_Cities
		PRIMARY KEY CLUSTERED (CityId ASC)
	WITH (OPTIMIZE_FOR_SEQUENTIAL_KEY = ON) -- and optimise information retrieval on index keys
);