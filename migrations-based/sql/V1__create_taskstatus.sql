CREATE TABLE [dbo].[TaskStatus]
(
[Id] [int] NOT NULL,
[Status] [nvarchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[TaskStatus] ADD CONSTRAINT [PK_TaskStatus] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO

INSERT INTO [dbo].[TaskStatus] ([Id], [Status]) VALUES (1, N'Open')
INSERT INTO [dbo].[TaskStatus] ([Id], [Status]) VALUES (2, N'Completed')
INSERT INTO [dbo].[TaskStatus] ([Id], [Status]) VALUES (3, N'Canceled')
GO
