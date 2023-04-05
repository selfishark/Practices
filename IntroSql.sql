USE [training-test]

/* Best practices
	SELECT STATEMENT
	-- using capital letter for KEY WORD
	-- using Table.Column names instead of * to call required columns
	-- using alias for information hiding and time saving on query typing

	*/

SELECT CA.Added_to_salesforce AS AutomatedCar_Salesforce, CA.Description AS Description FROM [training-test].[dbo].[CAR_Automation] as CA;

SELECT DISTINCT CA.Processes_Affected AS Process_List, CA.Internal_External AS Type FROM [training-test].[dbo].[CAR_Automation] as CA;

SELECT COUNT (DISTINCT Incident_Cause) AS "Number of Incident Causes"
FROM [training-test].[dbo].[CAR_Automation] as CA;

SELECT CA.Added_to_salesforce AS AutomatedCar_Salesforce, CA.Description AS Description 
FROM [training-test].[dbo].[CAR_Automation] as CA
WHERE CA.Internal_External = 'Internally';				-- maintain the alias consistency; Boolean Operators : = ; <> ; > ; < ; >= ; <=

SELECT CA.Added_to_salesforce AS AutomatedCar_Salesforce, CA.Description AS Descriptio 
FROM [training-test].[dbo].[CAR_Automation] as CA
WHERE CA.Internal_External = 'Externally' AND CA.Review_Date >= '01/03/2020';				-- use AND, OR as mulpitle expressions Operators 

-- ATTEMPT WITH ADDITIONAL OPERATORS: BETWEEN, LIKE, IN, IS, ISNOT
SELECT CA.Car_Number_Historical AS Car_nbr, CA.Description AS Description, CA.Incident_Cause as Cause
FROM [training-test].[dbo].[CAR_Automation] as CA
WHERE CA.Submitted_By= 'Megan Dobey' AND CA.Car_Number_Historical BETWEEN '00060' AND '0080';	-- BETWEEN OPERATOR

GO

SELECT CA.Submitted_By AS SubBy ,Car_Number_Historical AS Car_nbr, CA.Description AS Description, CA.Incident_Cause as Cause
FROM [training-test].[dbo].[CAR_Automation] as CA
WHERE CA.Submitted_By LIKE '%U%';		-- LIKE OPERATOR

GO

SELECT CA.Car_Number_Historical AS Car_nbr, CA.Description AS Descrption, CA.Incident_Cause as Cause, CA.Processes_Affected AS Processes
FROM [training-test].[dbo].[CAR_Automation] as CA
WHERE CA.Processes_Affected IN ('RPA/Digital Services', 'Scanning', 'Security');		--	IN OPERATOR / Can do the opposite query with NOT IN

GO
/* example of query with IN operator crossing 2 related tables
SELECT * FROM Customers
WHERE Country IN (SELECT Country FROM Suppliers); -- This query selects all customers that are from the same countries as the suppliers:

*/


SELECT CA.Car_Number_Historical AS Car_nbr, CA.Description AS Descrption, CA.Incident_Cause as Cause, CA.Processes_Affected AS Processes
FROM [training-test].[dbo].[CAR_Automation] as CA
WHERE CA.[Case_Number] IS NULL;   -- OR IS NOT NULL; 

