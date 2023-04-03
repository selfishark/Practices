create database sql_intro

create table sql_intro
(
EmpId int primary key,
EmpName nvarchar(100),
EmpAddress varchar(150) unique,
EmpPhoneNbr nvarchar(15) default ('9999-999-999'),
EmpAge int check(EmpAge>18)
);

select * from sql_intro

insert into sql_intro (EmpId, EmpName)
Values(401, 'Jefferson')


create table Items (Item_Id int primary key, Item_Name varchar(25), Item_Price int, Item_Qty varchar(20));

insert into Items 
values
(051, 'Laptop', 3000, 4),
(072, 'Screen', 150, 2),
(081, 'Desk', 1000, 5),
(091, 'Chair', 500, 3);


create table customers (Cust_id int primary key, Cust_name varchar(25), Age int, Gender char(1), Address varchar(20), 
Item_purchased varchar(15), Price float);

insert into customers values
(101, 'Joseph', 22, 'M', 'Yaounde', 'Laptop', 3000),
(102, 'Marie', 25, 'F', 'Douala', 'Makeup', 500),
(201, 'Marc', 30, 'M', 'Bafang', 'Fridge', 1000),
(202, 'Rita', 28, 'F', 'Edea', 'Dress', 1500);

Update sql_intro		-- to update row value
	set  EmpAge='27'
	Where EmpId=601 

select * from customers

insert into customers (Cust_id, Cust_name, Gender)
Values(401, 'Jefferson', 'F')


Alter table customers
add PhoneNbr nvarchar(15)

update customers
set PhoneNbr='+44'

Delete from sql_intro
where Cust_id=101

Select * from customers
where Cust_id=202

Truncate table customers

Drop table customers

update customers
set Age=29
where Cust_id=401

update customers
set Address='TBC'
where Item_purchased IS NULL

-- some DQL example

Select format (BirthDate, 'mm-dd-yyyy') -- fetch data with the following format. 
	from [dbo].[DimCustomer]
	where YearlyIncome=80000 and Gender='M' and TotalChildren=1 and BirthDate >= '1970-01-01'
	
Select top 10 *                        -- fetch the top 10 records to oversee the type of information contained in the DB
	From [dbo].[DimCustomer]	
	
Select distinct JobTitle               -- find the distinct value of job title contained in the datatable DimCustomer
	from [dbo].[DimCustomer]
	
Select * 
	From [dbo].[DimCustomer]           -- sort Date of Birth in the datatable, in ascending or descending order
	Order by BirthDate asc, Gender     -- or des (ascending is the default value, if order type not defined.)


Select [EmailAddress],
		Substring ([EmailAddress] ,1,4) as shortemail -- extract from the full email the fisrt 4 charcter from charchater 1 and put in a new colum with Alias name 'shortemail'
		len ([EmailAddress]) lenghtemail, 	-- count the length of the value in EmailAddress
		UPPER ([EmailAddress]) 				-- convert the value in EmailAddress in capital letters
		firstname + ISNULL('middlename', '-') +lastname -- concatains firstname, lastname and replace middlename with a character '-' if column value is null
		

Charindex ('@', EmailAddress, 1) Indx  		-- From position 1, find the character @ in EmailAddress and return the result in the alias column 'Indx'

Select *
	From [dbo].[DimCustomer] Cust
	Where EducationLevel like 'B%'  		-- retrieve all the result of EducationLevel starting by 'B'; %B% retrieve any result between 'B'
	
 Select * 
	From [dbo].[DimCustomer]
	Where EnglishEducation in ( 			-- create a sub-query; basic sub-query uses only one table, for instance EnglishEducation. 
									select disctinct EnglishEducation from [dbo].[DimCustomer] -- subquery plays the role of filter
									where EnglishEducation='Professional'						-- here the result is unexpected 
								)
								
-- Join Table sample section
Select cus.FirstName, Address from
	[dbo].[DimCustomer] txt
	left join [dbo].[DimCustomer] cus
	on txt.CustomerKey = cus.CustomerKey
	
	where txt.OrderDate between '2022-01-01' and '2025-12-31'
	
