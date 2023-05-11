USE Contacts
GO
/* TRIGGERS */

/* AFTER INSERT TRIGGERS */

-- PREVENT INCORRECT DATA FROM BEING INSERTED BASED ON BUSINESS CONSTRAINTS

-- sample insert trigger  1
CREATE OR ALTER TRIGGER TI_ContactNotes
	ON dbo.ContactNotes AFTER INSERT
	AS 
	BEGIN
		-- Check count of rows modified from calling INSERT action on dbo.ContactNotes
		IF (ROWCOUNT_BIG()=0)
			RETURN;
		-- Do not print any result detail from trigger
		SET NOCOUNT ON;
		-- In the case of a MERGE statement, the ROWCOUNT_BIG will return the rowcount of all INSERT, UPDATE, and DELETE actions, not just the INSERT count
		IF NOT EXISTS (SELECT 1 FROM inserted)
			RETURN;
		
		RAISERROR('The TI_ContactNotes was fired', 1,1);
	END;
GO

-- inserting a value on conflicting foreign key constraint to verify no trigger get called for deadend action
INSERT INTO dbo.ContactNotes 
	(ContactId, Notes)
VALUES
	(0, 'Follow these instructions to download, install, and configure the WideWorldImportersDW sample database with SQL Server Management Studio.');

GO
 

-- sample insert trigger  2
-- Checking the contraint [AllowContactByPhone] is TRUE // ON TABLE JOIN
CREATE OR ALTER TRIGGER TI_Contacts
	ON [Contacts].[dbo].[Contacts] AFTER INSERT
	AS 
	BEGIN
		IF (ROWCOUNT_BIG()=0)
			RETURN;

		SET NOCOUNT ON;

		IF NOT EXISTS (SELECT 1 FROM inserted)	-- this statement further checks the merge which returns a count of all rows modified
			RETURN;

		-- Is this contact allow contact by phone?	// With table join
		IF EXISTS
		(
			SELECT 1 FROM inserted i	--  'inserted' is the virtual table, which contains the newly inserted rows, with the dbo.Contacts table on the ContactId column.
				INNER JOIN dbo.Contacts c ON i.ContactId = c.ContactId
			WHERE c.AllowContactByPhone = 0
		)
		BEGIN
			RAISERROR('Contact cannot be inserted it does not allow phone calls.', 16,1);
			ROLLBACK TRANSACTION;		-- if only ONE contact in the whole transaction does not allow phone calls, all the transaction is rolled back
			RETURN;
		END;

	END;
GO


CREATE OR ALTER VIEW VW_VerifiedContact
	AS
	SELECT
		c.ContactId,
		c.FirstName,
		c.LastName,
		c.DateOfBirth,
		c.AllowContactByPhone,
		cvd.ContactVerified,
		cpn.PhoneNumberTypeId
	FROM dbo.Contacts c 
		INNER JOIN dbo.ContactVerificationDetails cvd 
			ON c.ContactId = cvd.ContactId
		INNER JOIN dbo.ContactPhoneNumbers cpn
			ON c.ContactId = cpn.ContactId
GO	


-- sample insert trigger  3
-- Checking two contraints when inserting a new contact on the [PhoneNumberTypeId] and [ContactVerified] // ON TABLE JOIN

 DELETE FROM [Contacts].[dbo].[Contacts] where ContactId between 166 and 180;
 GO

UPDATE [Contacts].[dbo].[Contacts] SET AllowContactByPhone = 0 WHERE ContactId = 26;

UPDATE [Contacts].[dbo].ContactVerificationDetails SET ContactVerified = 1 WHERE ContactId = 7;

UPDATE [Contacts].[dbo].ContactPhoneNumbers SET PhoneNumberTypeId = 1 WHERE ContactId = 7;

GO

INSERT INTO dbo.Contacts 
	(FirstName, LastName, DateOfBirth, AllowContactByPhone)
VALUES
	('Josephine', 'Bailey', '1949-05-31', 1);
		
GO

INSERT INTO dbo.Contacts 
	(FirstName, LastName, DateOfBirth, AllowContactByPhone)
VALUES
	('Richard', 'Adams', '1920-05-09', 0);
GO	

