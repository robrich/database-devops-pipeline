using Microsoft.Data.SqlClient;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;

namespace DatabaseDevOps.Tests.SuiteUnderTest
{
	public interface ITodoRepository
	{
		List<Todo> GetAll();
		Todo? GetById(int id);
		int AddTodo(Todo todo);
		int UpdateTodo(Todo todo);
		int DeleteTodo(int id);
	}

	public class TodoRepository : ITodoRepository
	{
		private readonly ISqlHelper sqlHelper;

		public TodoRepository(ISqlHelper sqlHelper)
		{
			this.sqlHelper = sqlHelper ?? throw new ArgumentNullException(nameof(sqlHelper));
		}

		public List<Todo> GetAll()
		{
			return this.sqlHelper.ExecuteQuery(
				"select Id, Task, TaskStatusId, CreateDate from dbo.Todo",
				this.GetRow
			);
		}

		public Todo? GetById(int id)
		{
			return this.sqlHelper.ExecuteQuery(
				"select Id, Task, TaskStatusId, CreateDate from dbo.Todo where Id = @Id",
				this.GetRow,
				new List<IDataParameter>
				{
					new SqlParameter("Id", SqlDbType.Int) { Value = id }
				}
			).FirstOrDefault();
		}

		public int AddTodo(Todo todo)
		{
			if (todo == null)
			{
				throw new ArgumentNullException(nameof(todo));
			}
			todo.CreateDate = DateTime.UtcNow;
			todo.Id = (int)this.sqlHelper.ExecuteScalar<decimal>(
				"insert into dbo.Todo (Task, TaskStatusId, CreateDate) values (@Task, @TaskStatusId, @CreateDate); select @@identity;",
				new List<IDataParameter>
				{
					new SqlParameter("Task", SqlDbType.NVarChar, 200) { Value = todo.Task },
					new SqlParameter("TaskStatusId", SqlDbType.Int) { Value = (int)todo.TaskStatus },
					new SqlParameter("CreateDate", SqlDbType.DateTime) { Value = todo.CreateDate }
				}
			);
			return todo.Id;
		}

		public int UpdateTodo(Todo todo)
		{
			if (todo == null)
			{
				throw new ArgumentNullException(nameof(todo));
			}
			todo.CreateDate = DateTime.Now;
			return this.sqlHelper.ExecuteNonQuery(
				"update dbo.Todo set Task = @Task, TaskStatusId = @TaskStatusId, CreateDate = @CreateDate where Id = @Id;",
				new List<IDataParameter>
				{
					new SqlParameter("Task", SqlDbType.NVarChar, 200) { Value = todo.Task },
					new SqlParameter("TaskStatusId", SqlDbType.Int) { Value = (int)todo.TaskStatus },
					new SqlParameter("CreateDate", SqlDbType.DateTime) { Value = todo.CreateDate },
					new SqlParameter("Id", SqlDbType.Int) { Value = todo.Id }
				}
			);
		}

		public int DeleteTodo(int id)
		{
			return this.sqlHelper.ExecuteNonQuery(
				"delete from dbo.Todo where Id = @Id;",
				new List<IDataParameter>
				{
					new SqlParameter("Id", SqlDbType.Int) { Value = id }
				}
			);
		}

		private Todo GetRow(IDataReader dr) =>
			new Todo
			{
				Id = sqlHelper.ToValOrNull<int>(dr, "Id"),
				Task = sqlHelper.ToValOrNull<string>(dr, "Task") ?? "",
				TaskStatus = (TaskStatus)sqlHelper.ToValOrNull<int>(dr, "TaskStatusId"),
				CreateDate = sqlHelper.ToValOrNull<DateTime>(dr, "CreateDate")
			};

	}
}
