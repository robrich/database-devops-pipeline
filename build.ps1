
$ErrorActionPreference = "Stop"

$env:SA_PASSWORD = "p5ssw@rd"

#
echo "starting local database server"

docker-compose up -d

sleep 80 # wait for database to start

#
echo "create test database"

docker run --rm --link db:db mcr.microsoft.com/mssql-tools /opt/mssql-tools/bin/sqlcmd -S db -U sa -P $env:SA_PASSWORD -b -Q "IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = 'Todos') BEGIN; CREATE DATABASE Todos; END;"

#
echo "migrate test database from empty to current version"

docker run --rm --link db -v "$(pwd)/sql-scripts:/data/sql-scripts" redgate/sqlcompare /IAgreeToTheEULA /scripts1:/data/sql-scripts /s2:db /db2:Todos /u2:sa "/p2:$env:SA_PASSWORD" /Synchronize /include:Identical

docker run --rm --link db -v "$(pwd)/sql-scripts:/data/sql-scripts" redgate/sqldatacompare /IAgreeToTheEULA /scripts1:/data/sql-scripts /s2:db /db2:Todos /u2:sa "/p2:$env:SA_PASSWORD" /Synchronize /include:Identical

#
echo "version assets"

$dateval = $(Get-Date -Format 'yyyy-MM-dd')
docker run --rm --link db:db mcr.microsoft.com/mssql-tools /opt/mssql-tools/bin/sqlcmd -S db -U sa -P $env:SA_PASSWORD -d Todos -b -Q "UPDATE dbo.Setting SET Value = '$dateval' WHERE Name = 'Build Date';"
$githash = $(git rev-parse --short HEAD)
docker run --rm --link db:db mcr.microsoft.com/mssql-tools /opt/mssql-tools/bin/sqlcmd -S db -U sa -P $env:SA_PASSWORD -d Todos -b -Q "UPDATE dbo.Setting SET Value = '$githash' WHERE Name = 'Git Hash';"

#
echo "run app tests against database"

docker run --rm --link db:db mcr.microsoft.com/mssql-tools /opt/mssql-tools/bin/sqlcmd -S db -U sa -P $env:SA_PASSWORD -d Todos -b -Q "SELECT * FROM dbo.TaskStatus; SELECT * FROM dbo.Setting;"

docker build -t app-tests app-tests
docker run --rm --link db -e ConnectionStrings__DatabaseDevOps="Server=db;Database=Todos;User ID=sa;Password=${env:SA_PASSWORD};" app-tests

#
echo "clean up"

docker-compose down

#
echo "deploy"

Read-Host "Push any key to deploy"

docker run --rm -v "$(pwd)/sql-scripts:/data/sql-scripts" redgate/sqlcompare /IAgreeToTheEULA /scripts1:/data/sql-scripts /s2:$deploydb_server /db2:$deploydb_database /u2:$deploydb_username "/p2:$deploydb_password" /Synchronize /include:Identical

docker run --rm -v "$(pwd)/sql-scripts:/data/sql-scripts" redgate/sqldatacompare /IAgreeToTheEULA /scripts1:/data/sql-scripts /s2:$deploydb_server /db2:$deploydb_database /u2:$deploydb_username "/p2:$deploydb_password" /Synchronize /include:Identical

#
echo "version assets"

$dateval = $(Get-Date -Format 'yyyy-MM-dd')
docker run --rm mcr.microsoft.com/mssql-tools /opt/mssql-tools/bin/sqlcmd -S $deploydb_server -U $deploydb_username -P $deploydb_password -d $deploydb_database -b -Q "UPDATE dbo.Setting SET Value = '$dateval' WHERE Name = 'Build Date'; UPDATE dbo.Setting SET Value = '$githash' WHERE Name = 'Git Hash';"
