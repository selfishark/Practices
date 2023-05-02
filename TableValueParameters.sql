USE Contacts

/* TABLE VALUE PARAMETERS */
-- CREATING CUSTOM DATA TYPE AND USER DEFINED TABLES

-- Creating Alias from Primitive DataType
DROP TYPE IF EXISTS dbo.DrivingLicense
GO   

CREATE TYPE dbo.DrivingLicense
FROM VARCHAR (16) NOT NULL;  -- NOT NULL is optional // any value longer than 16chrs is cut-off 

GO

DECLARE @dvla dbo.DrivingLicense = 'TIENT98741UK176';
SELECT @dvla;

GO

-- User Defined Table 
DROP TYPE IF EXISTS dbo.ContactNote;
GO

CREATE TYPE dbo.ContactNote		-- this table type is created to pass tabular data to the stored procedure
AS TABLE
(
Note	VARCHAR(MAX) NOT NULL
);

GO


-- STORED PROCEDURE WITH TVP
			-- The SELECT statement in this subtask 1 selects the "Note" column from the @Notes parameter and inserts it into the "Notes" column of the "dbo.ContactNotes" table. The @ContactID parameter value is inserted into the "ContactID" column of the "dbo.ContactNotes" table. This subtask makes use of the TVP parameter to pass a table as input to the stored procedure.
DROP PROCEDURE IF EXISTS dbo.InsertContactNotes
GO

CREATE  PROCEDURE dbo.InsertContactNotes
(
@ContactID	INT,
@Notes		dbo.ContactNote READONLY	-- READONLY function prevents large data copy from the TempDB where TVP are stored before being passed to the Stored Procedure
)
AS
BEGIN;
	INSERT INTO dbo.ContactNotes (ContactId, Notes)	-- subtask1_Insert data into the "dbo.ContactNotes" table
	SELECT	@ContactID, Note 
	FROM @Notes;

	SELECT * 
	FROM dbo.ContactNotes	-- subtask2_Retrieve data from the "dbo.ContactNotes" table for the specified ContactID
	WHERE ContactId = @ContactID
	ORDER BY NoteId DESC;
	
END;

GO

-- EXECUTING THE STORED PROCEDURE TO INSERT NOTES
DECLARE @TempNotes	dbo.ContactNote;

INSERT INTO @TempNotes 
	(Note)
VALUES
('Finalizing budget for Q2 and allocating resources'),
--('Reviewing progress on current project and identifying areas for improvement'),
('Brainstorming new marketing strategies and tactics');

EXECUTE dbo.InsertContactNotes
	@ContactID = 15,
	@Notes = @TempNotes;




/* ADVANCED PROCEDURE TO INSERT MULTIPLES NOTES FOR MULTIPLES CONTACTID CONCURENTLY */

DROP TYPE IF EXISTS dbo.ContactNoteCplx;
GO

CREATE TYPE dbo.ContactNoteCplx		-- this table type is created to pass tabular data to the stored procedure
AS TABLE
(
	Note	VARCHAR(MAX) NOT NULL,
	ContactID	INT NOT NULL
);

GO

-- STORED PROCEDURE WITH TVP
DROP PROCEDURE IF EXISTS dbo.InsertContactNotesCplx
GO

CREATE  PROCEDURE dbo.InsertContactNotesCplx
(
	@Notes	dbo.ContactNoteCplx READONLY	-- READONLY function prevents large data copy from the TempDB where TVP are stored before being passed to the Stored Procedure
)
AS
BEGIN;
	INSERT INTO dbo.ContactNotes (ContactId, Notes) -- subtask1
	SELECT	cn.ContactID, cn.Note 
	FROM @Notes AS cn;

	SELECT * 
	FROM dbo.ContactNotes	-- subtask2
	ORDER BY NoteId DESC;
	
END;

GO

-- EXECUTING THE STORED PROCEDURE TO INSERT NOTES
DECLARE @TempNotes	dbo.ContactNoteCplx;

INSERT INTO @TempNotes 
	(Note, ContactID)
VALUES
('Discussing new product launch and marketing strategies', 13),
('Reviewing customer feedback and identifying areas for improvement', 25),
('Planning company retreat and activities', 1);

EXECUTE dbo.InsertContactNotesCplx @Notes =	@TempNotes;



