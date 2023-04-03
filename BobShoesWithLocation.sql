-- Create database for Bobs Shoes

-- Note: the script uses the file path
--       C:\Users\ltwansi\Documents\SQL Training\Practices
-- To run in your environment, either create the path or change the pathname in the code below

USE master;
GO
CREATE DATABASE BobsShoes;
GO

-- Show the entry for BobsShoes in the system tables
SELECT * FROM sys.databases WHERE name = 'BobsShoes';

-- Change to the new database context
USE BobsShoes;
GO

-- Show the layout of the files for the database
EXEC sp_helpfile;
GO

-- Create schema for Bobs Orders
CREATE SCHEMA Orders 
    AUTHORIZATION dbo;
GO



USE BobsShoes;   -- enter the databe context BobShoes
GO   -- bash seperator to start a series of code

CREATE TABLE Orders.OrderTracking (
    OrderId int IDENTITY (1,1) NOT NULL,
    OrderDate datetime2(0) NOT NULL,
    RequestedDate datetime2(0) NOT NULL,
    DeliveryDate datetime2(0) NULL,
    CustName nvarchar(200) NOT NULL,
    CustAddress nvarchar(200) NOT NULL,
    ShoeStyle varchar(200) NOT NULL,
    ShoeSize varchar(10) NOT NULL,
    SKU char(8) NOT NULL,
    UnitPrice numeric(7, 2) NOT NULL,
    Quantity smallint NOT NULL,
    Discount numeric(4, 2) NOT NULL,
    IsExpedited bit NOT NULL,
    TotalPrice AS (Quantity * UnitPrice * (1.0 - Discount)), -- PERSISTED
) 

-- Adding Primary Key Constraint
USE BobsShoes;
GO

ALTER TABLE Orders.OrderTracking 
ADD CONSTRAINT PK_OrderTracking_OrderId -- PK_OrderTracking_OrderId is the name of the constraint
    PRIMARY KEY (OrderId)

GO


-- Show the collation configured on the instance
SELECT SERVERPROPERTY('collation') AS DefaultInstanceCollationName;

-- Show the collation configured on the database
SELECT DATABASEPROPERTYEX(DB_NAME(), 'collation') AS DatabaseCollationName;

-- Show the collation for all the columns in the OrderTracking table
SELECT name AS ColumnName, collation_name AS ColumnCollation
    FROM sys.columns 
    WHERE object_id = OBJECT_ID(N'Orders.OrderTracking'); -- collation applies on char, varchar, nvarchar

-- Show the description for the collation
SELECT name, description 
    FROM sys.fn_helpcollations()
    WHERE name = N'SQL_Latin1_General_CP1_CI_AS'; -- for case sensitivity

-- Show SQL collations not containing 'LATIN'
SELECT name, description 
    FROM sys.fn_helpcollations()
    WHERE name LIKE N'SQL_%' AND name not like N'SQL_Latin%';     

-- Change the customer column to a Scandinavian collation.
ALTER TABLE Orders.OrderTracking
    ALTER COLUMN CustName nvarchar(200) 
        COLLATE  SQL_Scandinavian_CP850_CI_AS -- COLLATE clause apply a character expression to Customer's Name to be compatible with Scandinavian names 
        NOT NULL;


USE BobsShoes;
GO

TRUNCATE TABLE Orders.OrderTracking;
INSERT INTO Orders.OrderTracking(
    OrderDate,     
    RequestedDate, 
    CustName,  
    CustAddress,   
    ShoeStyle,     
    ShoeSize,      
    SKU,           
    UnitPrice,     
    Quantity,    
    Discount,      
    IsExpedited
	)
VALUES 
	('20190301', '20190401', 'Arthur Dent', 'Golgafrincham', 'Oxford', '10_D', 'OXFORD01', 50.0, 1, 0, 0),
	('20190301', '20190401', 'Arthur Dent', 'Golgafrincham', 'BabySneakers', '3', 'BABYSHO1', 20.0, 1, 0, 0),	
	('20190301', '20190401', 'Arthur Dent', 'Golgafrincham', 'Killer Heels', '7', 'HEELS001', 75.0, 1, 0, 0);
	('20190315', '20190501', 'Arthur Dent', 'Golgafrincham', 'Boots', '10_D', 'BOOTS001', 50.0, 1, 0, 0),
	('20190315', '20190501', 'Arthur Dent', 'Golgafrincham', 'Slippers', '3', 'SLIPPERS', 20.0, 1, 0, 0);


USE BobsShoes;
GO

-- UPDATE Anomaly

