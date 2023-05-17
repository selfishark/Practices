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

SET STATISTICS IO ON

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
GO

/* INLINE TABLE VALUE FUNCTION, ITVFs */

/*
  Create simple ITVF
*/
USE Contacts
GO

CREATE OR ALTER FUNCTION dbo.SuperAdd_itvf(@a INT, @b INT)
RETURNS TABLE
WITH SCHEMABINDING
AS		-- no Begin, no End
RETURN(SELECT @a + @b AS SumValue);
GO


SELECT * FROM dbo.SuperAdd_itvf(2,2);
GO


/*
  Convert this to a CTE Example
*/
CREATE OR ALTER FUNCTION dbo.SuperAdd_itvf(@a INT, @b INT)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN(
	WITH SumValues AS (		-- here is the CTE coming to action
		SELECT @a + @b AS SumValue
	)
	SELECT SumValue FROM SumValues
	)
GO

SELECT * FROM DBO.SUPERADD_ITVF(2,2);
GO

--- CONVERTED MSTVF into a ITVF
USE BobsShoes
GO

CREATE OR ALTER FUNCTION dbo.AvrOrderSales_itvf(@OrderID INT, @OrderDate DATE, @OrderRequestedDate DATE)
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

SELECT * FROM dbo.AvrOrderSales_itvf(3,'2020-12-03','2020-12-03');

-- CROSS APPLICATION OF THE FUNCTION ON A SELECT STATEMENT
SELECT C.CustID, AOS. * FROM Orders.Orders C
	CROSS APPLY(
		SELECT * FROM dbo.AvrOrderSales_itvf(C.CustID ,'2020-12-03','2020-12-03')
	) AOS
	WHERE MinimumQte > 2

GO

/* Other Example of Functions */
USE Contacts
GO

-- Scalar function
CREATE FUNCTION CalculateAge(@dob DATE)
RETURNS INT
AS
BEGIN
	DECLARE @age INT

	SET @age = DATEDIFF(YEAR, @dob, GETDATE()) - 
												CASE
													WHEN (MONTH(@dob) > MONTH(GETDATE())) OR
														 (MONTH(@dob) = MONTH(GETDATE()) AND DAY(@dob) > DAY(GETDATE()))
													THEN 1
													ELSE 0
												END
	RETURN @age
END;
GO

-- Using the previous scalar function
SELECT dbo.CalculateAge('02/25/1993')


SELECT ContactId, FirstName, dbo.CalculateAge(DateOfBirth) AS Age FROM [dbo].[Contacts]
WHERE dbo.CalculateAge(DateOfBirth) > 30

-- text of the function
SP_HELPTEXT CalculateAge
GO

-- Inline Table Valued Function example 
	-- Inline table using a view table 
CREATE OR ALTER FUNCTION dbo.EmployeByRole(@Role varchar(200))
RETURNS TABLE	
AS		-- therer is no begin - close here
	RETURN (
		SELECT [ContactId], [FirstName], [LastName], [DateOfBirth], [RoleTitle]
		FROM [dbo].[VW_ContactRoles]
		WHERE [RoleTitle] = @Role
	)


-- retrieve data by calling the function
SELECT * FROM dbo.EmployeByRole('DBA')
WHERE dbo.CalculateAge(DateOfBirth) > 30; -- here CalculateAge is scalar function

-- retrieve data by calling the function, combined with a JOIN statement
SELECT	D.ContactId, 
		D.FirstName, 
		D.LastName, 
		D.DateOfBirth, 
		D.RoleTitle, 
		cvd.DrivingLicenseNumber, 
		cvd.PassportNumber, 
		cvd.ContactVerified
FROM dbo.EmployeByRole('Developer') D	-- the function sort the Employee list by Role
	INNER JOIN dbo.ContactVerificationDetails cvd
	ON	cvd.ContactId = d.ContactId



-- multi statement value table functions
CREATE OR ALTER FUNCTION dbo.EmployeeAddresses()
	-- MSTVF require the definition of the table to be called
RETURNS  @table Table(ContactId INT, Firstname VARCHAR(40), LastName VARCHAR(40), [D.O.B] DATE, HouseNumber VARCHAR(200), Postcode VARCHAR(40))
AS
BEGIN	-- unlike ITVF there is a begin and end close
	INSERT INTO @table 
	SELECT	c.ContactId, 
			c.Firstname , 
			c.LastName, 
			CAST(c.DateOfBirth AS DATE), -- converting the date
			ca.HouseNumber, 
			ca.Postcode 
	FROM dbo.Contacts c
		INNER JOIN dbo.ContactAddresses ca 
		ON C.ContactId = ca.ContactId

	RETURN
END
GO

SELECT ContactId, Firstname, LastName, HouseNumber, Postcode -- here the column [D.O.B]was purposefully omited as there is possibility to choose which column to retrieve
FROM [dbo].[EmployeeAddresses]()



-- ITVF can UPDATE the base table woks on
	-- example with a dummy function
		UPDATE fn_ITVF_GetEmployee() SET Name = 'Sam' WHERE Id = 1
