USE [training-test]


-- QUERY PLAN SYS FILE
select * from sys.dm_exec_cached_plans;

-- GET THE QUERY PLAN OF EACH 'VIA THEIR PLAN HANDLE'
select * from sys.dm_exec_query_plan(0x060007000A2C0312A022B0B65402000001000000000000000000000000000000000000000000000000000000);

-- GIVES THE TEXT THAT WAS USED FOR THE QUERY 
select * from sys.dm_exec_sql_text(0x060007000A2C0312A022B0B65402000001000000000000000000000000000000000000000000000000000000);

--TO CLEAR OR REBUILD CACHE AND QUERY PLANS
dbcc freeproccache


/*
-- TO VIEW: the Cached Plans, Plan Handles and Queries Plans in one

create function SqlAndPlan(@handle varbinary(max))
returns table
as
return select 
    sql.text, 
    cp.usecounts,
    cp.cacheobjtype,
    cp.objtype, 
    cp.size_in_bytes,
    qp.query_plan
 from sys.dm_exec_sql_text(@handle) as sql 
 cross join sys.dm_exec_query_plan(@handle)	as qp
 join sys.dm_exec_cached_plans as cp
 on cp.plan_handle = @handle;
 
 select * from SqlAndPlan(0x06000D007852A00B40613C82000000000000000000000000);
 
 
create view PlanCache
as
select sp.* from sys.dm_exec_cached_plans   as cp
cross apply SqlAndPlan(cp.plan_handle) as sp

select * from PlanCache

*/


-- TO RECONFIGURE THE WAY QUERY PLANS ARE CACHED, TO STORE ONLY DIFFERENT AND SKIP REDUNDANTS
sp_configure 'show advanced options', 1;  -- 1 or 0
go
RECONFIGURE
go
sp_configure 'optimize for ad hoc workloads', 0; -- 1 or 0 / Useful if most of the adhoc queries are not reused, because the Query Plan have to be used twice to be stored and considered
go
RECONFIGURE


-- TO CHECK THE PARAMETERISATION STATE OF A DATABASE: FORCED(1) OR SIMPLE(0)  // can be edited in db properties/options/miscellaneous
select Databasepropertyex ('training-test', 'IsParameterizationForced');

-- changing the parameterisation flushes the existing parameters in the PLAN  CACHE
alter database [training-test] set parameterization forced;

-- SP_EXECUTE_SQL helps manually parameterising queries; works like calling a store procedure
sp_executesql N'select * from SalesLT.Product   where ProductModelID=@pid
OPTION (optimize for (@pid=9))', N'@pid int', 6

-- PLAN GUIDE AND HINTS
-- PLAN GUIGES INFLUENCE THE WAY OPTIMIZER GO ABOUT A QUERY, 

-- PLAN GUIDE ON SQL Guide - Literal type

dbcc freeproccache; -- clear the cache


select * from dbo.CAR_Automation;
select * from dbo.Customers;
GO

-- select * from PlanCache;
-- GO

select * from dbo.CAR_Automation OPTION(FAST 9); -- HINT OPTION
select * from dbo.Customers;

GO

-- EXAMPLE OF PLAN GUIDE TO ADD A HINT TO A QUERY
exec sp_create_plan_guide
@name =N'FAST9',
@stmt = N'select * from dbo.CAR_Automation', -- there can only be ONE plan guide ENABLED AT A TIME, that matches both the @stmt and the @module_or_batch; the other one has to be disable.
@type = N'SQL',
@module_or_batch = N'select * from dbo.CAR_Automation;
select * from dbo.Customers;',
@params=null,
@hints = 'OPTION (FAST 9)';

GO

-- EXAMPLE OF PLAN GUIDE TO REMOVE A HINT TO A QUERY
exec sp_create_plan_guide
@name =N'NOFAST9',
@stmt = N'select * from dbo.CAR_Automation OPTION(FAST 9)', -- there can only be ONE plan guide ENABLED AT A TIME, that matches both the @stmt and the @module_or_batch 
@type = N'SQL',
@module_or_batch = N'select * from from dbo.CAR_Automation OPTION(FAST 9);
select * from dbo.Customers;',
@params=null,
@hints=null;

