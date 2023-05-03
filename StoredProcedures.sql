-- SET STATISTICS IO  ON
-- SET NO COUNT ON 

/* STORED PROCEDURES */
USE Contacts

GO

CREATE PROCEDURE dbo.SelectAllContacts		-- create procedure // here the procedure it has no parameter
AS
BEGIN;

SELECT * FROM dbo.Contacts;

END;

GO

CREATE PROCEDURE dbo.SelectGraceContact		-- create procedure // here the procedure it has no parameter
AS
BEGIN;

SELECT * FROM dbo.Contacts WHERE FirstName = 'Grace';

END;

GO


EXEC dbo.SelectGraceContact		-- execute the procedutre statement
GO

DROP PROCEDURE IF EXISTS dbo.SelectGraceContact -- drop the procedure // IF EXISTS procedures can be found in sys.procedures
GO

-- OR

IF EXISTS(SELECT 1 FROM sys.procedures WHERE [name] = 'SelectGraceContact')
 BEGIN;
	DROP PROCEDURE dbo.SelectContacts;
 END;

GO


/* PARAMETERLESS PROCEDURES */
DROP PROCEDURE IF EXISTS InsertContact;
GO

CREATE PROCEDURE dbo.InsertContact
AS
BEGIN;
-- Parameters (optional)
DECLARE @FirstName				VARCHAR(40),	-- DataType in line with the table 
		@LastName				VARCHAR(40),
		@DateOfBirth			DATE,
		@AllowContactByPhone	BIT;
--	Write Procedure Statement from HERE till END
SELECT	@FirstName = 'Stan',
		@LastName = 'Laurel',
		@DateOfBirth = '1890-06-16',
		@AllowContactByPhone = 0;

INSERT INTO dbo.Contacts
	(FirstName, LastName, DateOfBirth, AllowContactByPhone)
VALUES
	(@FirstName, @LastName, @DateOfBirth, @AllowContactByPhone);

END;

GO

-- Make use of the procedure
EXECUTE dbo.InsertContact;
EXECUTE dbo.SelectAllContacts;

Go


/* PARAMETERED PROCEDURES */

DROP PROCEDURE IF EXISTS InsertContact;
GO

CREATE PROCEDURE dbo.InsertContact
(	-- declare parameters before the statement
@FirstName		VARCHAR(40),	-- datatype must match column datatype
@LastName		VARCHAR(40),
@DateOfBirth	DATE,			-- can use 'DATE = NULL' or a default value if needed
@AllowContactByPhone	BIT
)
AS
BEGIN;	-- feed the statement with the declared paramters
	INSERT INTO dbo.Contacts
		(FirstName, LastName, DateOfBirth, AllowContactByPhone)
		VALUES
			(@FirstName, @LastName, @DateOfBirth, @AllowContactByPhone);

END;
GO

EXECUTE dbo.InsertContact
	@FirstName	= 'Lucie', 
	@LastName	= 'Schwartz', 
	@DateOfBirth	= '1911-07-14', 
	@AllowContactByPhone	= 0;


EXECUTE dbo.SelectAllContacts; -- test parametised insert


/* PARAMETERED PROCEDURES GLOBAL VARIABLE SCOPE_IDENTITY */
-- SCOPE_IDENTITY and @@IDENTITY return the last identity values that are generated in any table in the current session. However, SCOPE_IDENTITY returns values inserted only within the current scope; @@IDENTITY is not limited to a specific scope. */

DROP PROCEDURE IF EXISTS InsertContact;
GO

