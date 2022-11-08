CREATE TABLE [dbo].[Setting]
(
[Name] [nvarchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Value] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Setting] ADD CONSTRAINT [PK_Setting] PRIMARY KEY CLUSTERED ([Name]) ON [PRIMARY]
GO

INSERT INTO [dbo].[Setting] ([Name], [Value]) VALUES ('ApiKey', N'development value')
INSERT INTO [dbo].[Setting] ([Name], [Value]) VALUES ('Build Date', N'2000-01-01')
INSERT INTO [dbo].[Setting] ([Name], [Value]) VALUES ('Git Hash', N'default')
GO