GO

-- PLAN GUIDES (can be viewed, disable, enabled, dropped)

select * from sys.plan_guides		-- to view all the plan guides stored

GO


sp_control_plan_guide				-- Disable a plan guide; also disable all the plan guide patterns parameters
@operation=  N'disable',
@name = N'FAST9'

GO


sp_control_plan_guide				-- enable a plan guide
@operation =  N'enable',
@name = N'FAST9'

GO

-- DISABLE ALL, ENABLE ALL, DROP ALL table plan
sp_control_plan_guide
@operation = N'drop all' -- <here>

GO

-- PLAN GUIDE WITH HANDLE

-- view the list of current handles
select * from sys.dm_exec_cached_plans cross apply sys.dm_exec_sql_text(plan_handle);

-- 0x0500FF7F98BE56F160219CC38502000001000000000000000000000000000000000000000000000000000000 : OBJECTYPE: View
-- 0x0600070095B3D804A0E28FA98502000001000000000000000000000000000000000000000000000000000000 : OBJECTYPE: Adhoc

exec sp_create_plan_guide_from_handle @name = N'G1', -- Create a plan guide from the OBJECTYPE above based on its handle
@plan_handle = 0x0600070095B3D804A0E28FA98502000001000000000000000000000000000000000000000000000000000000


select * from sys.plan_guides
GO

-- PLAN GUIDE ON OBJECT Guide - Object type
create procedure AllCustProd
as
select * from dbo.CAR_Automation;
select * from dbo.Customers;

GO

dbcc freeproccache;


exec AllCustProd;


--select * from PlanCache;


exec sp_create_plan_guide
@name =N'FAST9Proc',
@stmt = N'select * from dbo.Customers',
@type = N'OBJECT',
@module_or_batch = N'AllCustProd',
@params=null,
@hints = 'OPTION (FAST 9)';

GO

-- PLAN GUIDE WITH OPTIMIZE FOR
--drop procedure if exists GreaterExceptionID
create procedure GreaterExceptionID(@id int)
as
select * from dbo.Exceptions
where ExceptionID>@id
OPTION (OPTIMIZE FOR (@id = 4));

 
exec GreaterExceptionID 4;
 
 -- select * from PlanCache;
 
exec sp_create_plan_guide
@name =N'P9',
@stmt = N'select * from dbo.Exceptions where ExceptionID>@id',
@type = N'OBJECT',
@module_or_batch = N'GreaterExceptionID',
@params=null,
@hints = 'OPTION (OPTIMIZE FOR (@id = 9))';
 
GO


--PLAN GUIDE WITH TEMPLATE (use stored procedure as literal values not permitted)
-- useful for queies that we want to make the most of not using Shell Query
dbcc freeproccache;

alter database [training-test] set parameterization simple;

select * from dbo.Exceptions where ExceptionID > 10;

--select * from PlanCache;

-- declaring variable for the stored procedure
declare @s nvarchar(max); -- N'' the variable to get the normalised form of the query
declare @p nvarchar(max); -- the statement

-- creating the stored procedure for the template plan guide : sp_get_query_template
-- passing the text of the query to be normalised between the N'' : select * from dbo.Exceptions where ExceptionID > 10;
-- Variables
exec sp_get_query_template N'select * from dbo.Exceptions where ExceptionID > 10;', @s output, @p output;
select @s, @p


-- select * from dbo . Exceptions where ExceptionID > @0
-- @0 int

-- Template plan guide created following the stored procedure above
exec sp_create_plan_guide
@name =N'ParamProduct',
@module_or_batch=null,		-- ALWAYS NULL
@stmt = N'select * from SalesLT . Product where ProductID > @0',	-- normalised form of the query
@type = N'TEMPLATE',		-- type template
@hints = N'OPTION(parameterization forced)',		-- parameterisation forced or simple; THIS WHAT IS WHAT WE ARE LOOKING FOR IN THIS PLAN GUIDE: controlling SQL queries parameterisation
@params = N'@0 int';
