create database [security principals]

use [security principals]

select * from sys.server_principals

create login DoNotDoThis with password = 'password'   -- create & save loging and password

create login nobody from windows          -- create & save user login from user list in COMPUTER MGT IN WINDOWS (require existing <domain\username>)


select * from [security principals].sys.database_principals

select * from [model].sys.database_principals       -- the repertory of models of DB, similar to sys.database_principals

create user DoNotDoThis      -- it has to match the existing login
create user ludo from login DoNotDoThis       

--0x3D49419912B2AE4C9AE88A9DE5170193 SID for DoNotDoThis login
select * from sys.server_principals where sid = 0x3D49419912B2AE4C9AE88A9DE5170193


-- OTHER QUERIES 
create user whoami without login

alter user whoami with name = noone

drop user whoami


create role myrole


--PERMISSIONS
		--   authorization, principals, objects and permissions

select * from sys.server_principals

alter login DoNotDoThis disable -- ENABLE AND DISABLE LOGINS
alter login [domain\username] enable


SELECT * FROM SYS.fn_my_permissions(NULL, 'database') -- TO KNOW THE PERMISSIONS of the current USER logged in // NULL: to know all the permissions, database is an object type; could be changed to other oject types such as server, database. 

SELECT * FROM SYS.fn_my_permissions('[training-test].[dbo].[CAR_Automation]', 'object') -- TO KNOW CURRENT USER PERMISSIONS ON THE TABLE OBJECT  [training-test].[dbo].[CAR_Automation]


grant control server to DoNotDoThis		-- TYPE OF PRIVILEDGES IN SSMS TO MANAGE MOST PERMISSIONS


create user [new user] from login DoNotDoThis	-- IMPERSONATE: create user from login and grant them herited logins from DoNotDoThis to acess its priviledges // but impersonate doesn't work with GRANT CONTROL SERVER function
setuser '[new user]' -- this command activate the impersonnation


select user [luket]	-- IMPERSONATE A DIFFERENT USER PROFILE THAT THE ONE IN CURRENT USE
setuser		-- takes you back to the initial user


--GROUPS AND ROLES

create login [Admin\DevTeam] from windows -- CREATE A LOGIN FOR AN EXISTING GROUP OF USERS PRESENTS IN COMPUTER MGT FROM WINDOWS
CREATE USER DevTeam from login [Admin\DevTeam] -- Create a GROUP as it was a user with the [Admin\DevTeam] login
GRANT SELECT ON OBJECT::[training-test].[dbo].[CAR_Automation] TO DevTeam -- GRANT SELECT PERMISSION to devTeam GROUP


select * from sys.database_principals


create role pilot		-- create a DATABE ROLE, also considered as GROUP in SSMS

sp_addrolemember 'pilot', 'luket' -- ADD the user 'luket' TO THE DATABASE ROLE/GROUP 'pilot'


grant insert on object::[training-test].[dbo].[CAR_Automation] to pilot -- GRANT insert PERMISSION to the Database role 'pilot' on the object table [CAR_Automation]


