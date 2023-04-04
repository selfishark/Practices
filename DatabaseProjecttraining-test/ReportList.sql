CREATE TABLE [dbo].[ReportList] (
    [ReportID]        INT            NOT NULL,
    [CompanyID]       INT            NOT NULL,
    [SupplierID]      INT            NOT NULL,
    [FileName]        NVARCHAR (MAX) NOT NULL,
    [Status]          INT            NOT NULL,
    [StatusTimeStamp] DATETIME2 (7)  NOT NULL,
    [ReturnLocation]  VARCHAR (MAX)  NULL
);


GO

