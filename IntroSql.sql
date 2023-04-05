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

SELECT CA.Added_to_salesforce AS AutomatedCar_Salesforce, CA.Description AS Description 
FROM [training-test].[dbo].[CAR_Automation] as CA
WHERE CA.Internal_External = 'Externally' AND CA.Review_Date >= '01/03/2020';				-- use AND, OR as mulpitle expressions Operators 