CREATE PROCEDURE dbo.InsertContact
(	-- declare parameters before the statement
@FirstName		VARCHAR(40),	-- datatype must match column datatype
@LastName		VARCHAR(40),
@DateOfBirth	DATE,			-- can use 'DATE = NULL' or a default value if needed
@AllowContactByPhone	BIT
)
AS
BEGIN;	-- feed the statement witht the declared paramters
	DECLARE @ContactID INT;
	
	INSERT INTO dbo.Contacts	-- subtask1_INSERT NEW RECORD
		(FirstName, LastName, DateOfBirth, AllowContactByPhone)
		VALUES
			(@FirstName, @LastName, @DateOfBirth, @AllowContactByPhone);

	SELECT @ContactID = SCOPE_IDENTITY();	-- subtask2_RETURNS THE LAST IDENTITY VALUE INSERTED INTO THE IDENTITY COLUMN (dbo.Contacts.ContactID) IN THE SAME SCOPE
	SELECT ContactId, FirstName, LastName, DateOfBirth, AllowContactByPhone	-- subtask3_DISPLAY NEWLY INSERTED DATA
	FROM dbo.Contacts
	WHERE ContactId = @ContactId;

END;
GO

EXECUTE dbo.InsertContact
	@FirstName	= 'Jamy', 
	@LastName	= 'McDonadol', 
	@DateOfBirth	= '1920-08-20', 
	@AllowContactByPhone	= 1;


EXECUTE dbo.SelectAllContacts; -- test parametised insert

/* PARAMETERED PROCEDURES WITH OUTPUT PARAMETERS */
-- Output parameter is a parameter whose value is passed out of the stored procedure/function module, back to the calling PL/SQL block. */

DROP PROCEDURE IF EXISTS InsertContact;
GO

CREATE PROCEDURE dbo.InsertContact
(	
@FirstName		VARCHAR(40),	
@LastName		VARCHAR(40),
@DateOfBirth	DATE,
@AllowContactByPhone	BIT,
@ContactID		INT	OUTPUT		-- OUTPUT parameters allow the stored procedure to pass values back to the caller //  instructing SQL Server to capture the output value from the stored procedure execution and store it in the @ContactIdOut variable declared and called bellow, at execution
)
AS
BEGIN;	
	SET NOCOUNT ON;		--  prevents the sending of DONEINPROC messages to the client for each statement in a stored procedure
	
	INSERT INTO dbo.Contacts	-- subtask1_INSERT NEW RECORD
		(FirstName, LastName, DateOfBirth, AllowContactByPhone)
		VALUES
			(@FirstName, @LastName, @DateOfBirth, @AllowContactByPhone);

	SELECT @ContactId = SCOPE_IDENTITY();	-- subtask2__RETURNS THE LAST IDENTITY VALUE INSERTED INTO THE IDENTITY COLUMN (dbo.Contacts.ContactID) to pass out to
	SELECT ContactId, FirstName, LastName, DateOfBirth, AllowContactByPhone	-- subtask3_DISPLAY NEWLY INSERTED DATA
	FROM dbo.Contacts
	WHERE ContactId = @ContactId;

	SET NOCOUNT OFF;
END;
GO


DECLARE @ContactIdOut INT;	-- of same datatype as the OUTPUT Parameter

EXECUTE dbo.InsertContact
	@FirstName	= 'Bobby', 
	@LastName	= 'Smith', 
	@DateOfBirth	= '1989-07-20', 
	@AllowContactByPhone	= 1,
	@ContactId = @ContactIdOut OUTPUT; -- allow the new Identity Variable Captured by the execution to be passed out to the caller	

EXECUTE dbo.SelectAllContacts; -- test parametised insert

GO



/* CALLING PROCEDURE FROM ANOTHER PROCEDURE */ 

--  PROCEDURE 1, REFERRED PROCEDURE TO CALL
DROP PROCEDURE IF EXISTS dbo.SelectContact;
GO

CREATE PROCEDURE dbo.SelectContact
(
@IdSelectedContact INT
)
AS	
BEGIN;
	SET NOCOUNT ON;
	
	SELECT
		FirstName	AS	[First Name],
		LastName	AS	[Last Name],
		DateOfBirth	AS	[Date of Birth],
		AllowContactByPhone	[Allow Contact By Phone], 
		CreatedDate	AS	[Creation Date]		-- Can comment any line to hide any unwanted column fromt the select statement
	FROM dbo.Contacts
	WHERE ContactId = @IdSelectedContact;
	SET NOCOUNT OFF;
