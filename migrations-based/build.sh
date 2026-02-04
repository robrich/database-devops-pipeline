#!/bin/sh

set -e

export SA_PASSWORD="p5ssw@rd"

#
echo "starting local database server"
docker-compose up &

#sleep 80 # wait for database to start
echo -n "waiting for database to start..."
ready=false
until [ "$ready" = true ]; do
  docker run --rm --link db:db mcr.microsoft.com/mssql-tools /opt/mssql-tools/bin/sqlcmd -S db -U sa -P $SA_PASSWORD -C -b -Q "SELECT * FROM sys.databases" > /dev/null 2>&1 && ready=true
  sleep 1
  echo -n "."
done
echo ""

#
echo "create test database"

docker run --rm --link db:db mcr.microsoft.com/mssql-tools /opt/mssql-tools/bin/sqlcmd -S db -U sa -P $SA_PASSWORD -Q "IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = 'Todos') BEGIN; CREATE DATABASE Todos; END;"

#
echo "migrate test database from empty to current version"

docker run --rm --link db -v "$(pwd)/sql:/flyway/sql" flyway/flyway migrate "-url=jdbc:sqlserver://db:1433;databaseName=Todos;encrypt=true;trustServerCertificate=true" "-user=sa" "-password=$SA_PASSWORD"

#
echo "version assets"

docker run --rm --link db:db mcr.microsoft.com/mssql-tools /opt/mssql-tools/bin/sqlcmd -S db -U sa -P $SA_PASSWORD -d Todos -Q "UPDATE dbo.Setting SET Value = '$(date --iso-8601)' WHERE Name = 'Build Date';"
docker run --rm --link db:db mcr.microsoft.com/mssql-tools /opt/mssql-tools/bin/sqlcmd -S db -U sa -P $SA_PASSWORD -d Todos -Q "UPDATE dbo.Setting SET Value = '$(git rev-parse --short HEAD)' WHERE Name = 'Git Hash';"

#
echo "run app tests against database"

docker run --rm --link db:db mcr.microsoft.com/mssql-tools /opt/mssql-tools/bin/sqlcmd -S db -U sa -P $SA_PASSWORD -d Todos -Q "SELECT * FROM dbo.TaskStatus; SELECT * FROM dbo.Setting;"

docker build --target test -t app-tests ../app-tests
docker run --rm --link db -e ConnectionStrings__DatabaseDevOps="Server=db;Database=Todos;User ID=sa;Password=$SA_PASSWORD;TrustServerCertificate=True" -v "$(pwd)/test-results:/src/test-results" app-tests

#
echo "clean up"

docker-compose down

#
echo "deploy"

if [ -z ${deploydb_database} ] || [ -z ${deploydb_server} ] || [ -z ${deploydb_username} ] || [ -z ${deploydb_password} ]; then
  echo "can't deploy because deploy variables not set"
  exit 1
fi

docker run --rm --link db -v "$(pwd)/sql:/flyway/sql" flyway/flyway migrate "-url=jdbc:sqlserver://$deploydb_server:1433;databaseName=$deploydb_database;encrypt=true" "-user=$deploydb_username" "-password=$deploydb_password"

#
echo "version assets"

docker run --rm mcr.microsoft.com/mssql-tools /opt/mssql-tools/bin/sqlcmd -S $deploydb_server -U $deploydb_username -P $deploydb_password -d $deploydb_database -Q "UPDATE dbo.Setting SET Value = '$(date --iso-8601)' WHERE Name = 'Build Date'; UPDATE dbo.Setting SET Value = '$(git rev-parse --short HEAD)' WHERE Name = 'Git Hash';"
