--SCHEMA AND SECURITY

USE [security principals]


select * from [security principals].sys.schemas  -- List the schema binded to this database
select * from sys.schemas

select		-- each schema has an id and can join it to the Users datanase to see their name
	s.*, 
	p.name 
from sys.schemas as s 
	join sys.database_principals as p
on s.principal_id = p.principal_id		


select user		-- to know the current user profile 

create user nologin without login

create user gorty from login [darkmatter5\gort]

-- create a user with a defaul schema, based on a Windows login
	-- if is schema does not exist, it will be created
create user klatuu from login [darkmatter5\klatuu] with default_schema = saucer

-- view all the schema for specific users
select * from sys.database_principals where name in ('gorty', 'klatuu', 'nologin')


-- change a user default schema to another one
alter user gorty with default_schema = guest


-- give the effective permissions the current user has on the object table [security principals]
	-- following the REVOCE > DENY > GRANT persmissions
select * from sys.fn_my_permissions('[security principals]', 'database')


-- Another method to impersonate a user
execute as user = 'new user'
execute as user = 'luket'

select user		--tells you who is the current user

revert			--takes you back to the previous user profile
go

-- assigning a schema to a user do not give permissions to the table inside that schema. 
	-- GRANT Permission is the way to allow the user Gorty to SELECT the table planets in the shcema dbo
		-- only the schema owner has most permissions
grant select on dbo.planets to gorty
go
-- or give authorisation rigth from the schema creation
CREATE SCHEMA dangers AUTHORIZATION DoNotDoThis

GO

-- to know the list of schema permission's for 'dangers'
select p.name, s.* from sys.schemas as s join sys.database_principals as p
on s.principal_id = p.principal_id
where s.name='dangers'

sp_help '[dbo].[CAR_Automation]'




-- GROUP AND ROLE MANAGEMENT --
select * from sys.database_role_members


sp_helpsrvrole		-- List of all the server fixed role with a brief description
sp_srvrolepermission 'sysadmin'		-- list of all the sysadmin  role
sp_srvrolepermission 'dbcreator'		-- list of all dbcreator role


--FIXED ROLES 
select * from sys.server_principals where type= 'r'	-- SERVER ROLE or SERVER GROUP OF USER is of type 'R'
select * from sys.database_principals where type= 'r'	-- DATABASE ROLE or DATABASE GROUP OF USER is of type 'R'

select * from sys.server_principals where name = 'sysadmin' -- SERVER ROLE ARE USED AS SERVER PRINCIPAL'S NAME


sp_addsrvrolemember 'domain\user', 'sysadmin' -- add the USER to the SYSADMIN GROUP with SERVER ROLE permission
sp_dropsrvrolemember 'domain\user', 'sysadmin' -- remove the USER to the SYSADMIN GROUP and revolke his SERVER ROLE permission


sp_helpdbfixedrole		-- list of all the fixed role on database level

sp_addrolemember 'db_datareader', 'domain\user'	-- add the role of DATABASE READER to USER and give him the related permissions // DB_DATAREADER can read any data in the entire database

deny select on schema::saucer to db_datareader	-- you can't DENY permission on a FIXED ROLE but rather specify as follow
deny select on schema::saucer to [darkmatter5\workerbee]	-- specify the denial always


--FLEXIBLES ROLES
select * from sys.database_role_members -- to get list of the member of

create role saucer_reader	-- create a role
grant select on schema::dbo to saucer_reader	-- grant a SELECT permission to a role on a Schema
sp_addrolemember 'db_datareader', 'saucer_reader'	-- add the role saucer_reader IN the DATABASE READER GROUP ROLE and give him the related JUST LIKE A USER

select		-- get the user and role from their individual table based on their id
	pri.name as role, 
	pri2.name as principal  
from sys.database_role_members as rm
	join sys.database_principals as pri
on pri.principal_id = rm.role_principal_id
	join sys.database_principals as pri2
on pri2.principal_id = rm.member_principal_id
--where pri2.name = 'saucer_reader'


--TIPS:		YOU CAN CREATE A GROUPE WITH DINIAL PERMISSION TO GIVE THEM A ROLE WITH RESTICTION
create role no_saucer

deny control on schema::guest to no_saucer		-- NEGATIVE PERMISSION

sp_addrolemember 'no_saucer', 'pilot'

select		-- get the user and role from their individual table based on their id
	pri.name as role, 
	pri2.name as principal  
from sys.database_role_members as rm
	join sys.database_principals as pri
on pri.principal_id = rm.role_principal_id
	join sys.database_principals as pri2
on pri2.principal_id = rm.member_principal_id



--	EXECUTION CONTEXT
execute as login = 'darkmatter5\workerbee'

revert		-- CAN ONLY REVERT EACH LEVEL OF THE STACK ONE AT A TIME // AND ONLY FROM THE CONTEXT IN WHICH THE USER WAS CREATED

execute as user = 'darkmatter5\workerbee'

-- executing a Dynamic SQL comand with owner priviledge allow an unautorised user to modify a remote db
create proc JustShootMe2 (@cmd nvarchar(max))
with execute as owner		-- owner is the procedure creator (could also be SELF, CALLER, or a specific)
as
exec sp_executesql @cmd

