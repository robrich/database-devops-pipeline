CREATE TABLE [dbo].[Todo]
(
[Id] [int] NOT NULL IDENTITY(1, 1),
[Task] [nvarchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[TaskStatusId] [int] NOT NULL,
[CreateDate] [datetime] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Todo] ADD CONSTRAINT [PK_Todo] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Todo] ADD CONSTRAINT [FK_Todo_TaskStatus] FOREIGN KEY ([TaskStatusId]) REFERENCES [dbo].[TaskStatus] ([Id])
GO