UPDATE Orders.OrderTracking
SET CustAddress = 'Magarathea'
WHERE OrderDate = '20190301'
AND CustName = 'Arthur Dent'

SELECT * FROM Orders.OrderTracking
WHERE CustName = 'Arthur Dent'


USE BobsShoes;
GO

-- Remove any existing tables

DROP TABLE IF EXISTS Orders.Customers, Orders.Stock, Orders.Orders, Orders.OrderItems;

CREATE TABLE Orders.Customers (
    CustID int IDENTITY(1,1) NOT NULL -- PRIMARY KEY,
        CONSTRAINT PK_Customers_CustID PRIMARY KEY,
    CustName nvarchar(200) NOT NULL,
    CustStreet nvarchar(100) NOT NULL,
    CustCity nvarchar(100) NOT NULL,
    CustStateProv nvarchar(100) NOT NULL,
    CustCountry nvarchar(100) NOT NULL,
    CustPostalCode nvarchar(20) NOT NULL,
    CustSalutation char(5) NOT NULL
);

CREATE TABLE Orders.Stock (
    StockSKU char(8) NOT NULL,
    StockSize varchar(10) NOT NULL,
    StockName varchar(100) NOT NULL,
    StockPrice numeric(7, 2) NOT NULL,
    CONSTRAINT PK_Stock_StockSKU_StockSize PRIMARY KEY (StockSKU, StockSize)
);

CREATE TABLE Orders.Orders (  
    OrderID int IDENTITY(1,1) NOT NULL -- PRIMARY KEY,
        CONSTRAINT PK_Orders_OrderID PRIMARY KEY,
    OrderDate date NOT NULL,
    OrderRequestedDate date NOT NULL,
    OrderDeliveryDate datetime2(0) NULL,
    CustID int NOT NULL,
    OrderIsExpedited bit NOT NULL
 );

CREATE TABLE Orders.OrderItems (
    OrderItemID int IDENTITY(1,1) NOT NULL -- PRIMARY KEY,
        CONSTRAINT PK_OrderItems_OrderItemID PRIMARY KEY,
    OrderID int NOT NULL,
    StockSKU char(8) NOT NULL,
    StockSize varchar(10) NOT NULL,
    Quantity smallint NOT NULL,
    Discount numeric(4, 2) NOT NULL
);

RETURN;


-- Add customers

INSERT INTO Orders.Customers (
        CustName, 
        CustStreet, 
        CustCity, 
        CustStateProv, 
        CustCountry, 
        CustPostalCode, 
        CustSalutation)
VALUES 
    ('Arthur Dent', '1 Main St', 'Golgafrincham', 'GuideShire', 'UK', '1MSGGS', 'Mr.'),
    ('Trillian Astra', '42 Cricket St.', 'Islington', 'Greater London', 'UK', '42CSIGL', 'Miss')

INSERT INTO Orders.Stock (
        StockSKU, 
        StockName, 
        StockSize, 
        StockPrice)

VALUES
    ('OXFORD01', 'Oxford', '10_D', 50.),
    ('BABYSHO1', 'BabySneakers', '3', 20.),
    ('HEELS001', 'Killer Heels', '7', 75.)

INSERT INTO Orders.Orders(
    OrderDate, 
    OrderRequestedDate, 
    CustID, 
    OrderIsExpedited)

VALUES 
    ('20190301', '20190401', 1, 0),
    ('20190301', '20190401', 2, 0)

INSERT INTO Orders.OrderItems(
    OrderID, 
    StockSKU, 
    StockSize, 
    Quantity, 
    Discount)

VALUES
    (1, 'Oxford', '10_D', 1, 0.),
    (2, 'HEELS001', '7', 1, 0.)

-- Display results

SELECT * FROM Orders.Customers;
SELECT * FROM Orders.Stock
SELECT * FROM Orders.Orders;
SELECT * FROM Orders.OrderItems;

USE BobsShoes;
GO


-- 2NF NORMALISATION
-- Remove any existing tables

DROP TABLE IF EXISTS Orders.Customers, Orders.Stock, Orders.Orders, Orders.OrderItems;

CREATE TABLE Orders.Customers (
    CustID int IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_Customers_CustID PRIMARY KEY,
    CustName nvarchar(200) NOT NULL,
    CustStreet nvarchar(100) NOT NULL,
    CustCity nvarchar(100) NOT NULL,
    CustStateProv nvarchar(100) NOT NULL,
    CustCountry nvarchar(100) NOT NULL,
    CustPostalCode nvarchar(20) NOT NULL,
    CustSalutation char(5) NOT NULL
);

