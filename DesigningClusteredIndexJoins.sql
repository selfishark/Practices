USE SqlTutorial
GO


CREATE SCHEMA Orders;
GO


-- Create the tables for trial purpose

DROP TABLE IF EXISTS Orders.Stock
CREATE TABLE Orders.Stock (
    StockID int IDENTITY(1,1) NOT NULL
      CONSTRAINT UQ_Stock_StockID UNIQUE, -- CLUSTERING PROPERTY ASSIGNED IN THE INDEXATION BELOW 
    StockSKU char(8) NOT NULL,
    StockSize INT NOT NULL,
    StockName varchar(100) NOT NULL,
    StockPrice numeric(7, 2) NOT NULL,
);

DROP TABLE IF EXISTS Orders.OrderItems
CREATE TABLE Orders.OrderItems ( 
    OrderItemID int IDENTITY(1,1) NOT NULL
        CONSTRAINT UQ_OrderItems_OrderItemID UNIQUE, -- UNIQUE KEY to meet the clustering trade-off
    OrderID int NOT NULL,
    StockID int NOT NULL  
        CONSTRAINT FK_OrderItems_StockID_Stock_StockID
            FOREIGN KEY REFERENCES Orders.Stock (StockID), 
    Quantity smallint NOT NULL,
    Discount numeric(4, 2) NOT NULL
);

-- populate the tables for trial purpose
INSERT INTO Orders.Stock (
        StockSKU, 
        StockName, 
        StockSize, 
        StockPrice)

VALUES
    ('MODI2453', 'ADIDAS', '11', 30.),
    ('MOROGR25', 'PUMA', '6', 45.),
    ('ESSHOOD5', 'TOMY HILFIGER', '8', 65.),
    ('OXFORD01', 'Oxford', '10', 50.),
    ('BABYSHO1', 'BabySneakers', '3', 20.),
    ('HEELS001', 'Killer Heels', '7', 75.)



INSERT INTO Orders.OrderItems(
    StockID, --
	OrderID, --   
	Quantity, 
    Discount)

VALUES
    ( 3, 1, 6, 20.),
    ( 2, 3, 5, 10.),
	( 4, 7, 4, 60.),
    ( 5, 8, 8, 35.),
	( 6, 7, 9, 70.),
    ( 1, 4, 6, 25.)




SELECT * FROM Orders.Stock1;
SELECT * FROM Orders.Stock2;
SELECT * FROM Orders.Stock3;

GO

-- create back table
SELECT * 
INTO Stock
FROM Orders.Stock1

GO


SET STATISTICS IO ON ;  
GO

-- TEST OF THE CHOICE OF INDEX KEY, 
-- Create a WIDE Clustered Index on the table
DROP INDEX IF EXISTS idx_Stock1_StockID ON Orders.Stock1;
CREATE CLUSTERED INDEX idx_Stock1_StockID
    ON Orders.Stock1(StockID, StockSKU, StockSize, StockPrice);		-- USE UNIQUE COMPOSITE to solve duplicate key that may arise ie:  ON Orders.CustomerList(Customer_ID, Stock)
GO


-- Create a Clustered Index on the STOCKSKU, to test rule niether unchanging nor ever-increasing
DROP INDEX IF EXISTS idx_Stock2_StockID ON dbo.Stock2;
CREATE CLUSTERED INDEX idx_Stock2_StockID
    ON Orders.Stock2(StockSKU);		-- USE UNIQUE COMPOSITE to solve duplicate key that may arise ie:  ON Orders.CustomerList(Customer_ID, Stock)
GO

-- Create a Clustered Index on the STOCKNAME, to test reasonably Narrow, mostly increasing and Unchanging
DROP INDEX IF EXISTS idx_Stock3_StockID ON Orders.Stock3;
CREATE CLUSTERED INDEX idx_Stock3_StockID
    ON Orders.Stock3(StockName);		-- USE UNIQUE COMPOSITE to solve duplicate key that may arise ie:  ON Orders.CustomerList(Customer_ID, Stock)
GO

/*
SELECT OBJECT_NAME(OBJECT_ID) AS tableIndexName, -- Database Related Dynamic Management Views (Transact-SQL)
	used_page_count,
	reserved_page_count,
	row_count
FROM sys.dm_db_partition_stats 
WHERE OBJECT_NAME(OBJECT_ID) IN ('idx_Stock1_StockID', 'idx_Stock2_StockID', 'idx_Stock3_StockID')
*/

-- evaluating equality predicate on stock3

DROP INDEX IF EXISTS idx_Stock3_StockSKU ON Orders.Stock3;
CREATE NONCLUSTERED INDEX idx_Stock3_StockSKU
    ON Orders.Stock3(StockSKU);		-- USE UNIQUE COMPOSITE to solve duplicate key that may arise ie:  ON Orders.CustomerList(Customer_ID, Stock)
GO

DROP INDEX IF EXISTS idx_Stock3_StockName ON Orders.Stock3;
CREATE NONCLUSTERED INDEX idx_StockName
    ON Orders.Stock3(StockName);		-- USE UNIQUE COMPOSITE to solve duplicate key that may arise ie:  ON Orders.CustomerList(Customer_ID, Stock)
GO

