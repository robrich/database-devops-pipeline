using DatabaseDevOps.Tests.Helpers;
using DatabaseDevOps.Tests.SuiteUnderTest;
using FluentAssertions;
using FluentAssertions.Execution;
using System;
using System.Collections.Generic;
using Xunit;

namespace DatabaseDevOps.Tests
{
	public class DatabaseIntegrationTests
    {
        private readonly ITodoRepository todoRepository;

        public DatabaseIntegrationTests()
		{
            var config = Config.LoadSettings();
            var sqlHelper = new SqlHelper(config);
            this.todoRepository = new TodoRepository(sqlHelper);
        }

        [Fact]
        public void GetAll()
        {

            // Arrange

            // Act
            List<Todo> todos = this.todoRepository.GetAll();

            // Assert
            todos.Should().NotBeNull();

        }

        [Fact]
        public void GetById_NotFound()
        {

            // Arrange

            // Act
            Todo? todo = this.todoRepository.GetById(-1);

            // Assert
            todo.Should().BeNull();

        }

        [Fact]
        public void CRUD()
        {
			Todo todo = Add();
            Modify(todo);
            GetByIdFound(todo);
            Delete(todo.Id);
        }

        private Todo Add()
		{

            // Arrange
            Todo todo = new Todo
            {
                Task = "test added a todo",
                TaskStatus = TaskStatus.Open
            };

            // Act
            this.todoRepository.AddTodo(todo);

            // Assert
            todo.Id.Should().BeGreaterThan(0);

            return todo;
        }

        private void Modify(Todo todo)
        {

            // Arrange
            todo.Task = "modified test todo";
            todo.TaskStatus = TaskStatus.Completed;

            // Act
            this.todoRepository.UpdateTodo(todo);

            // Assert
            // it shouldn't throw an exception
        }

        private void GetByIdFound(Todo todo)
        {

			// Arrange

			// Act
			Todo? actual = this.todoRepository.GetById(todo.Id);

            // Assert
            actual.Should().NotBeNull();
            if (actual == null)
			{
                throw new ArgumentNullException(nameof(actual));
			}
            using (new AssertionScope())
            {
                actual.Id.Should().Be(todo.Id);
                actual.Task.Should().Be(todo.Task);
                actual.TaskStatus.Should().Be(todo.TaskStatus);
                actual.CreateDate.Should().BeCloseTo(todo.CreateDate, TimeSpan.FromSeconds(1));
            }

        }

        private void Delete(int id)
        {

            // Arrange

            // Act
            int rowCount = this.todoRepository.DeleteTodo(id);
            Todo? actual = this.todoRepository.GetById(id);

            // Assert
            using (new AssertionScope())
            {
                rowCount.Should().Be(1);
                actual.Should().BeNull();
            }
            
        }
    }
}