CREATE TABLE Orders.Stock (
    StockID int IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_Stock_StockID PRIMARY KEY,    
    StockSKU char(8) NOT NULL,
    StockSize varchar(10) NOT NULL,
    StockName varchar(100) NOT NULL,
    StockPrice numeric(7, 2) NOT NULL,
    -- CONSTRAINT PK_Stock_StockSKU_StockSize PRIMARY KEY (StockSKU, StockSize)
);

CREATE TABLE Orders.Orders (  
    OrderID int IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_Orders_OrderID PRIMARY KEY,
    OrderDate date NOT NULL,
    OrderRequestedDate date NOT NULL,
    OrderDeliveryDate datetime2(0) NULL,
    CustID int NOT NULL,
    OrderIsExpedited bit NOT NULL
 );

CREATE TABLE Orders.OrderItems (
    OrderItemID int IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_OrderItems_OrderItemID PRIMARY KEY,
    OrderID int NOT NULL,
    StockID int NOT NULL,
    Quantity smallint NOT NULL,
    Discount numeric(4, 2) NOT NULL
);

RETURN;


-- Populate the tables

INSERT INTO Orders.Customers (
        CustName, 
        CustStreet, 
        CustCity, 
        CustStateProv, 
        CustCountry, 
        CustPostalCode, 
        CustSalutation)
VALUES 
    ('Arthur Dent', '1 Main St', 'Golgafrincham', 'GuideShire', 'UK', '1MSGGS', 'Mr.'),
    ('Trillian Astra', '42 Cricket St.', 'Islington', 'Greater London', 'UK', '42CSIGL', 'Miss')

INSERT INTO Orders.Stock (
        StockSKU, 
        StockName, 
        StockSize, 
        StockPrice)

VALUES
    ('OXFORD01', 'Oxford', '10_D', 50.),
    ('BABYSHO1', 'BabySneakers', '3', 20.),
    ('HEELS001', 'Killer Heels', '7', 75.)

INSERT INTO Orders.Orders(
    OrderDate, 
    OrderRequestedDate, 
    CustID, 
    OrderIsExpedited)

VALUES 
    ('20190301', '20190401', 1, 0),
    ('20190301', '20190401', 2, 0)

INSERT INTO Orders.OrderItems(
    OrderID, 
    StockID,
    Quantity, 
    Discount)

VALUES
    (1, 1, 1, 20.),
    (2, 3, 1, 20.)

-- Show the results

SELECT * FROM Orders.Customers;
SELECT * FROM Orders.Stock
SELECT * FROM Orders.Orders;
SELECT * FROM Orders.OrderItems;



-- Can't insert an order item with a non-existent orderid

INSERT INTO Orders.OrderItems(
    OrderID, 
    StockID,
    Quantity, 
    Discount)
VALUES (42,42,42,42.)



-- 3NF NORMALISATION
USE BobsShoes;
GO

-- Remove any existing tables

DROP TABLE IF EXISTS Orders.OrderItems, Orders.Orders, Orders.Stock, Orders.Customers, Orders.Salutations, Orders.CustomersLocation;

--DELETE TABLE IF EXISTS Orders.OrderItems, Orders.Orders, Orders.Stock, Orders.Customers, Orders.Salutations, Orders.CustomersLocation;


CREATE TABLE Orders.CustomersLocation (
	CustLocationID int IDENTITY (1,1) NOT NULL
		CONSTRAINT PK_CustLocation_CustlocationID PRIMARY KEY,
    CustCity nvarchar(100) NOT NULL,
    CustStateProv nvarchar(100) NOT NULL,
    CustCountry nvarchar(100) NOT NULL,
    CustPostalCode nvarchar(20) NOT NULL,
);

CREATE TABLE Orders.Salutations (
    SalutationID int IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_Salutations_SalutationID PRIMARY KEY,
    Salutation varchar(5) NOT NULL
);

CREATE TABLE Orders.Customers (
    CustID int IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_Customers_CustID PRIMARY KEY,
    CustName nvarchar(200) NOT NULL,
	CustStreet nvarchar(100) NOT NULL,
	CustLocationID int  NOT NULL
		CONSTRAINT FK_Customers_CustLocationID_CustomersLocation_CustlocationID
			REFERENCES Orders.CustomersLocation(CustLocationID),
    SalutationID int  NOT NULL
       CONSTRAINT FK_Customers_SaluationID_Salutations_SalutationID 
           REFERENCES Orders.Salutations (SalutationID),
);

