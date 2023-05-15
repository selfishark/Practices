/*
  Look at a select statement with three built-in Scalar functions
*/
SELECT MONTH(GETDATE()) AS [MONTH], YEAR(GETDATE()) AS [YEAR];
GO


/*
  Create a very simple User-Defined, Multi-Statement Scalar Function
*/
CREATE OR ALTER FUNCTION dbo.SuperAdd_scaler(@a INT, @b INT)
RETURNS INT
WITH SCHEMABINDING
AS
BEGIN
	/*
	  Although this just happens to be one statement, I can have more than 
	  one in a scalar function, so don't let that confuse you.
	*/
	RETURN @a + @b;
END;
GO

/*
  Do simple addition
*/
select dbo.SuperAdd_scaler(4,2);
GO

/*
  Create a slightly more complext Multi-Statement Scalar Function that
  returns the Fiscal Year Ending of a provided date/time.

  Defaulting to June as the default Fiscal Ending Month
*/
-- this function take a date input and returns a Fiscal Year based on the given Fiscal End Month
CREATE OR ALTER FUNCTION dbo.FiscalYearEnding(@SaleDate DATETIME, @FiscalEndMonth INT = 6)
RETURNS INT
WITH SCHEMABINDING --	means it is bound to the schema of the referenced objects and prevents any changes to those objects that could break the function
AS
BEGIN
	DECLARE @saleMonth INT = MONTH(@SaleDate);
	DECLARE @saleYear INT = YEAR(@SaleDate);
	DECLARE @fiscalYear INT = @saleYear;

	IF(@saleMonth > @FiscalEndMonth AND @FiscalEndMonth != 1) -- go to the next year if the inputed month is greater than 6
	BEGIN
		SET @fiscalYear = @saleYear + 1;
	END;

	RETURN @fiscalYear;
END;
GO

-- example of Fiscal Year test

SELECT '2019-01-01' SampleDate, dbo.FiscalYearEnding('2019-01-01',1) FiscalYear; -- 2019
SELECT '2019-07-01' SampleDate, dbo.FiscalYearEnding('2019-07-01',6) FiscalYear; -- 2020
SELECT '2019-07-01' SampleDate, dbo.FiscalYearEnding('2019-07-01',7) FiscalYear; -- 2019
SELECT '2019-12-01' SampleDate, dbo.FiscalYearEnding('2019-05-01',4) FiscalYear; -- 2020
SELECT '2019-12-01' SampleDate, dbo.FiscalYearEnding('2019-12-01',12) FiscalYear; -- 2019

SELECT TOP (1000) 
	ContactId, LastName, dbo.FiscalYearEnding(DateOfBirth, DEFAULT) AS FiscalYear 
FROM dbo.Contacts

SELECT TOP (1000) ContactId, LastName, YEAR(DateOfBirth) AS [Given Date], dbo.FiscalYearEnding(DateOfBirth, DEFAULT) AS [Fiscal Year] FROM dbo.Contacts 
WHERE dbo.FiscalYearEnding(DateOfBirth, DEFAULT) > 1960 


USE BobsShoes

INSERT INTO Orders.OrderItems2
	(OrderID, StockID, Quantity, Price, Discount)
VALUES
	(1, 7, 5, 100, 30.00),
	(2, 5, 3, 25, 10.00),
	(3, 6, 10, 70, 12.00)
GO


CREATE OR ALTER FUNCTION dbo.AvrOrderSales(@OrderID INT, @OrderDate DATE, @OrderRequestedDate DATE)
RETURNS @AverageOrderSales TABLE
(
	OrderID INT,
	MinimumQte Decimal(9, 2),
	MaximumQte Decimal(9, 2),
	AverageQte Decimal(9, 2),
	Total INT
)
WITH SCHEMABINDING
AS 
BEGIN
	--	checks if the difference in days between @OrderDate and @OrderRequestedDate is less than 1. If it is, @OrderRequestedDate is updated by adding 10 days to @OrderDate.
	IF (DATEDIFF(DAY, @OrderDate, @OrderRequestedDate) < 1)
	BEGIN
		SET @OrderRequestedDate = DATEADD(DAY, 10, @OrderDate);
	END

	--  inserts data into the @AverageOrderSales table variable by selecting the OrderID, minimum quantity, maximum quantity, and average quantity from the Orders.OrderItems2 table. It joins the Orders.Orders table to retrieve the order details and calculates the total price by multiplying the price and quantity of each order item using the CROSS APPLY clause
	INSERT INTO @AverageOrderSales
	SELECT OI2.OrderID, MIN(Quantity) MinimumQte, MAX(Quantity) MaximumQte, AVG(Quantity) AverageQte, Total FROM Orders.OrderItems2 OI2
		INNER JOIN Orders.Orders O ON O.OrderID = OI2.OrderID
		CROSS APPLY(
			SELECT (OI2.Price * OI2.Quantity) Total FROM Orders.OrderItems2
			WHERE OI2.OrderID = O.OrderID
		) OL
	WHERE OI2.OrderID = @OrderID
		AND O.OrderDate >= @OrderDate
		AND O.OrderDate <= @OrderRequestedDate
	GROUP BY O.CustID, OI2.OrderID,OL.Total;

	--	Overall, this function is designed to calculate the minimum, maximum, and average quantity of order items for a given order within a specified date range.
	RETURN;

END;
GO

SELECT * FROM dbo.AvrOrderSales(1,'2019-03-01','2019-03-01');
SELECT * FROM dbo.AvrOrderSales(2,'2023-07-01','2023-07-01');
SELECT * FROM dbo.AvrOrderSales(3,'2020-12-03','2020-12-03');

-- CROSS APPLICATION OF THE FUNCTION ON A SELECT STATEMENT
SELECT C.CustID, AOS. * FROM Orders.Orders C
	CROSS APPLY(
		SELECT * FROM dbo.AvrOrderSales(C.CustID ,'2020-12-03','2020-12-03')
	) AOS
	WHERE MinimumQte > 2

GO

SELECT * FROM sys.sql_modules WHERE is_inlineable = 1;