END;
GO

-- PROCEDURE 2, REFERRING PROCEDURE CALLING PROCEDURE 1
DROP PROCEDURE IF EXISTS dbo.InsertContact2 
GO

CREATE PROCEDURE dbo.InsertContact2
(
 @FirstName				VARCHAR(40),
 @LastName				VARCHAR(40),
 @DateOfBirth			DATE = NULL,
 @AllowContactByPhone	BIT,
 @ContactId				INT OUTPUT
)
AS
BEGIN;
	SET NOCOUNT ON;

	INSERT INTO dbo.Contacts	-- subtask1_populate the table dbo.Contacts with new INPUTS parameters from the stored procedure call
		(FirstName, LastName, DateOfBirth, AllowContactByPhone)
	VALUES
		(@FirstName, @LastName, @DateOfBirth, @AllowContactByPhone);

	SELECT @ContactId = SCOPE_IDENTITY();	-- subtask2_retrieve the newly inserted Identity value in the column ContactId within this scope
	EXEC dbo.SelectContact @IdSelectedContact = @ContactId;	-- subtask3_the referred procedure call the OUTPUT VARIABLE taht was captured to exeute the SELECT Statement, to display the newly inserted value. 

	SET NOCOUNT OFF;

END;
GO

-- EXECUTING THE STORED PROCEDURE2 TO INSERT NEW RECORDS
DECLARE @ContactIdOut INT;	-- of same datatype as the OUTPUT Parameter

EXECUTE dbo.InsertContact2
	@FirstName	= 'Braley', 
	@LastName	= 'Cooper', 
	@DateOfBirth	= '1970-06-16', 
	@AllowContactByPhone	= 1,
	@ContactId = @ContactIdOut OUTPUT; -- allow the new Identity Variable Captured by the execution to be passed out to the caller	

GO


-- INSERTING A BUSINESS LOGIC IN THE REFERING PROCEDURE to check if a the new record to add already exist in the table
-- (1) Complex Approach with the referral procedure. 

DROP PROCEDURE IF EXISTS dbo.InsertContactCplx
GO

CREATE PROCEDURE dbo.InsertContactCplx
(
 @FirstName				VARCHAR(40),
 @LastName				VARCHAR(40),
 @DateOfBirth			DATE = NULL,
 @AllowContactByPhone	BIT,
 @ContactId				INT OUTPUT
)
AS
BEGIN;
	SET NOCOUNT ON;

	DECLARE @ExistingContactId INT;	


	SELECT -- subtask1_Check if a record already exists with the given first name, last name and birthdate
		@ExistingContactId = @ContactId 
	FROM dbo.contacts
	WHERE FirstName = @FirstName AND LastName = @LastName AND ((DateOfBirth IS NULL AND @DateOfBirth IS NULL) OR (DateOfBirth = @DateOfBirth));


	-- subtask2_BUSINESS LOGIC_insert the new record and return the identity value
	IF @ExistingContactId IS NULL -- If no record exists, 
	BEGIN	
		INSERT INTO dbo.Contacts
		(
		FirstName, 
		LastName, 
		DateOfBirth, 
		AllowContactByPhone
		)
		VALUES
		(
		@FirstName, 
		@LastName, 
		@DateOfBirth, 
		@AllowContactByPhone
		);

		SET @ContactId = SCOPE_IDENTITY();	-- Collect the Newly inserted records Identity value
	END

	ELSE -- If a record already exists, set the @ContactId output parameter to the existing contact ID
	BEGIN
		SET @ContactId = @ExistingContactId;
	END


	EXEC dbo.SelectContact @IdSelectedContact = @ContactId;	-- subtask3_Display the newly inserted or existing contact details


	SET NOCOUNT OFF;
END;
GO

-- EXECUTING Complex Procedure
DECLARE @ContactIdOut INT;	-- of same datatype as the OUTPUT Parameter

