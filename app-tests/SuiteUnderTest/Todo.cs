namespace DatabaseDevOps.Tests.SuiteUnderTest;

public class Todo
{
	public int Id { get; set; }
	public string Task { get; set; } = "";
	public TaskStatus TaskStatus { get; set; }
	public DateTime CreateDate { get; set; }
}