CREATE TABLE Orders.Stock (
    StockID int IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_Stock_StockID PRIMARY KEY,    
    StockSKU char(8) NOT NULL,
    StockSize varchar(10) NOT NULL,
    StockName varchar(100) NOT NULL,
    StockPrice numeric(7, 2) NOT NULL,
);

 CREATE TABLE Orders.Orders (  
    OrderID int IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_Orders_OrderID PRIMARY KEY,
    OrderDate date NOT NULL,
    OrderRequestedDate date NOT NULL,
    OrderDeliveryDate datetime2(0) NULL,
    CustID int NOT NULL --,
        CONSTRAINT FK_Orders_CustID_Customers_CustID 
            FOREIGN KEY REFERENCES Orders.Customers (CustID),
    OrderIsExpedited bit NOT NULL
 );

CREATE TABLE Orders.OrderItems ( -- add non cluster constraint to 
    OrderItemID int IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_OrderItems_OrderItemID PRIMARY KEY,
    OrderID int NOT NULL --,
        CONSTRAINT FK_OrderItems_OrderID_Orders_OrderID
            FOREIGN KEY REFERENCES Orders.Orders (OrderID),
    StockID int NOT NULL --,
        CONSTRAINT FK_OrderItems_StockID_Stock_StockID
            FOREIGN KEY REFERENCES Orders.Stock (StockID)
				ON DELETE CASCADE, 
    Quantity smallint NOT NULL,
    Discount numeric(4, 2) NOT NULL
);

RETURN;

-- Populate the tables

INSERT INTO Orders.Salutations (
		--SalutationID,
		Salutation
		)
VALUES 
	('Mr.'), 
	('Miss'),
	('Mrs.')


INSERT INTO Orders.CustomersLocation (  --HERRE
        --CustLocationID,
		CustCity, 
        CustStateProv, 
        CustCountry, 
        CustPostalCode)
VALUES 
    ('Golgafrincham', 'GuideShire', 'UK', '1MSGGS'),
    ('Islington', 'Greater London', 'UK', '42CSIGL'),
	('Marlone', 'Greater Glasgow', 'UK', 'G334QA')


INSERT INTO Orders.Customers (
		CustName,
		CustStreet,
		CustLocationID, --
		SalutationID
	)  -- HREEE
VALUES 
    ('Arthur Dent','1 Main St', 2, 3),
	('Trillian Astra', '42 Cricket St.', 1, 2), 
	('Ross Pratt', '16 Brooke St.', 3, 2)


INSERT INTO Orders.Orders( --HERE
    OrderDate, 
    OrderRequestedDate, 
    CustID, --
    OrderIsExpedited)

VALUES 
    ('20190301', '20190301', 1, 0),
    ('20230701', '20230701', 2, 0),
    ('20201203', '20201203', 2, 0)



INSERT INTO Orders.OrderItems(
    OrderID, --
    StockID, --
    Quantity, 
    Discount)

VALUES
    ( 3, 1, 6, 20.),
    ( 2, 3, 5, 20.)


INSERT INTO Orders.Stock (
        StockSKU, 
        StockName, 
        StockSize, 
        StockPrice)

VALUES
    ('OXFORD01', 'Oxford', '10_D', 50.),
    ('BABYSHO1', 'BabySneakers', '3', 20.),
    ('HEELS001', 'Killer Heels', '7', 75.)


SELECT * FROM Orders.Customers;
SELECT * FROM Orders.CustomersLocation;
SELECT * FROM Orders.OrderItems;
SELECT * FROM Orders.Orders;
SELECT * FROM Orders.Salutations;
SELECT * FROM Orders.Stock

-- Can't insert an order item with a non-existent orderid

INSERT INTO Orders.OrderItems(
    OrderID, 
    StockID,
    Quantity, 
    Discount)
VALUES (42,42,42,42.)



-- Add default constraint for the OrderDate

ALTER TABLE Orders.Orders
    ADD CONSTRAINT DF_Orders_OrderDate_Getdate 
        DEFAULT GETDATE() FOR OrderDate;


-- Add default constraint for the expedited flag

ALTER TABLE Orders.Orders
    ADD CONSTRAINT DF_Orders_OrderIsExpedited_False
        DEFAULT 0 FOR OrderIsExpedited;

EXEC sp_helpfile
GO

-- JOIN table to see the relation

SELECT * 
	,A.CustID
	,A.CustName
	,A.CustStreet
	,B.OrderDate
	,B.OrderDeliveryDate
	,C.Salutation
	,D.Quantity
	,E.StockName
FROM Orders.Customers as A
JOIN Orders.Orders as B
	ON A.CustID = B.OrderID