CREATE OR ALTER TRIGGER TI_VerifiedContacts
	ON dbo.Contacts AFTER INSERT
	AS 
	BEGIN
		IF (ROWCOUNT_BIG() = 0)
			RETURN;

		SET NOCOUNT ON;

		IF NOT EXISTS (SELECT 1 FROM inserted)
			RETURN;

		-- Check if any inserted contacts have been verified
		IF EXISTS 
		(
			SELECT 1 
			FROM inserted i
				LEFT JOIN dbo.Contacts c on i.ContactId = c.ContactId
				LEFT JOIN dbo.ContactVerificationDetails cvd ON i.ContactId = cvd.ContactId
			WHERE cvd.ContactVerified = 0 OR cvd.ContactVerified IS NULL 
		)
		BEGIN
			PRINT 'Contact has not been verified, yet..';
			RAISERROR('Contact has not been verified, yet..', 16, 1);
			ROLLBACK TRANSACTION;
			RETURN;
		END;

	END;
GO


/* test of double verification*/
-- there is an isseu with RAISERROR function to allow the second condition to prompt its response

CREATE OR ALTER TRIGGER TI_VerifiedContacts
	ON dbo.Contacts AFTER INSERT
	AS 
	BEGIN
		IF (ROWCOUNT_BIG() = 0)
			RETURN;

		SET NOCOUNT ON;

		IF NOT EXISTS (SELECT 1 FROM inserted)
			RETURN;

		-- Check if any inserted contacts have been verified
		IF EXISTS (
			SELECT 1 
			FROM inserted i
			LEFT JOIN dbo.ContactVerificationDetails cvd ON i.ContactId = cvd.ContactId
			WHERE cvd.ContactVerified IS NULL OR cvd.ContactVerified = 0
		)
		BEGIN
			PRINT 'Contact has not been verified, yet..';
			RAISERROR('Contact has not been verified, yet..', 16, 1);
			ROLLBACK TRANSACTION;
			RETURN;
		END;

		-- Check if any inserted contacts have a mobile phone number
		IF EXISTS (
			SELECT 1
			FROM inserted i
			LEFT JOIN dbo.ContactPhoneNumbers cpn ON i.ContactId = cpn.ContactId --AND cpn.PhoneNumberTypeId <> 3
			WHERE cpn.PhoneNumberId IS NULL OR cpn.PhoneNumberTypeId <>3
		)
		BEGIN
			PRINT 'Contact does not have a mobile phone number.';
			RAISERROR('Contact does not have a mobile phone number.', 16, 2);
			ROLLBACK TRANSACTION;
			RETURN;
		END;
	END;
GO

----- there is an issue with RAISERROR function to allow the second condition to prompt its response -----
CREATE OR ALTER TRIGGER TI_VerifiedContacts
    ON dbo.Contacts AFTER INSERT