EXECUTE dbo.InsertContactCplx
	@FirstName	= 'Harrick', 
	@LastName	= 'Potery', 
	@DateOfBirth	= '1890-08-28', 
	@AllowContactByPhone	= 0,
	@ContactId = @ContactIdOut OUTPUT; -- allow the new Identity Variable Captured by the execution to be passed out to the caller	

GO


-- (2) simpler method with the referral procedure
DROP PROCEDURE IF EXISTS dbo.InsertContactSmpl
GO

CREATE PROCEDURE dbo.InsertContactSmpl
(
    @FirstName				VARCHAR(40),
    @LastName				VARCHAR(40),
    @DateOfBirth			DATE = NULL,
    @AllowContactByPhone	BIT,
    @ContactId				INT OUTPUT
)
AS
BEGIN;

    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM dbo.Contacts
                WHERE FirstName = @FirstName AND LastName = @LastName
                    AND ((DateOfBirth IS NULL AND @DateOfBirth IS NULL)
                            OR (DateOfBirth = @DateOfBirth)))
    BEGIN
        RAISERROR('The contact already exists.', 16, 1);
        RETURN;
    END;

    INSERT INTO dbo.Contacts
        (FirstName, LastName, DateOfBirth, AllowContactByPhone)
    VALUES
        (@FirstName, @LastName, @DateOfBirth, @AllowContactByPhone);

    SELECT @ContactId = SCOPE_IDENTITY();

    EXEC dbo.SelectContact @IdSelectedContact = @ContactId;

    SET NOCOUNT OFF;

END;
GO

-- Executing Simpler Procedure with already existing records
DECLARE @ContactIdOut INT;	-- of same datatype as the OUTPUT Parameter

EXECUTE dbo.InsertContactSmpl
	@FirstName	= 'Braley', 
	@LastName	= 'Cooper', 
	@DateOfBirth	= '1970-06-16', 
	@AllowContactByPhone	= 1,
	@ContactId = @ContactIdOut OUTPUT; -- allow the new Identity Variable Captured by the execution to be passed out to the caller	

GO


/* EXAMPLE OF TRY CATCH FOR ERROR HANDLING IN A PROCEDURE */

USE Contacts;

DROP PROCEDURE IF EXISTS dbo.InsertContactRole;

GO

CREATE PROCEDURE dbo.InsertContactRole
(
 @ContactId	INT,
 @RoleTitle	VARCHAR(200)
)
AS
BEGIN;

DECLARE @RoleId		INT;
		
BEGIN TRY;		--	Begin the code to watch here, and close with 'End Try'

BEGIN TRANSACTION;		--	transaction block access to the table whilst they update records and should be closed asap transcation done

	IF NOT EXISTS(SELECT 1 FROM dbo.Roles WHERE RoleTitle = @RoleTitle)		-- IF NOT EXISTS avoid the ELSE IF
	 BEGIN;
		INSERT INTO dbo.Roles (RoleTitle)
			VALUES (@RoleTitle);
	 END;

	SELECT @RoleId = RoleId FROM dbo.Roles WHERE RoleTitle = @RoleTitle;

	IF NOT EXISTS(SELECT 1 FROM dbo.ContactRoles WHERE ContactId = @ContactId AND RoleId = @RoleId)
	 BEGIN;
		INSERT INTO dbo.ContactRoles (ContactId, RoleId)
			VALUES (@ContactId, @RoleId);
	 END;

COMMIT TRANSACTION;		-- After statements are written, the transaction is commited. // (BEGIN/END) either all of the statements within the transaction are executed successfully, or none of them are executed at all.
	
SELECT	C.ContactId, C.FirstName, C.LastName, R.RoleTitle
	FROM dbo.Contacts C
		INNER JOIN dbo.ContactRoles CR
			ON C.ContactId = CR.ContactId
		INNER JOIN dbo.Roles R
			ON CR.RoleId = R.RoleId
WHERE C.ContactId = @ContactId;

