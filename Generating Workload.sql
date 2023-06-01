-- Creating a procedure that SELECT all the records of a ramdom PK from a given table to generate Workload that can feed the DTA with transactions
USE AdventureWorksLT2022
GO

CREATE OR ALTER PROCEDURE dbo.TestIndexWorkload
    @DatabaseName NVARCHAR(100),
    @SchemaName NVARCHAR(100),
    @TableName NVARCHAR(100),
    @PrimaryKeyColumnName NVARCHAR(100),
    @Iterations INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @Counter INT = 1;

    WHILE @Counter <= @Iterations
    BEGIN
        -- Generate a random PK ID
        DECLARE @RandomID INT;
        SET @SQL = N'SELECT TOP 1 @RandomID = ' + QUOTENAME(@PrimaryKeyColumnName) + N' FROM ' + QUOTENAME(@DatabaseName) + N'.' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName) + N' ORDER BY NEWID();';
        EXEC sp_executesql @SQL, N'@RandomID INT OUTPUT', @RandomID = @RandomID OUTPUT;

        -- Retrieve all records with the random PK ID
        SET @SQL = N'SELECT * FROM ' + QUOTENAME(@DatabaseName) + N'.' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName) + N' WHERE ' + QUOTENAME(@PrimaryKeyColumnName) + N' = @RandomID;';
        EXEC sp_executesql @SQL, N'@RandomID INT', @RandomID;

        SET @Counter += 1;
    END;
END;


---- SqlQueryStress or OSTRESS (RML Utilities)
/*
I can also use OSTRESS or SqlQueryStress to simulate multiple sessions to generate a workload based on the above procedure with 

-- with SqlQueryStress just download the application
-- with OSTRESS use a similar query
C:\Program Files\Microsoft Corporation\RMLUtils> .\ostress.exe -E -W3-DEV-005\MSSQLSERVEREVAL -d"AdventureWorksLT2022" -n10 -r5 -q -Q"EXEC dbo.TestIndexWorkload @DatabaseName = 'AdventureWorksLT2022', @SchemaName = 'SalesLT', @TableName = 'Address', @PrimaryKeyColumnName = 'AddressID', @Iterations = 10;" -0"C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVEREVAL\MSSQL\Log"

*/
----



USE [AdventureWorksLT2022]

EXEC dbo.TestIndexWorkload @DatabaseName = 'AdventureWorksLT2022', @SchemaName = 'SalesLT', @TableName = 'Address', @PrimaryKeyColumnName = 'AddressID', @Iterations = 50;

EXEC dbo.TestIndexWorkload @DatabaseName = 'AdventureWorksLT2022', @SchemaName = 'SalesLT', @TableName = 'CustomerAddress', @PrimaryKeyColumnName = 'CustomerID', @Iterations = 50;

EXEC dbo.TestIndexWorkload @DatabaseName = 'AdventureWorksLT2022', @SchemaName = 'SalesLT', @TableName = 'Product', @PrimaryKeyColumnName = 'ProductID', @Iterations = 50;

EXEC dbo.TestIndexWorkload @DatabaseName = 'AdventureWorksLT2022', @SchemaName = 'SalesLT', @TableName = 'ProductCategory', @PrimaryKeyColumnName = 'ProductDescriptionID', @Iterations = 50;

EXEC dbo.TestIndexWorkload @DatabaseName = 'AdventureWorksLT2022', @SchemaName = 'SalesLT', @TableName = 'ProductDescription', @PrimaryKeyColumnName = 'ProductDescriptionID', @Iterations = 50;

EXEC dbo.TestIndexWorkload @DatabaseName = 'AdventureWorksLT2022', @SchemaName = 'SalesLT', @TableName = 'ProductModel', @PrimaryKeyColumnName = 'ProductModelID', @Iterations = 50;

EXEC dbo.TestIndexWorkload @DatabaseName = 'AdventureWorksLT2022', @SchemaName = 'SalesLT', @TableName = 'ProductModelProductDescription', @PrimaryKeyColumnName = 'ProductDescriptionID', @Iterations = 50;

EXEC dbo.TestIndexWorkload @DatabaseName = 'AdventureWorksLT2022', @SchemaName = 'SalesLT', @TableName = 'SalesOrderDetail', @PrimaryKeyColumnName = 'SalesOrderID', @Iterations = 50;

EXEC dbo.TestIndexWorkload @DatabaseName = 'AdventureWorksLT2022', @SchemaName = 'SalesLT', @TableName = 'SalesOrderHeader', @PrimaryKeyColumnName = 'SalesOrderID', @Iterations = 50;



USE [SQLAuthority]

EXEC dbo.TestIndexWorkload @DatabaseName = 'SQLAuthority', @SchemaName = 'dbo', @TableName = 'DiskBasedTable', @PrimaryKeyColumnName = 'ID', @Iterations = 50;

EXEC dbo.TestIndexWorkload @DatabaseName = 'SQLAuthority', @SchemaName = 'dbo', @TableName = 'MemoryOptimizedTable', @PrimaryKeyColumnName = 'ID', @Iterations = 50;

EXEC dbo.TestIndexWorkload @DatabaseName = 'SQLAuthority', @SchemaName = 'dbo', @TableName = 'MemoryOptimizedTable_I_Mem', @PrimaryKeyColumnName = 'ID', @Iterations = 50;

EXEC dbo.TestIndexWorkload @DatabaseName = 'SQLAuthority', @SchemaName = 'dbo', @TableName = 'MemoryOptimizedTable_I_Mem', @PrimaryKeyColumnName = 'ID', @Iterations = 50;

