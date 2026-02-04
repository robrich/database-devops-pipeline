namespace DatabaseDevOps.Tests.Helpers;

public static class Config
{

	public static IConfiguration LoadSettings()
	{
		return new ConfigurationBuilder()
		  .SetBasePath(AppContext.BaseDirectory)
		  .AddJsonFile("appsettings.json", false, true)
		  .AddEnvironmentVariables()
		  .Build();
	}

}