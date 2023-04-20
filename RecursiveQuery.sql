-- RECURSIVES QUERIES
with f1(A, B)
as
(
select 502, 4
union all
select A-1, B+A from f1
where not A <= 1
)
select B from f1
where A < 5
option (maxrecursion 0) -- cannot recurse more than 100 times // but can be controlled here, 0 is unlimited

--TABLE RECURSION
DROP TABLE IF EXISTS [BASE].[PERSONNEL (PARENTED)]
CREATE TABLE [BASE].[PERSONNEL (PARENTED)]
	(
	EmployeeID INT,
	[Name] nvarchar(50),
	[Hourly Rate] money,
	BossTreeID int -- parent in personnel tree
	);

--SET IDENTITY_INSERT BASE.[PERSONNEL (PARENTED)] ON;		-- allows explicit values to be inserted into the identity column of a table.
INSERT INTO [BASE].[PERSONNEL (PARENTED)] (EMPLOYEEID, [NAME], [HOURLY RATE], BossTreeID)
VALUES
(1, 'Big Boss', 1000.00, 1),
(2, 'Joe', 10.00, 1),
(8, 'Mary', 20.00, 1),
(14, 'Jack', 15.00, 1),
(3, 'Jane', 10.00, 2),
(5, 'Max', 35.00, 2),
(9, 'Lynn', 15.00, 8),
(10, 'Miles', 60.00, 8),
(12, 'Sue', 15.00, 8),
(15, 'June', 50.00, 14),
(18, 'Jim', 55.00, 14),
(19, 'Bob', 40.00, 14),
(4, 'Jayne', 35.00, 3),
(6, 'Ann', 45.00, 5),
(7, 'Art', 10.00, 5),
(11, 'Al', 70.00, 10),
(13, 'Mike', 50.00, 12),
(16, 'Marty', 55.00, 15),
(17, 'Barb', 60.00, 15),
(20, 'Bart', 1000.00, 19);
--SET IDENTITY_INSERT [BASE].[PERSONNEL (PARENTED)] OFF;

SELECT * FROM [BASE].[PERSONNEL (PARENTED)]
ORDER BY BossTreeID

--RECURSIVE QUERY ON THE TABLE PERSONNEL
DECLARE @bossId int;
SET @bossId = 8;	-- MARY (TREE ID)

WITH TREE
AS
	(
	SELECT			-- Anchor initialisation // Which collects Mary Employee ID and Tree ID
		EmployeeID,
		BossTreeID
	FROM [BASE].[PERSONNEL (PARENTED)]
	WHERE EmployeeID=@bossId

	UNION ALL		-- Recursive selection // which then finds all the employee in Mary's tree

	SELECT 
		PP.EmployeeID,
		PP.BossTreeID
	FROM [BASE].[PERSONNEL (PARENTED)] AS PP
	JOIN TREE ON TREE.EmployeeID=PP.BossTreeID -- Collects all the Employee below Mary and the ones belows them until nobody left in the tree
	)

SELECT PP.* FROM [BASE].[PERSONNEL (PARENTED)] AS PP
JOIN TREE ON TREE.EmployeeID=PP.EmployeeID	-- this is where the result set is outputs with all the information about all the retrieved employee

GO



--RECURSIVE QUERY BUDGET HOURLY RATE OF THE EMPLOYEE IN MARY TREE
DECLARE @bossId int;
SET @bossId = 8;	-- MARY (TREE ID)

WITH TREE
AS
	(
	SELECT			-- Anchor initialisation // Which collects Mary Employee ID and Tree ID
		EmployeeID,
		BossTreeID
	FROM [BASE].[PERSONNEL (PARENTED)]
	WHERE EmployeeID=@bossId

	UNION ALL		-- Recursive selection // which then finds all the employee in Mary's tree

	SELECT 
		PP.EmployeeID,
		PP.BossTreeID
	FROM [BASE].[PERSONNEL (PARENTED)] AS PP
	JOIN TREE ON TREE.EmployeeID=PP.BossTreeID -- Collects all the Employee below Mary and the ones belows them until nobody left in the tree
	)

