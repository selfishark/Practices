Create table UIDemo_Input
(
Id int primary key, identity (1,1) not null, -- identity auto increment the primary key
CashIn varchar (15) null, -- null avoid recording empty row
OnUsCheck varchar (15) null,
NotOnUsCheck varchar (15) null,
SStatus char (10 ) null default '0',  -- default set the default value to record
Remarks varchar (max) null,
InsertDateTime datetime null default getdate(), -- getdate the current date from the system 
ProcessStartDateTime datetime null,
ProcessEndDateTime datetime null,
RetryCount int null default '0',
);

/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP (1000) [Id]
      ,[Name]
      ,[Value]
      ,[Description]
  FROM [sql_tutorial].[dbo].[Configuration]