JOIN Orders.Salutations as C
	ON A.SalutationID = C.SalutationID
JOIN Orders.OrderItems as D
	ON B.OrderID = D.OrderID
JOIN Orders.Stock as E
	ON E.StockID = D.StockID
WHERE A.CustName LIKE '%t%'
ORDER BY B.OrderDate

-- VIEW 
--
CREATE VIEW SortBobsShoesCustomersOrderDate AS -- TO DEBUG
SELECT * 
	,A.CustID
	,A.CustName
	,A.CustStreet
	,B.OrderDate
	,B.OrderDeliveryDate
FROM Orders.Customers as A
JOIN Orders.Orders as B
	ON A.CustID = B.OrderID
		AND A.CustID = B.OrderID
WHERE A.CustName LIKE '%t%'
--ORDER BY B.OrderDate


-- UNIQUE CONSTRAINT
CREATE TABLE Orders.Stock2 (
    StockID int IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_Stock_StockID PRIMARY KEY,    
    StockSKU char(8) NOT NULL
		CONSTRAINT UQ_STOCK_STOCKSKU
			UNIQUE CLUSTERED,
    StockSize varchar(10) NOT NULL,
    StockName varchar(100) NOT NULL,
    StockPrice numeric(7, 2) NOT NULL,
);





-- DEFAULT CONSTRAINTS
-- issue 
--Incorrect syntax for definition of the 'TABLE' constraint.

CREATE TABLE Orders.OrdersTest (  
    OrderID int IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_Orders_OrderID PRIMARY KEY,
    OrderDate date NOT NULL,
		CONSTRAINT DF_Orders_OrderDate_GetDate
			DEFAULT GETDATE(),
    OrderRequestedDate date NOT NULL,
		CONSTRAINT DF_Orders_OrderResquestedDate_GetDate
			DEFAULT GETDATE(),
    OrderDeliveryDate datetime2(0) NULL,
		CONSTRAINT DF_OrderDeliveryDate_TBC	
			DEFAULT 'TBC',
    CustID int NOT NULL --,
        CONSTRAINT FK_Orders_CustID_Customers_CustID 
            FOREIGN KEY REFERENCES Orders.Customers (CustID),
    OrderIsExpedited bit NOT NULL
		CONSTRAINT DF_Orders_OrderIsExpedited_False
            DEFAULT 0
 );


 -- FOREIGN KEY CASCADE UPDATE EXAMPLE

 DROP TABLE IF EXISTS _2, _1
CREATE TABLE _1 (
    StatChar char(1) PRIMARY KEY,
    StatStatus varchar(20) NOT NULL 
    );

CREATE TABLE _2 (
    StatChar CHAR(1) NULL REFERENCES _1(StatChar)
            ON UPDATE SET NULL
    );

INSERT INTO _1 (StatChar, StatStatus)
    VALUES ('A', 'A-Status'), ('B', 'B-Status');
INSERT INTO _2 VALUES ('A'), ('B');


 

UPDATE _1 SET 
    StatChar = 'C',
    StatStatus = 'C-Status'
WHERE StatChar = 'B'; 

SELECT * FROM _2;



-- table constraint with CHECK function
DROP TABLE IF EXISTS Orders.Stock;
CREATE TABLE Orders.Stock (
    StockID int IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_Stock_StockID PRIMARY KEY CLUSTERED,    
    StockSKU char(8) NOT NULL,
    StockSize varchar(10) NOT NULL,
    StockName varchar(100) NOT NULL,
    StockPrice numeric(7, 2) NOT NULL,
    CONSTRAINT UQ_Stock_StockSKU_StockSize UNIQUE NONCLUSTERED (StockSKU, StockSize),
    CONSTRAINT CK_Stock_SKU_cannot_equal_Description CHECK (StockSKU <> StockName )
);


-- Define a table constraint with CHECK function on date
DROP TABLE IF EXISTS Orders.Orders;
CREATE TABLE Orders.Orders (  
    OrderID int IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_Orders_OrderID PRIMARY KEY,
    OrderDate date NOT NULL,
    OrderRequestedDate date NOT NULL,
    OrderDeliveryDate datetime2(0) NULL,
    CustID int NOT NULL
        CONSTRAINT FK_Orders_CustID_Customers_CustID 
            FOREIGN KEY REFERENCES Orders.Customers (CustID),
    OrderIsExpedited bit NOT NULL,
    CONSTRAINT CK_Orders_RequestedDate_must_follow_OrderDate
        CHECK (1 = Orders.CheckDates(OrderDate, OrderRequestedDate))