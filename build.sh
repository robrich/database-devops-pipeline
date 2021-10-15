#!/bin/sh

set -e

export SA_PASSWORD="p5ssw@rd"

docker-compose up -d

sleep 80 # wait for database to start

#
echo "create test database"

docker run --rm --link db:db mcr.microsoft.com/mssql-tools /opt/mssql-tools/bin/sqlcmd -S db -U sa -P $SA_PASSWORD -Q "IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = 'Todos') BEGIN; CREATE DATABASE Todos; END;"

#
echo "migrate test database from empty to current version"

docker run --rm --link db -v "$(pwd)/sql-scripts:/data/sql-scripts" redgate/sqlcompare /IAgreeToTheEULA /scripts1:/data/sql-scripts /s2:db /db2:Todos /u2:sa "/p2:$SA_PASSWORD" /Synchronize /include:Identical

docker run --rm --link db -v "$(pwd)/sql-scripts:/data/sql-scripts" redgate/sqldatacompare /IAgreeToTheEULA /scripts1:/data/sql-scripts /s2:db /db2:Todos /u2:sa "/p2:$SA_PASSWORD" /Synchronize /include:Identical

#
echo "version assets"

docker run --rm --link db:db mcr.microsoft.com/mssql-tools /opt/mssql-tools/bin/sqlcmd -S db -U sa -P $SA_PASSWORD -d Todos -Q "UPDATE dbo.Setting SET Value = '$(date --iso-8601)' WHERE Name = 'Build Date';"
docker run --rm --link db:db mcr.microsoft.com/mssql-tools /opt/mssql-tools/bin/sqlcmd -S db -U sa -P $SA_PASSWORD -d Todos -Q "UPDATE dbo.Setting SET Value = '$(git rev-parse --short HEAD)' WHERE Name = 'Git Hash';"

#
echo "run app tests against database"

docker run --rm --link db:db mcr.microsoft.com/mssql-tools /opt/mssql-tools/bin/sqlcmd -S db -U sa -P $SA_PASSWORD -d Todos -Q "SELECT * FROM dbo.TaskStatus; SELECT * FROM dbo.Setting;"

docker build -t app-tests app-tests
docker run --rm --link db -e ConnectionStrings__DatabaseDevOps="Server=db;Database=Todos;User ID=sa;Password=$SA_PASSWORD;" app-tests

#
echo "clean up"

docker-compose down

#
echo "deploy"

docker run --rm -v "$(pwd)/sql-scripts:/data/sql-scripts" redgate/sqlcompare /IAgreeToTheEULA /scripts1:/data/sql-scripts /s2:$deploydb_server /db2:$deploydb_database /u2:$deploydb_username "/p2:$deploydb_password" /Synchronize /include:Identical

docker run --rm -v "$(pwd)/sql-scripts:/data/sql-scripts" redgate/sqldatacompare /IAgreeToTheEULA /scripts1:/data/sql-scripts /s2:$deploydb_server /db2:$deploydb_database /u2:$deploydb_username "/p2:$deploydb_password" /Synchronize /include:Identical

#
echo "version assets"

docker run --rm mcr.microsoft.com/mssql-tools /opt/mssql-tools/bin/sqlcmd -S $deploydb_server -U $deploydb_username -P $deploydb_password -d $deploydb_database -Q "UPDATE dbo.Setting SET Value = '$(date --iso-8601)' WHERE Name = 'Build Date'; UPDATE dbo.Setting SET Value = '$(git rev-parse --short HEAD)' WHERE Name = 'Git Hash';"
