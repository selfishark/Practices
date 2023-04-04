-- DESIGNING COLUMNSTORES INDEXES

USE SqlTutorial
GO


SET STATISTICS IO ON ;  
GO


CREATE SCHEMA Orders;
GO


-- Create the tables for trial purpose

DROP TABLE IF EXISTS Orders.Stock4
CREATE TABLE Orders.Stock4 (
    StockID int IDENTITY(1,1) NOT NULL,
     -- CONSTRAINT UQ_Stock_StockID UNIQUE, -- CLUSTERING PROPERTY ASSIGNED IN THE INDEXATION BELOW 
    StockSKU char(8) NOT NULL,
    StockSize INT NOT NULL,
    StockName varchar(100) NOT NULL,
    StockPrice numeric(7, 2) NOT NULL,
);

DROP TABLE IF EXISTS Orders.OrderItems4
CREATE TABLE Orders.OrderItems4 ( 
    OrderItemID int IDENTITY(1,1) NOT NULL,
     --   CONSTRAINT UQ_OrderItems_OrderItemID UNIQUE, -- UNIQUE KEY to meet the clustering trade-off
    OrderID int NOT NULL,
    StockID int NOT NULL,  
    --    CONSTRAINT FK_OrderItems_StockID_Stock_StockID
    --       FOREIGN KEY REFERENCES Orders.Stock (StockID), 
    Quantity smallint NOT NULL,
    Discount numeric(4, 2) NOT NULL
);

-- populate the tables for trial purpose
INSERT INTO Orders.Stock4 (
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



INSERT INTO Orders.OrderItems4(
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




SELECT * FROM Orders.Stock4;
SELECT * FROM Orders.OrderItems4;


GO

-- EVALUATING TABLE PROPERTIES

SELECT COUNT(*) FROM Orders.Stock4				-- Count table columns
GO

SELECT OBJECT_ID, 
		Index_id,
		used_page_count,
		reserved_page_count,
		row_count
FROM sys.dm_db_partition_stats 
WHERE OBJECT_ID = OBJECT_ID ('Orders.Stock4')	-- Page count shows how big is the page count (a page is 8kb ) changes after the clustering normally the compression should reduce the table page count used

GO

SELECT * FROM sys.indexes 
WHERE OBJECT_ID = OBJECT_ID ('Orders.Stock4')   -- Table described as a HEAP before the clustering

GO

-- CREATE CLUSTERED COLUMNSTORE INDEXES
DROP INDEX IF EXISTS c_idx_Orders_OrderStock4_Columnstore ON Orders.Stock4
CREATE CLUSTERED COLUMNSTORE INDEX c_idx_Orders_OrderStock4_Columnstore ON Orders.Stock4;

GO


-- CREATE NONCLUSTERED INDEX ON SPECIFIC COLUMNS
-- The NonClustered Index create a secondary structure, seperate from the initial HEAP table for  indexation
DROP INDEX IF EXISTS nc_idx_Orders_OrderStock4_Columnstore ON Orders.Stock4
CREATE NONCLUSTERED COLUMNSTORE INDEX nc_idx_Orders_OrderStock4_Columnstore ON Orders.Stock4(StockID, StockName, StockSKU, StockPrice);

GO


-- This sys commands give the number of row group
SELECT * FROM sys.column_store_row_groups

GO