AS 
BEGIN
    IF (ROWCOUNT_BIG() = 0)
        RETURN;

    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM inserted)
        RETURN;

    -- Check if any inserted contacts have not been verified
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        LEFT JOIN dbo.ContactVerificationDetails cvd ON i.ContactId = cvd.ContactId
        WHERE cvd.ContactVerified IS NULL OR cvd.ContactVerified = 0
    )
    BEGIN
        PRINT 'Contact has not been verified, yet..';
        RAISERROR('Contact has not been verified, yet..', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    -- Check if any inserted contacts do not have a mobile phone number or have not been verified yet
    IF EXISTS (
        SELECT 1
        FROM inserted i
        LEFT JOIN dbo.ContactPhoneNumbers cpn ON i.ContactId = cpn.ContactId 
        WHERE cpn.PhoneNumberId IS NULL AND cpn.PhoneNumberTypeId <> 3
            AND NOT EXISTS (
                SELECT 1 
                FROM dbo.ContactVerificationDetails cvd 
                WHERE cvd.ContactId = i.ContactId AND cvd.ContactVerified = 1
            )
    )
    BEGIN
        PRINT 'Contact does not have a mobile phone number or has not been verified.';
        RAISERROR('Contact does not have a mobile phone number or has not been verified.', 16, 2);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;
GO

/* AFTER INSERT TRIGGERS */
-- AFTER INSERT TRIGGER FOR LOG EVENT
	-- this trigger use an UPSERT like behavior which means when you want to perform an INSERT operation, but if a matching record already exists, you want to UPDATE it instead.
CREATE OR ALTER TRIGGER TI_Contacts_ContactVerificationDetails_After
	ON dbo.ContactPhoneNumbers AFTER INSERT
	AS 
	BEGIN
		IF (ROWCOUNT_BIG()=0)
			RETURN;

		SET NOCOUNT ON;

		IF NOT EXISTS (SELECT 1 FROM inserted)	
			RETURN;

		IF EXISTS (SELECT 1 FROM inserted i)
		-- Create an id variable collect the Id value from the ContactPhoneNumbers replicated in the virtual 'inserted' table 

		DECLARE @Id int		
		SELECT @Id = i.ContactId FROM inserted i		
		
		-- insert the log message in the Audit Table
		BEGIN	
			INSERT INTO dbo.ContactAudit (AuditData)
			VALUES('New contact with Id = ' + CAST(@Id AS nvarchar(5)) + ' was inserted at ' + CAST (GETDATE() AS nvarchar(20)))
		END
				
	END
GO

INSERT INTO dbo.ContactPhoneNumbers
	([ContactId], [PhoneNumberTypeId], [PhoneNumber])
VALUES
	(22, 3, 074487562132)

SELECT * FROM dbo.ContactPhoneNumbers
SELECT * FROM dbo.ContactAudit
GO


/* AFTER DELETE TRIGGER FOR LOG EVENT */

CREATE OR ALTER TRIGGER TD_Contacts_ContactVerificationDetails_After
	ON dbo.ContactPhoneNumbers AFTER DELETE
	AS 
	BEGIN
		IF (ROWCOUNT_BIG()=0)
			RETURN;

		SET NOCOUNT ON;

		IF NOT EXISTS (SELECT 1 FROM deleted)	-- the virtual table for AFTER DELETE TRIGGERS
			RETURN;

		IF EXISTS (SELECT 1 FROM deleted d)	
		-- this id variable collect the Id value from the ContactPhoneNumbers replicated in the virtual 'inserted' table 
		DECLARE @Id int		
		SELECT @Id = d.ContactId FROM deleted d

		-- Log the deletion event in the Audit table
		BEGIN
			INSERT INTO dbo.ContactAudit (AuditData)
			VALUES('A contact with Id = ' + CAST(@Id AS nvarchar(5)) + ' was deleted at ' + CAST (GETDATE() AS nvarchar(20)))
		END
	END
GO

--	delete the selected row from the ContactPhoneNumbers table
DELETE FROM dbo.ContactPhoneNumbers WHERE ContactId = 21
GO

SELECT * FROM dbo.ContactPhoneNumbers
SELECT * FROM dbo.ContactAudit
GO


/* AFTER UPDATE TRIGGER FOR LOG EVENT */

-- The modifier called EXCEP, make sure the data collected in the Inserted Table are differeent from the value passed out to Deleted Table to ensure I will only get data returned that actually had changes for effective information logging and not just resetted data
-- once data obtained, the changed data is logged to the AuditTable and selecting them out as a JSON document

CREATE OR ALTER TRIGGER TU_Contacts_ContactAddresses_Update
	ON dbo.ContactAddresses AFTER UPDATE
	AS 
	BEGIN
		IF (ROWCOUNT_BIG() = 0)
			RETURN;

		SET NOCOUNT ON;

		IF NOT EXISTS (SELECT 1 FROM deleted)
			RETURN;

		SELECT *
		INTO #ModifiedData
		FROM
		(
			SELECT * FROM inserted i -- deleted d
			EXCEPT	 
			SELECT * FROM deleted d	-- inserted i
		) ModifiedData;

		-- Log the update event in the Audit table
		BEGIN
			INSERT INTO dbo.ContactAudit (AuditData)
			SELECT 'Contact with Id = ' + CAST(m.ContactId AS NVARCHAR(5)) + ' was updated at ' + CAST(GETDATE() AS NVARCHAR(20)) + ' to house number: ' + m.HouseNumber + ' and Postcode ' + m.Postcode + '.'
			FROM #ModifiedData m;
		END;
	END;
GO


UPDATE dbo.ContactAddresses 
	SET HouseNumber =  '17 Butterfly Street', Street = 'Odd Road',	City = 'Falkirk', Postcode = 'G54 7AS'
	WHERE ContactId = 21;

SELECT * FROM dbo.ContactAudit
SELECT * FROM dbo.ContactAddresses



-- Advanced Version of	AFTER UPDATE TRIGGER with VIEWS
		-- In this case a subquery can be used but, VIEWS ARE KNOWN TO BE FASTER IN DML TRIGGERS
CREATE OR ALTER TRIGGER TU_Contacts_ContactAddresses_Update
	ON dbo.ContactAddresses AFTER UPDATE
	AS 
	BEGIN
		IF (ROWCOUNT_BIG() = 0)
			RETURN;

		SET NOCOUNT ON;

		IF NOT EXISTS (SELECT 1 FROM deleted)
			RETURN;

		-- Create a temporary table to store the modified data
		CREATE TABLE #ModifiedData (
			[AddressId] INT,
			[ContactId] INT,
			[HouseNumber] VARCHAR(50),
			[Street] VARCHAR(100),
			[City] VARCHAR(100),
			[Postcode] VARCHAR(50)
		);

		-- Insert the modified data into the temporary table
		INSERT INTO #ModifiedData
		SELECT i.*
		FROM deleted d
		INNER JOIN inserted i ON d.[AddressId] = i.[AddressId]
		WHERE EXISTS (
			SELECT 1
			FROM dbo.ContactAddresses c
			WHERE c.[AddressId] = d.[AddressId]
			  AND (
				   c.[HouseNumber] <> d.[HouseNumber]
			    OR c.[Street] <> d.[Street]
			    OR c.[City] <> d.[City]
			    OR c.[Postcode] <> d.[Postcode]
			  )
		);

		-- Check if any modified rows exist
		IF EXISTS (SELECT 1 FROM #ModifiedData)
		BEGIN
			DECLARE @Id INT = (SELECT ContactId FROM #ModifiedData);
			DECLARE @HouseNumber VARCHAR(50) = (SELECT HouseNumber FROM #ModifiedData);
			DECLARE @Postcode VARCHAR(50) = (SELECT Postcode FROM #ModifiedData);

			DECLARE @Old_H_Nber VARCHAR(50) = (SELECT HouseNumber FROM deleted);	-- old house number
			DECLARE @Old_P_Code VARCHAR(50) = (SELECT Postcode FROM deleted);		-- old post code

			-- Log the update event in the Audit table
			INSERT INTO dbo.ContactAudit (AuditData)
			VALUES ('Contact with Id = ' + CAST(@Id AS NVARCHAR(5)) + ' was updated at ' + CAST(GETDATE() AS NVARCHAR(20)) + ' from old '+ @Old_H_Nber +' to new house number: ' + @HouseNumber + ' and from old ' + @Old_P_Code + ' to new postcode '+ @Postcode + '.');
		END;

		-- Drop the temporary table
		DROP TABLE #ModifiedData;
	END;
GO


/* INSTEAD OF TRIGGERS */

-- create the test view
CREATE OR ALTER VIEW VW_ContactRoles
	AS
	SELECT
		c.ContactId,
		c.FirstName,
		c.LastName,
		c.DateOfBirth,
		r.RoleTitle
	FROM dbo.Contacts c 
		INNER JOIN dbo.ContactRoles cr
			ON c.ContactId = cr.ContactId
		INNER JOIN dbo.Roles r
			ON cr.RoleId = r.RoleId
GO	

SELECT * FROM VW_ContactRoles
GO


-- InsteadOf Trigger to modify underlying tables of a View.
	-- here only the ROLE ID is mody in the base table to be reflected when the view is called
		-- so INSTEAD OF INSERTing a new record in the VIEW, the following trigger modify the base table

CREATE OR ALTER TRIGGER TI_Contacts_VW_ContactRoles_InsteadOf
    ON dbo.VW_ContactRoles
    INSTEAD OF INSERT
AS
BEGIN
    IF (ROWCOUNT_BIG() = 0)
        RETURN;

    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM inserted)
        RETURN;

    -- Check if the role title exists in the Roles table
		-- if the role to assign to the contact exist in the base table then proceed
    IF EXISTS
    (
        SELECT 1
        FROM inserted i
        LEFT JOIN dbo.Roles r ON i.RoleTitle = r.RoleTitle
        WHERE r.RoleId IS NULL
    )
    BEGIN
        RAISERROR('Invalid role title. ', 16, 1);
        RETURN;
    END;

    BEGIN
        -- Insert the new records into the ContactRoles table
			-- only RoleId get inserted in the base table, the following example modify the other records
        INSERT INTO dbo.ContactRoles (ContactId, RoleId)
        SELECT i.ContactId, r.RoleId
        FROM inserted i
        INNER JOIN dbo.Roles r ON i.RoleTitle = r.RoleTitle;
    END;


END;
GO

----- 
-- Update the base tables (Contacts, etc.) as needed ...

INSERT INTO dbo.VW_ContactRoles ([ContactId], [FirstName], [LastName], [DateOfBirth], [RoleTitle])
	VALUES(27,'Boris', 'Keillan', '2001-06-30', 'Developer')
	--WHERE ContactId = 4;


SELECT * FROM dbo.ContactRoles
SELECT * FROM dbo.ContactRoles
SELECT * FROM dbo.VW_ContactRoles

-----

-- InsteadOf Trigger to modify underlying tables of a View.
CREATE OR ALTER TRIGGER TI_Contacts_VW_ContactRoles_InsteadOf
    ON dbo.VW_ContactRoles
    INSTEAD OF INSERT
AS
BEGIN
    IF (ROWCOUNT_BIG() = 0)
        RETURN;

    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM inserted)
        RETURN;

    -- Check if the role title exists in the Roles table
    IF EXISTS
    (
        SELECT 1
        FROM inserted i
        LEFT JOIN dbo.Roles r ON i.RoleTitle = r.RoleTitle
        WHERE r.RoleId IS NULL
    )
    BEGIN
        RAISERROR('Invalid role title. ', 16, 1);
        RETURN;
    END;

    BEGIN
        -- Update the existing records in the Contacts table for each column of the View
        UPDATE c
        SET c.FirstName = i.FirstName,
            c.LastName = i.LastName,
            c.DateOfBirth = i.DateOfBirth
        FROM dbo.Contacts c
        INNER JOIN inserted i ON c.ContactId = i.ContactId;

        -- Insert the new records into the ContactRoles table
        INSERT INTO dbo.ContactRoles (ContactId, RoleId)
        SELECT i.ContactId, r.RoleId
        FROM inserted i
        INNER JOIN dbo.Roles r ON i.RoleTitle = r.RoleTitle;
    END;

END;
GO


-----
-- Instead Of Update Trigger to modify underlying tables of a View.
CREATE OR ALTER TRIGGER TU_Contacts_VW_ContactRoles_InsteadOf
    ON dbo.VW_ContactRoles
    INSTEAD OF UPDATE
AS
BEGIN
    IF (ROWCOUNT_BIG() = 0)
        RETURN;

    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM deleted)
        RETURN;

    -- Check if any of the relevant columns have changed
    IF EXISTS
    (
        SELECT 1
        FROM inserted i
        INNER JOIN deleted d ON i.ContactId = d.ContactId
        WHERE i.FirstName <> d.FirstName OR
              i.LastName <> d.LastName OR
              i.DateOfBirth <> d.DateOfBirth OR
              i.RoleTitle <> d.RoleTitle
    )
    BEGIN
        -- Check if the role title exists in the Roles table
        IF EXISTS
        (
            SELECT 1
            FROM inserted i
            LEFT JOIN dbo.Roles r ON i.RoleTitle = r.RoleTitle
            WHERE r.RoleId IS NULL
        )
        BEGIN
            RAISERROR('Invalid role title. ', 16, 1);
            RETURN;
        END;

        BEGIN
            -- Update the existing records in the Contacts table
            UPDATE c
            SET c.FirstName = i.FirstName,
                c.LastName = i.LastName,
                c.DateOfBirth = i.DateOfBirth
            FROM dbo.Contacts c
            INNER JOIN inserted i ON c.ContactId = i.ContactId;

            -- Update the RoleId in the ContactRoles table
            UPDATE cr
            SET cr.RoleId = r.RoleId
            FROM dbo.ContactRoles cr
            INNER JOIN inserted i ON cr.ContactId = i.ContactId
            INNER JOIN dbo.Roles r ON i.RoleTitle = r.RoleTitle;
        END;
    END;
END;
GO

-- Instead Of Delete Trigger to modify underlying tables of a View.
CREATE OR ALTER TRIGGER TD_Contacts_VW_ContactRoles_InsteadOf
    ON dbo.VW_ContactRoles
    INSTEAD OF DELETE
AS
BEGIN
    IF (ROWCOUNT_BIG() = 0)
        RETURN;

    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM deleted)
        RETURN;

    BEGIN
        -- Delete the corresponding records from the ContactRoles table
        DELETE cr
        FROM dbo.ContactRoles cr
        INNER JOIN deleted d ON cr.ContactId = d.ContactId;

        -- Delete the corresponding records from the Contacts table
        DELETE c
        FROM dbo.Contacts c
        WHERE c.ContactId IN (SELECT ContactId FROM deleted);
    END;
END;
GO

DELETE FROM dbo.VW_ContactRoles WHERE ContactId=27;
GO

/* TRIGGERS ORDERS, APPLY TO AFTER TRIGGERS */
	-- If trigger recreated, order should be re-assigned 
 -- use the function SP_SETTRIGGERORDER, add the trigger name, its order and type(INSERT, UPDATE and DELETE)
sp_settriggerorder @triggername = '[dbo].[TI_VerifiedContacts]', @order = 'first', @stmttype = 'INSERT';
GO

sp_settriggerorder @triggername = '[Application].[TU_People_ChangeSalesPerson]', @order = 'last', @stmttype = 'UPDATE';
GO



/*ENABLE THE DEDICATED ADMINISTRATOR CONNECTION (DAC)*/
USE MASTER;
EXEC SP_CONFIGURE 'REMOTE ADMIN CONNECTIONS', 1;

RECONFIGURE
GO