SELECT SUM (PP.[Hourly Rate]) AS [Mary Dept. Budget] FROM [BASE].[PERSONNEL (PARENTED)] AS PP
JOIN TREE 
ON TREE.EmployeeID=PP.EmployeeID	-- this is where the result set is outputs with all the information about all the retrieved employee

GO


--CREATE A T.V.F (TABLE VALUE FUNCTION) TO GET ANYONE'S TREE IN THE TABLE
CREATE FUNCTION PersonelTree (@bossId int)
RETURNS TABLE 
AS
RETURN
WITH TREE
AS
	(
	SELECT			-- Anchor initialisation // Which collects Employee ID and Tree ID
		EmployeeID,
		BossTreeID
	FROM [BASE].[PERSONNEL (PARENTED)]
	WHERE EmployeeID=@bossId

	UNION ALL		-- Recursive selection // which then finds all the employee in the tree

	SELECT 
		PP.EmployeeID,
		PP.BossTreeID
	FROM [BASE].[PERSONNEL (PARENTED)] AS PP
	JOIN TREE 
	ON TREE.EmployeeID=PP.BossTreeID  AND PP.EmployeeID!=PP.BossTreeID --
	)

SELECT * FROM TREE

GO

SELECT PP.* FROM [BASE].[PERSONNEL (PARENTED)] AS PP
JOIN PersonelTree(9) AS [EMPLOYEE TREE] 
ON PP.EmployeeID=[EMPLOYEE TREE].EmployeeID	-- this is where the result set is outputs with all the information in regards to the provided BossID.



-- TABLE PIVOT AS IN EXCEL 
		-- PIVOT AND UNPIVOT (CONVERT ROWS INTO COLUMNS AND ROWS INTO COLUMNS RESPECTIVELY)
		-- Works best directly after a subquery

select *		-- THE * REFERS TO THE OUTPUT OF THE OPERATION NOT THE TABLE ITSELF (the subquery)
from 
	(select 
	total, cast([date] as date)  as [date], 
	payment from [sales receipts]) as t		
		pivot		-- PIVOT AND UNPIVOT OPERATES ON WHAT IMMEDIATLY PRECEDES IT 
		(
			sum(total)		-- aggregating the total money paid per date per payment method
			for [payment] in ([VISA], [AmEx], [MasterCard], Cash)	-- pivoting the different payment method
		) 
as p		-- alias mendatatory
order by [date]

-- OR 

select id, cast([date] as date) as [date], payment  from [sales receipts]  -- these column can be renamed with AS function

	pivot
	(
	count(id)
	for [payment] in ([VISA], [AmEx], [MasterCard], Cash)
	) as p
order by [date]	 


-- EXAMPLE OF TABLE UNPIVOT
select   * 
	into [#pivoted receipts]	-- TEMPORARY TABLE FOR THE UNPIVOT REVERSE ACTION
	from (select id, cast([date] as date)  as [date], payment 
	from [sales receipts]) as t   
		pivot
		(
		count(id)
		for [payment] in ([VISA], [AmEx], [MasterCard], Cash)
		) as p


select *  from [#pivoted receipts]
UNPIVOT
([sales] for payment in (VISA, AmEx, MasterCard, Cash)) as p
 order by date, payment



-- EXAMPLE OF ENTITY ATTRIBUTE VALUE QUERY
select * from properties
PIVOT (
-- each value will come from the corresponding "value"
-- column of the properties table
MAX(value)	-- aggregating with max can take any variable type
-- rows that have a name equal to
-- "color", "type" or "amount" will
-- be added to the columns of the output table
for name in ([color], [type], [amount])
)
AS P
-- this limits the virtual table to Swish rows
where id in (select id from products where name='Swish')
go


-- TABLE SAMPLING WITH 

select * from [sales receipts]
tablesample(1000 rows)
-- repeatable(444); -- THIS FIX REPEAT THE SAMPLE SET

-- GOOD BECAUSE READS ALL THE ROWS AND QUITE PRECISES
select * from [sales receipts]
where 0.001 >= cast(checksum(newid(), id) & 0x7fffffff AS float) 
/ cast (0x7fffffff AS int) 
order by id

-- GOOD BECAUSE IT IS FAST BUT SKIPS ROWS/PAGES AND SHOULD NOT BE USED WITH CLUSTERED INDEXES
select *  from [sales receipts]
tablesample (.1 percent);