DROP INDEX IF EXISTS idx_Stock3_StockSkuAndName ON Orders.Stock3;
CREATE NONCLUSTERED INDEX idx_StockSkuAndName
    ON Orders.Stock3(StockSKU, StockName);		-- CREATING AN INDEX on two column allow the optimiser to use it on any both columns, or even one column alone if required
GO

SELECT StockName FROM Orders.Stock3
WHERE StockSKU ='BABYSHO1'			-- the execution differ (SCAN instead of SEEK when indexation type not define)

SELECT StockSKU, StockName FROM Orders.Stock3
WHERE StockSKU ='BABYSHO1' AND StockName ='PUMA' -- like '%a%'


-- evaluating inequality predicate on stock2

DROP INDEX IF EXISTS idx_Stock2_StockPrice ON Orders.Price;
CREATE NONCLUSTERED INDEX idx_Stock2_StockPrice
    ON Orders.Stock2(StockPrice);		
GO


SELECT StockPrice FROM Orders.Stock2
WHERE StockPrice > 25 


DROP INDEX IF EXISTS idx_Stock2_StockName ON Orders.Stock2;
CREATE NONCLUSTERED INDEX idx_Stock2_PriceAndName
    ON Orders.Stock2(StockPrice, StockName);		-- USE UNIQUE COMPOSITE to solve duplicate key that may arise ie:  ON Orders.CustomerList(Customer_ID, Stock)
GO

SELECT StockPrice FROM Orders.Stock2
WHERE StockPrice > 25 and StockName='PUMA' -- the equality predicate is prior in the seeking operation


DROP INDEX IF EXISTS idx_Stock2_SizeAndPrice ON Orders.Stock2;
CREATE NONCLUSTERED INDEX idx_Stock2_SizeAndPrice
    ON Orders.Stock2(StockSize, StockPrice);		-- 
GO

DROP INDEX IF EXISTS idx_Stock2_Size ON Orders.Stock2;
CREATE NONCLUSTERED INDEX idx_Stock2_Size
    ON Orders.Stock2(StockSize);		-- 
GO

SELECT StockSize, StockPrice FROM Orders.Stock2
WHERE StockSize > 6  AND StockPrice < 50		-- SWITCHING THE INDEX POSITION TO THE LEFT(Size or Price), BUT SAME RESULT WITH THE SEEK OPERATION because of the inequality predcate so the best of perfomance is the one to choose


SELECT StockID, StockName, StockSize, StockPrice FROM Orders.Stock2
WHERE StockSize = 6  OR StockPrice = 50

SELECT StockID, StockName StockSize, StockPrice FROM Orders.Stock2
WHERE StockID = 1 AND (StockSize > 6  OR StockPrice < 50)  -- USE INDEX INTERSECTION OF idx_Stock2_Size AND idx_Stock2_Price to quickly seek the result

GO

DROP INDEX IF EXISTS idx_Stock_StockName ON Orders.Stock;
CREATE NONCLUSTERED INDEX idx_Stock_StockName
    ON Orders.Stock(StockName);		-- 
GO

-- INDEXING FOR JOINS

SELECT Itm.OrderItemID, Stk.StockName		-- seek predicate on JOIN_ed Tables
	FROM Orders.OrderItems as Itm
		INNER JOIN Orders.Stock Stk ON Itm.StockID = Stk.StockID
	WHERE Itm.OrderItemID = 2


SELECT Itm.OrderItemID, Stk.StockName		-- seek predicate on JOIN_ed Tables
	FROM Orders.OrderItems as Itm
		INNER MERGE JOIN Orders.Stock Stk ON Itm.StockID = Stk.StockID
	WHERE Itm.OrderItemID = 2



-- INDEX ON JOINED TABLE 
-- join table OrderItem and Stock

/*
CREATE OR ALTER VIEW Orders.Stock_Items_Stats
AS
SELECT
	Stock.StockName			AS Name,
	Stock.StockSKU			AS SKU,
	Stock.StockSize			AS Size,
	Stock.StockPrice		AS Price,
	Item.Quantity			AS Quantity,
	Item.Discount			AS Discount_On
FROM Orders.Stock as Stock
JOIN Orders.OrderItems AS Item
	ON Stock.StockID = Item.StockID
GO

SELECT * FROM Orders.Stock_Items_Stats
GO
*/


ALTER TABLE Orders.OrderItems
ADD CONSTRAINT PK_OrderItems_OrderItemID
    PRIMARY KEY (OrderItemId);
GO


-- INDEXING FOR INCLUDE COLUMNS
DROP INDEX IF EXISTS idx_Stock_StockSKU	ON Orders.Stock
CREATE NONCLUSTERED INDEX idx_Stock_StockSKU
	ON Orders.Stock(StockSKU)
	INCLUDE(StockSize, StockPrice)		-- Including columns helps avoiding look-ups

-- Querrying the index idx_Stock_StockSKU with included columns
SELECT StockSKU, StockSize, StockPrice FROM Orders.Stock
	WHERE StockSKU = 'MOROGR25'


-- FILTERED INDEX
DROP INDEX IF EXISTS idx_Stock_StockSize ON Orders.Stock
CREATE INDEX idx_Stock_StockSize
	ON Orders.Stock(StockSize)
	WHERE StockSize = 6

SELECT StockSize, StockName from Orders.Stock 
	WHERE StockSize = 6			-- Can only be used with Hard Coded value Queries and not parametised queries