END TRY		--	Close the Begin try here

BEGIN CATCH;
	IF (@@TRANCOUNT > 0)	-- check if transaction opened, it relates to the begin transaction
	 BEGIN;
		ROLLBACK TRANSACTION;	-- reset the changes implemented by the code with the transaction to the last savepoint //  If an error occurs, the transaction is rolled back and any changes made within the transaction (BEGIN/END) are undone.
	 END;
	PRINT 'Error occurred in ' + ERROR_PROCEDURE() + ' ' + ERROR_MESSAGE();		-- Print the error that were catched // ERROR_PROC returnrs the error on procedure and trigger // ERROR_MSG returns the error the caused the cath block
	RETURN -1;		-- return code to know the state of the procecedure (@RetVal= -1 for error, @RetVal= 0 for successful transaction)
END CATCH;

RETURN 0;

END;

-- PROCEDURE EXECUTION WITH RETURN CODE
DECLARE @RetVal INT;

EXEC	@RetVal = dbo.InsertContactRole 
		@ContactId = 22,
		@RoleTitle = 'Actor';

PRINT 'RetVal = ' + CONVERT(VARCHAR(10), @RetVal);


/*improved version */
/* EXAMPLE OF TRY CATCH FOR ERROR HANDLING IN A PROCEDURE */

USE Contacts;

DROP PROCEDURE IF EXISTS dbo.InsertContactRole;

GO

CREATE PROCEDURE dbo.InsertContactRole
(
    @ContactId  INT,
    @RoleTitle  VARCHAR(200)
)
AS
BEGIN
    -- Declare local variables
    DECLARE @RoleId     INT;
    DECLARE @RetVal     INT;

    -- Begin the try-catch block to handle errors
    BEGIN TRY

        BEGIN TRANSACTION;  -- Begin transaction block to ensure atomicity of operations

        -- Check if role exists; if not, insert it
        IF NOT EXISTS(SELECT 1 FROM dbo.Roles WHERE RoleTitle = @RoleTitle)
        BEGIN
            INSERT INTO dbo.Roles (RoleTitle)
            VALUES (@RoleTitle);
        END;

        -- Retrieve role ID
        SELECT @RoleId = RoleId FROM dbo.Roles WHERE RoleTitle = @RoleTitle;

        -- Check if contact already has the role; if not, assign it
        IF NOT EXISTS(SELECT 1 FROM dbo.ContactRoles WHERE ContactId = @ContactId AND RoleId = @RoleId)
        BEGIN
            INSERT INTO dbo.ContactRoles (ContactId, RoleId)
            VALUES (@ContactId, @RoleId);
        END;

        -- Commit transaction
        COMMIT TRANSACTION;	

        -- Retrieve contact details with assigned role
        SELECT C.ContactId, C.FirstName, C.LastName, R.RoleTitle
        FROM dbo.Contacts C
        INNER JOIN dbo.ContactRoles CR
            ON C.ContactId = CR.ContactId
        INNER JOIN dbo.Roles R
            ON CR.RoleId = R.RoleId
        WHERE C.ContactId = @ContactId;

        -- Set return value to success
        SET @RetVal = 0;

    END TRY -- End of try block

    -- Handle any errors caught during execution
    BEGIN CATCH

        IF (@@TRANCOUNT > 0)  -- Check if a transaction was started and roll it back if necessary
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        -- Print the error message
        PRINT 'Error occurred in ' + ERROR_PROCEDURE() + ': ' + ERROR_MESSAGE();

        -- Set return value to indicate failure
        SET @RetVal = -1;

    END CATCH; -- End of catch block

    -- Return the appropriate value depending on the outcome of the procedure
    RETURN @RetVal;

END;


-- execution

DECLARE @RetVal INT;

EXEC	@RetVal = dbo.InsertContactRole 
		@ContactId = 22,
		@RoleTitle = 'Actor';

PRINT 'RetVal = ' + CONVERT(VARCHAR(10), @RetVal);
