use [SQLAuthority]
go

CREATE CLUSTERED INDEX [_dta_index_DiskBasedTable_c_13_901578250__K1] ON [dbo].[DiskBasedTable]
(
	[ID] ASC
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]
go

CREATE NONCLUSTERED COLUMNSTORE INDEX [_dta_index_DiskBasedTable_13_901578250__col__] ON [dbo].[DiskBasedTable]
(
	[ID],
	[FName],
	[LName]
)WITH (DROP_EXISTING = OFF, COMPRESSION_DELAY = 0) ON [PRIMARY]
go

