CREATE TABLE [dbo].[Exceptions] (
    [ExceptionID]                     INT            NOT NULL,
    [ExceptionMessage]                NVARCHAR (MAX) NOT NULL,
    [ExceptionDateTime]               NVARCHAR (MAX) NOT NULL,
    [ExceptionInvestigationTime_Mins] INT            NULL
);


GO

