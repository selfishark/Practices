CREATE TABLE [dbo].[Email_Downloader] (
    [Email_ID]          INT            IDENTITY (1, 1) NOT NULL,
    [Subject]           NVARCHAR (MAX) NULL,
    [Received_DateTime] NVARCHAR (MAX) NULL,
    [Sender]            NVARCHAR (MAX) NULL,
    [Recipients]        NVARCHAR (MAX) NULL,
    [Body]              NVARCHAR (MAX) NULL
);


GO

