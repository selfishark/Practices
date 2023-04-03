SELECT * FROM Orders.Customers;
SELECT * FROM Orders.CustomersLocation;
SELECT * FROM Orders.OrderItems;
SELECT * FROM Orders.Orders;
SELECT * FROM Orders.Salutations;
SELECT * FROM Orders.Stock


-- JOIN table to see the relation

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
ORDER BY B.OrderDate;
GO

SELECT 
	A.CustID
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
WHERE A.CustName LIKE '%t%';
--ORDER BY B.OrderDate
GO


CREATE OR ALTER VIEW Orders.CustomersOrderDateAndLocation
AS 
	SELECT  
	A.CustName
	,A.CustStreet
	,B.OrderDate
	,B.OrderDeliveryDate
FROM Orders.Customers as A
	JOIN Orders.Orders as B
		ON A.CustID = B.OrderID
	AND A.CustID = B.OrderID
WHERE A.CustName LIKE '%t%'
--ORDER BY B.OrderDate
GO

-- best parctice VIEW query
-- ALTER the view to add column aliases
-- Then SELECT the VIEW an ORDER result BY
CREATE OR ALTER VIEW Orders.CustomerList
AS
SELECT 
	A.CustID				AS Customer_ID,
	A.CustName				AS Name,
	A.CustStreet			AS Street,
	B.OrderDate				AS Ordered_On,
	B.OrderDeliveryDate		AS Delivered_On,
	C.Salutation			AS Saluation,
	D.Quantity				AS Quantity,
	E.StockName				AS Stock
FROM Orders.Customers as A
JOIN Orders.Orders as B
	ON A.CustID = B.OrderID
JOIN Orders.Salutations as C
	ON A.SalutationID = C.SalutationID
JOIN Orders.OrderItems as D
	ON B.OrderID = D.OrderID
JOIN Orders.Stock as E
	ON E.StockID = D.StockID
GO

SELECT 
	cl.Customer_ID,
	cl.Name,
	cl.Street,
	cl.Ordered_On,
	cl.Delivered_On,
	cl.Saluation,
	cl.Quantity,
	cl.Stock
FROM Orders.CustomerList cl
WHERE cl.Name LIKE '%t%'
ORDER BY cl.Ordered_On;

-- VIEWS WITH SCHEMA BINDING 
CREATE OR ALTER VIEW bar
WITH SCHEMABINDING
AS
    SELECT 
        a AS an_integer, 
        b as a_float 
    FROM dbo.foo;
GO

CREATE OR ALTER VIEW Orders.CustomersOrderDateAndLocation
WITH SCHEMABINDING				-- invoke schema-binding condition
AS 
	SELECT  
	 A.CustName
	,A.CustStreet
	,B.OrderDate
	,B.OrderDeliveryDate
FROM dbo.Orders.Customers as A  -- specify binding schema, ie: dbo
	JOIN Orders.Orders as B
		ON A.CustID = B.OrderID
	AND A.CustID = B.OrderID
WHERE A.CustName LIKE '%t%'
--ORDER BY B.OrderDate
GO


--- TEST OF VIEW CONSTRAINS
CREATE OR ALTER View Orders.OrderSummary
WITH SCHEMABINDING 
AS
    SELECT 
        o.OrderID,
        o.OrderDate,
        IIF(o.OrderIsExpedited = 1, 'YES', 'NO') AS Expedited,
        c.CustName,
        SUM(i.Quantity) TotalQuantity

    FROM Orders.Orders o
    JOIN Orders.Customers c 
      ON o.CustID = c.CustID
    JOIN Orders.OrderItems i
      ON o.OrderID = i.OrderID
    GROUP BY o.OrderID, o.OrderDate, o.OrderIsExpedited, c.CustName;
GO

CREATE OR ALTER VIEW Orders.CustomersOrderItems
WITH SCHEMABINDING
AS 
	SELECT  top 10  -- Rule 4
	Customers.CustName		AS Name,
	Customers.CustStreet	AS Street,
	Orders.OrderDate		AS Ordered_On,
	Orders.OrderDeliveryDate	AS Delivered_On,
	C.Discount		AS On_Discount

FROM Orders.Customers AS Customers
	JOIN Orders.Orders AS Orders
		ON A.CustID = B.OrderID
	AND Customers.CustID = B.OrderID
	JOIN Orders.OrderItems AS C
		ON Orders.OrderID = C.OrderID
WHERE Customers.CustName LIKE '%t%'
WITH CHECK OPTION; -- Not Working with Rule 4
GO

-- Updating VIEW Rule 1
BEGIN TRAN
UPDATE Orders.CustomerList
SET Name = 'Ross Methven'
WHERE Name = 'Ross Pratt';

-- REVERT CHANGE WITH ROLLBACK on Table transaction
SELECT * FROM Orders.CustomerList;
ROLLBACK

