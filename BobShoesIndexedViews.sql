SELECT * FROM Orders.Customers;
SELECT * FROM Orders.CustomersLocation;
SELECT * FROM Orders.OrderItems;
SELECT * FROM Orders.Orders;
SELECT * FROM Orders.Salutations;
SELECT * FROM Orders.Stock




-- DETERMINISTIC VIEWS
USE BobsShoes;
GO

DROP VIEW IF EXISTS foo;
GO

CREATE VIEW foo
WITH SCHEMABINDING
AS
SELECT 
    CONCAT(oi.OrderID, oi.OrderItemID) AS One, 
    oi.Discount * cast(.90 as [float]) AS Two
FROM Orders.OrderItems oi;
GO

DROP INDEX IF EXISTS ix_foo ON foo;
 -- CREATE UNIQUE CLUSTERED INDEX ix_foo ON foo(One, Two);  Cannot use Column Two because Floating Point Number DATATYPE are not Precise
CREATE UNIQUE CLUSTERED INDEX ix_foo ON foo(One); -- Table Index Views's require a table both Deterministic and precise

-- CREATE CLUSTERED INDEX ON THE VIEWS WITH INDEXING RULES
CREATE OR ALTER VIEW Orders.CustomerList
WITH SCHEMABINDING
AS
SELECT 
	Cust.CustID					AS Customer_ID,
	Cust.CustName				AS Name,
	Cust.CustStreet				AS Street,
	Ord.OrderDate				AS Ordered_On,
	Ord.OrderDeliveryDate		AS Delivered_On,
	Sal.Salutation				AS Saluation,
	Item.Quantity				AS Quantity
--	Stock.StockName				AS Stock
	--COUNT_BIG(*)				AS Records_Count -- Rule on indexes view: GROUP BY function come in hand with COUNT BIG function
FROM Orders.Customers as Cust
JOIN Orders.Orders as Ord
	ON Cust.CustID = Ord.OrderID
JOIN Orders.Salutations as Sal
	ON Cust.SalutationID = Sal.SalutationID
JOIN Orders.OrderItems as Item
	ON Ord.OrderID = Item.OrderID
/*JOIN Orders.Stock as Stock
	ON Stock.StockID = Stock.StockID
 GROUP BY	Cust.CustID, CustName,	CustStreet,
			Ord.OrderDate, Ord.OrderDeliveryDate,
			Sal.Salutation,
			Item.Quantity,
			Stock.StockName
	*/		
GO

-- Create a Unique, clustered index on the view
DROP INDEX IF EXISTS UQ_CustomerList_CustomerID ON Orders.CustomerList;
CREATE UNIQUE CLUSTERED INDEX UQ_CustomerList_CustomerID
    ON Orders.CustomerList(Customer_ID);		-- USE UNIQUE COMPOSITE to solve duplicate key that may arise ie:  ON Orders.CustomerList(Customer_ID, Stock)
GO

-- Query the view
SELECT Customer_ID, Name, Saluation, Quantity, Delivered_On --, Stock, 
    FROM Orders.CustomerList 
    WHERE Customer_ID = 2
    -- OPTION (EXPAND VIEWS); -- Ignore the index and expand the view into querie on the underlying tables.
GO

-- Create a non clustered index on the view
DROP INDEX IF EXISTS IX_CustomerList_Name_PostalCode ON Orders.CustomerList;
CREATE NONCLUSTERED INDEX IX_CustomerList_Name_PostalCode  
    ON Orders.CustomerList(Name, Street);
GO
