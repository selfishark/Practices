-- SELECTING DATABASE AND CREATING SCHEMA & TABLE FOR PRACTICE

USE BASICS


CREATE SCHEMA base


DROP TABLE IF EXISTS base.franchisees --, bases.Stores, bases.UnifiedRecipts
CREATE TABLE base.Franchisees
(
FranchiseesID INT 
	CONSTRAINT PK_Franchisees_FranchisesID PRIMARY KEY, -- IDENTITY(1,1)
Name NVARCHAR(40),
City NVARCHAR(40),
State VARCHAR(2)
);


DROP TABLE IF EXISTS base.Stores
CREATE TABLE base.Stores
(
StoresID INT 
	CONSTRAINT PK_Stores_StoresID PRIMARY KEY, -- IDENTITY(1,1)
Franchisee INT
	CONSTRAINT FK_Stores_Franchisee_Franchisees_FranchiseesID FOREIGN KEY REFERENCES base.Franchisees (FranchiseesID) ON DELETE CASCADE,
Zipcode NVARCHAR(5),
YearsInBusiness INT,
);


DROP TABLE IF EXISTS base.UnifiedReceipts
CREATE TABLE base.UnifiedReceipts
(
	RegisterID INT CONSTRAINT PK_UnifiedReceipts_RegisterID PRIMARY KEY, -- IDENTITY(1,1)
StoresID INT
	CONSTRAINT FK_UnifiedReceipts_StoresID_Stores_StoresID FOREIGN KEY REFERENCES base.Stores(StoresID),
[Sequence] INT,
Amount MONEY,
[Date] DATE,
CashierID INT
);

GO


-- Populating the table for practical uses 

INSERT INTO base.Franchisees (
	FranchiseesID, 
	Name, 
	City, 
	State)

VALUES 
	(301, 'Joe', 'Greenville', 'MD'),
	(512, 'Jane', 'Orangetown', 'OH'),
	(121, 'Jack', 'Burgerville', 'LA'),
	(891, 'Jim', 'East Eden', 'CT'),
	(2355, 'Tad', 'Blottingsworth', 'NM'),
	(67, 'Tom', 'Upper Lower', 'MD');


INSERT INTO base.Stores (
	StoresID,
	Franchisee,
	Zipcode,
	YearsInBusiness
)
VALUES
(14, 301, 29601, '2010'),
(13, 512, 10913, '1989'),
(12, 121, 15650, '1998'),
(11, 891, 14057, '2000'),
(10, 2355, 13895, '1999'),
(9, 67, 20711, '1898');



INSERT INTO base.UnifiedReceipts (
	RegisterID, 
	StoresID, 
	[Sequence], 
	Amount, 
	[Date], 
	CashierID)

VALUES 
 (1, 14, 23836, 117.15, '11/27/2012', 16)
,(2, 13, 23639, 66.48, '7/ 4/2012', 12)
,(3, 12, 23251, 119.23, '7/10/2012', 14)
,(4, 11, 23340, 38.49, '10/ 1/2012', 7)
,(5, 10, 23380, 13.49, '9/10/2012', 10)
,(6, 9, 23092, 99.34, '7/ 9/2012', 2);

/*
,(7, 8, 23229, 88.11, '8/ 9/2012', 1)
,(8, 7, 23304, 65.82, '11/23/2012', 11)
,(9, 6, 23284, 43.7, '4/ 1/2012', 41)
,(10, 5, 23085, 44, '11/23/2012', 33)
,(11, 4, 23045, 119.74, '2/14/2012', 3)
,(12, 3, 23508, 70.98, '3/21/2012', 21)
,(13, 2, 23738, 12.54, '1/ 7/2012', 6)
,(14, 1, 23558, 19.87, '6/19/2012', 32)
;
*/

/****** Script for SelectTopNRows command from SSMS  ******/
SELECT [FranchiseesID]
      ,[Name]
      ,[City]
      ,[State]
  FROM [basics].[base].[Franchisees]


/****** Script for SelectTopNRows command from SSMS  ******/
SELECT [StoresID]
      ,[Franchisee]
      ,[Zipcode]
      ,[YearsInBusiness]
  FROM [basics].[base].[Stores]

/****** Script for SelectTopNRows command from SSMS  ******/
SELECT [RegisterID]
      ,[StoresID]
      ,[Sequence]
      ,[Amount]
      ,[Date]
      ,[CashierID]
  FROM [basics].[base].[UnifiedReceipts]

GO
 -- CREATING CTE (COMMON TABLE EXPRESSION)

 -- Syntax Illustration
WITH StoreLocation
AS
(SELECT Franchisee, Zipcode, YearsInBusiness FROM base.Stores)

SELECT * FROM StoreLocation

GO


-- or 

WITH StoreLocation2 (FranchiseeID, [Franchise ZIPCODE], Creation)
AS
(SELECT Franchisee, Zipcode, YearsInBusiness FROM base.Stores)

SELECT * FROM StoreLocation2

GO

-- multiple CTE examples (CTE can reference each other as long as the is no forward referencing)

-- INDEPENDENT CTE

WITH FranchisesSales
AS
	(SELECT 
		Store.Zipcode,
		Store.YearsInBusiness,
		Receipt.[Sequence],
		Receipt.[Amount]
	FROM base.Stores AS Store
	INNER JOIN base.UnifiedReceipts AS Receipt
	ON Store.StoresID=Receipt.StoresID),

FranchisesLocations ([Owner], City, State)
AS	
	(SELECT 
		[Name], 
		City, 
		[State] 
	FROM base.Franchisees)

SELECT * FROM FranchisesLocations, FranchisesSales;

GO