-- operators : UNION, INTERSECT, EXCEPT
Select * from [dbo].[DimCustomer] A
	UNION 								-- merges records from both tables without duplicates
Select * from [dbo].[DimClient] A

Select * from [dbo].[DimCustomer] A
	INTERSECT							-- return the records common to both tables
Select * from [dbo].[DimClient] A

Select * from [dbo].[DimCustomer] A
	EXCEPTION							-- removes records occurence from both tables
Select * from [dbo].[DimClient] A


-- CTO : Common table Expression

WITH temp_prod							-- 'WITH' goes along with 'SELECT'; and the select expression can be extended
AS
(
select 'biscuit' prod
UNION
select 'chocolate'
)

SELECT mstr_table.Cust_id, mstr_table.Cust_name, trsct_table.EmpAddress 
	from customers mstr_table	
	left join sql_intro trsct_table							-- A join table based on the EmpAdrress of transaction table Sql_intro, missing values are NULL
	on mstr_table.Cust_id = trsct_table.EmpId, 

Where Address in ('','' select Prod from Temp_prod)


-- Temp TABLE			-- can be dropped once purpose is met
# LOCAL TEMPORARY 		-- for temporary results sauvegarde, local
## GLOBAL TEMPORARY		-- for temporary results sauvegarde, GLOBALLY

Create table #temp_prod
(
id int,
prod VARCHAR(20)
)


Create table ##global_temp_prod
(
id int,
prod VARCHAR(20)
)

-- Triggers example
Create Trigger TR_Audit_Employees ON dbo.Employees
	For INSERT, UPDATE, DELETE
AS 
	Declare @Login_name varchar(128)
	
	SELECT 	@Login_name = Login_name
	FROM	sys.dm_exec_sessions
	WHERE	session_id = @@SPID
	
	IF EXIST ( SELECT 0 FROM Deleted)
		BEGIN
			If EXISTS(select 0 from Inserted)
				BEGIN
					INSERT INTO dbo.EmployeeAudit
							( EmployeeId,
							  EmployeeName,
							  EmployeeAddress,
							  MonthlySalary,
							  ModifiedBy,
							  ModfiedDate,
							  Operation
							)
							SELECT	D.EmployeeID,
									D.EmployeeId,
									D.EmployeeName,
									D.EmployeeAddress,
									D.MonthlySalary,
									@Loging_name,
									GETDATE(),
									'U'
							from	Deleted D
				END
			ELSE
				BEGIN
					INSERT INTO dbo.EmployeeAudit
							( EmployeeId,
							  EmployeeName,
							  EmployeeAddress,
							  MonthlySalary,
							  ModifiedBy,
							  ModfiedDate,
							  Operation
							)
							SELECT	D.EmployeeID,
									D.EmployeeId,
									D.EmployeeName,
									D.EmployeeAddress,
									D.MonthlySalary,
									@Loging_name,
									GETDATE(),
									'I'
							from	Inserted I
				END
		END	
		
		

-- Cursors

DECLARE @name VARCHAR(50) -- database name
DECLARE @path varchar(256) -- path for backup files
DECLARE @fileName VARCHAR(256) -- filename for BACKUP
DECLARE @fileDate VARCHAR(20) -- used for file name

SET @path ='C:\BACKUP'

select @fileDate = CONVERT (VARCHAR(20), GETDATE(),112)

DECLARE db_cursor CURSOR FOR
SELECT name
from MASTER.dbo.sysdatabases
WHERE name NOT IN ('master', 'model', 'msdb', 'tempdb')

open db_cursor
fetch next from db_cursor INTO @name

WHILE @@FETCH_STATUS = 0
BEGIN 
		set @filename = @path + @name + '_' + @fileDate + '.BAK'
		BACKUP DATABASE @name TO DISK = @filename
		
		Fetch next from db_cursor INTO @NAME
END
