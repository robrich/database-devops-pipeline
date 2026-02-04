namespace DatabaseDevOps.Tests.SuiteUnderTest;

public interface ISqlHelper
{
	T? ToValOrNull<T>(IDataReader Reader, string ColumnName);
	List<T> ExecuteQuery<T>(string query, Func<IDataReader, T> map, List<IDataParameter>? parameters = null) where T : new();
	T? ExecuteScalar<T>(string query, List<IDataParameter>? parameters = null) where T : new();
	int ExecuteNonQuery(string query, List<IDataParameter>? parameters = null);
}

public class SqlHelper : ISqlHelper
{
	public const string CONNECTION_STRING_NAME = "DatabaseDevOps";
	private readonly string connectionString;

	public SqlHelper(IConfiguration config)
	{
		if (config is null)
		{
			throw new ArgumentNullException(nameof(config));
		}

		this.connectionString = config.GetSection("ConnectionStrings")[CONNECTION_STRING_NAME]!;
		if (string.IsNullOrEmpty(this.connectionString))
		{
			throw new ArgumentNullException(nameof(config), $"{CONNECTION_STRING_NAME} not found in ConnectionStrings");
		}
	}

	/// <summary>
	/// A cool helper method that makes <code>reader[&quot;column&quot;] != DBNull.Value ? reader[&quot;column&quot;] : (type)null;</code> more DRY: <code>this.sqlHelper.ToValOrNull&lt;type&gt;(reader, &quot;column&quot;)</code>
	/// </summary>
	public T? ToValOrNull<T>(IDataReader Reader, string ColumnName)
	{
		try
		{
			object value = Reader[ColumnName];
			return value == DBNull.Value ? default(T) : (T)value;
		}
		catch (Exception ex)
		{
			throw new ArgumentException($"Can't get {ColumnName}: {ex.Message}", ex);
		}
	}

	// public to be testable, not part of interface
	public void ExecuteQueryToFunc(string query, Action<IDbCommand> map, List<IDataParameter>? parameters = null)
	{
		if (map == null)
		{
			throw new ArgumentNullException(nameof(map));
		}

		using (IDbConnection conn = new SqlConnection(connectionString))
		{
			using (IDbCommand cmd = conn.CreateCommand())
			{
				cmd.CommandText = query;
				if (parameters != null)
				{
					foreach (IDataParameter p in parameters)
					{
						if (p.Value == null)
						{
							p.Value = DBNull.Value;
						}
						cmd.Parameters.Add(p);
					}
				}

				bool open = cmd.Connection?.State != ConnectionState.Closed;

				try
				{
					if (!open)
					{
						cmd.Connection?.Open();
					}
					map(cmd);
				}
				finally
				{
					// Until the GC runs, the old connection owns the passed in parameters and the retry won't work correctly
					cmd.Parameters.Clear();
					if (!open && cmd.Connection?.State != ConnectionState.Closed)
					{
						cmd.Connection?.Close();
					}
				}
			}
		}

		if (parameters != null)
		{
			foreach (IDataParameter p in parameters)
			{
				if (p.Value == DBNull.Value)
				{
					p.Value = null;
				}
			}
		}
	}

	public List<T> ExecuteQuery<T>(string query, Func<IDataReader, T> map, List<IDataParameter>? parameters = null) where T : new()
	{
		List<T> results = new List<T>();
		ExecuteQueryToFunc(query, dbCommand =>
		{
			using (IDataReader reader = dbCommand.ExecuteReader())
			{
				while (reader.Read())
				{
					results.Add(map(reader));
				}
			}
		}, parameters);
		return results;
	}

	public T? ExecuteScalar<T>(string query, List<IDataParameter>? parameters = null) where T : new()
	{
		object? output = null;
		ExecuteQueryToFunc(query, dbCommand =>
		{
			output = dbCommand.ExecuteScalar();
		}, parameters);

		T? results = default(T);
		if (output == null || output == DBNull.Value)
		{
			results = default(T);
		}
		else if (output is T)
		{
			results = (T)output;
		}
		else
		{
			throw new ArgumentException($"{query} didn't return a {typeof(T)} or DBNull.Value, it returned {output}");
		}

		return results;
	}

	public int ExecuteNonQuery(string query, List<IDataParameter>? parameters = null)
	{
		int result = 0;
		ExecuteQueryToFunc(query, dbCommand =>
		{
			result = dbCommand.ExecuteNonQuery();
		}, parameters);
		return result;
	}

}
