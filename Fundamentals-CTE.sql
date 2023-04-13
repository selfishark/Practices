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
 -- CTE precede the defintion of the operation the statement performs.

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
-- SQL Server analyse the query as a whole and then produce a query plan

-- INDEPENDENT CTE
WITH FranchisesSales -- result set 1  // NOTE: the WITH keyword appears only once
AS
	(SELECT 
		Store.Zipcode,
		Store.YearsInBusiness,
		Receipt.[Sequence],
		Receipt.[Amount]
	FROM base.Stores AS Store
	INNER JOIN base.UnifiedReceipts AS Receipt
	ON Store.StoresID=Receipt.StoresID),		-- expression seperated by commas

FranchisesLocations ([Owner], City, [State])	-- result set 2, with names results set that can be reffered to subsequently in the expression
AS	
	(SELECT 
		[Name], 
		City, 
		[State] 
	FROM base.Franchisees)

SELECT * FROM FranchisesLocations, FranchisesSales;		-- each result set here is considered as Temporary View, use the SELECT statement to refer to it/them.

GO


-- TWO CTE: On referencing to other
	-- You can reference only the CTEs before the current one and not the CTEs that follow.

WITH SalesPerStores --(StoreID, FranchiseeID, [Sum Store Sales])
AS
	(SELECT 
		Store.StoresID,
		Store.Franchisee,
		SUM(Receipt.Amount) AS [Sum Store Sales]
	FROM base.Stores AS Store 
	INNER JOIN base.UnifiedReceipts AS Receipt
	ON Store.StoresID=Receipt.StoresID
	GROUP BY Store.StoresID, Store.Franchisee),

SalesAmountAVG --([Sales Average])
AS 
	(SELECT 
		AVG([Sum Store Sales]) AS [Sales Average] -- you can refer to a column from the previous result set, directly.
	FROM SalesPerStores)


SELECT * FROM SalesPerStores, SalesAmountAVG

GO

-- TWO CTE: On referencing to other
WITH ReceiptAmount 
AS
	(SELECT 
		RegisterID, 
		StoresID, 
		Amount 
	FROM base.UnifiedReceipts),

AnnualAmount (RegisterID, StoresID, Amount, [YrinBiz x Amount], [FranchiseID]) -- these columns are transfered to the columns copied from refered tables (inherited)
AS
	(SELECT
		RA.RegisterID,
		RA.StoresID,
		RA.Amount,
		(RA.Amount * BS.YearsInBusiness) AS [YrinBiz x Amount],
		BS.Franchisee
	FROM ReceiptAmount AS RA
	--CROSS JOIN base.Stores AS BS -- CROSS JOIN doesn't work on boolean expression like expected with 'ON' with an INNER JOIN Statement
	INNER JOIN base.Stores AS BS
	ON RA.StoresID=BS.StoresID
	)

SELECT		-- SELECT column From the previous CTE because it inherite the prvious column by hierachy
	F.[Name],
	AN.FranchiseID,
	AN.RegisterID,
	AN.StoresID,
	AN.Amount,
	[YrinBiz x Amount]
FROM AnnualAmount AS AN
INNER JOIN base.Franchisees AS F
ON AN.FranchiseID=F.FranchiseesID

GO



SELECT 
	StoreID,
	[Sales
	([Sum Store Sales]*12) AS [Annual Sales]
FROM SalesPerStore
	INNER JOIN SalesAmountAVG as saa
ON	


		

SELECT * FROM SalesPerStores, SalesAmountAVG, Unified;
GO

--Unified (StoreID, Franchisee, [Sum Store Sales], [Sales Average], [Name], City)
--AS
/*	--(
sps.StoreID,
		sps.Franchisee,
		sps.[Sum Store Sales],
		saa.[Sales Average],
		fran.[Name],
		fran.City
	FROM SalesPerStore AS sps
	INNER JOIN SalesAmountAVG AS saa
	ON
	INNER JOIN base.Franchisees as fran
	ON saa.franchisee=franchiseesID
	GROUP BY saa.StoreID, saa.Franchisee, saa.[Sum Store Sales], saa.[Sales Average], fran.[Name],	fran.City)
*/	

-- RANKING FUNCTION: Row Number, Rank, Dense Rank


USE [training-test]
			-- THIS RANKING SHOULD PROMPT DIFFERENT RESULTS IF IT HAS DUPLICATES ON 'TP'
SELECT 
	City, 
	Temprature AS tp, 
	[DateTime],
		ROW_NUMBER() OVER (ORDER BY Temprature) AS RowNmbr_tp,
		RANK() OVER (ORDER BY Temprature) AS Rank_tp,
		DENSE_RANK() OVER (ORDER BY Temprature) AS Dense_Rank_tp

FROM [training-test].[dbo].[Weather_API_Table]


-- NTILE
USE [training-test]

SELECT 
	City, 
	Temprature AS tp, 
	[DateTime],
		NTILE (2) OVER (ORDER BY Temprature) AS [NTILE OF 2 ON tp] -- Here the tile is per 2 or 2%;  'Tile per 100' is percentile (100%), 'Tile per 10' is decitile (10%).

FROM [training-test].[dbo].[Weather_API_Table]

GO

-- It is best practice to choose the number of item that goes is a tile rather than the number tiles
USE [training-test]

SELECT 
	City, 
	Temprature AS tp, 
	[DateTime],
		NTILE ((SELECT COUNT (*)/10 FROM [dbo].[Weather_API_Table])) OVER (ORDER BY Temprature) AS [NTILE OF 10 ITEMS PER TILE ] -- This tile take 10 items per tile.

FROM [training-test].[dbo].[Weather_API_Table]

ORDER BY City

GO