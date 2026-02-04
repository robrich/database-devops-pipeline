
$ErrorActionPreference = "Stop"
#Set-PSDebug -Trace 1

$env:SA_PASSWORD = "p5ssw@rd"

# TODO: $env:REDGATE_AUTH_TOKEN = "..."
# TODO: $env:REDGATE_AUTH_EMAIL = "..."
if (-not $env:REDGATE_AUTH_TOKEN -or -not $env:REDGATE_AUTH_EMAIL) {
  Write-Error "Please set REDGATE_AUTH_TOKEN and REDGATE_AUTH_EMAIL environment variables"
  Write-Error "See https://documentation.red-gate.com/authentication/personal-access-tokens-pats"
  exit 1
}

#
echo "starting local database server"
Start-Process -NoNewWindow docker-compose up

#sleep 80 # wait for database to start
Write-Host "waiting for database to start..." -NoNewLine
$ready = $false
while (!$ready) {
  try {
    docker run --rm --link db:db mcr.microsoft.com/mssql-tools /opt/mssql-tools/bin/sqlcmd -S db -U sa -P $env:SA_PASSWORD -C -b -Q "SELECT * FROM sys.databases" > $null 2> $null
    if ($?) {
      $ready = true
      break
    }
  } catch {
    $ready = false
  }
  sleep 1
  Write-Host "." -NoNewLine
}
echo ""

#
echo "create test database"

docker run --rm --link db:db mcr.microsoft.com/mssql-tools /opt/mssql-tools/bin/sqlcmd -S db -U sa -P $env:SA_PASSWORD -C -b -Q "IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = 'Todos') BEGIN; CREATE DATABASE Todos; END;"

#
echo "migrate test database from empty to current version"

docker run --rm --link db -v "${PWD}/sql-scripts:/data/sql-scripts" redgate/sqlcompare /IAgreeToTheEULA /token:"$env:REDGATE_AUTH_TOKEN" /email:"$env:REDGATE_AUTH_EMAIL" /scripts1:/data/sql-scripts /s2:db /db2:Todos /u2:sa "/p2:$env:SA_PASSWORD" /Synchronize /include:Identical

docker run --rm --link db -v "${PWD}/sql-scripts:/data/sql-scripts" redgate/sqldatacompare /IAgreeToTheEULA /token:"$env:REDGATE_AUTH_TOKEN" /email:"$env:REDGATE_AUTH_EMAIL" /scripts1:/data/sql-scripts /s2:db /db2:Todos /u2:sa "/p2:$env:SA_PASSWORD" /Synchronize /include:Identical

#
echo "version assets"

$dateval = $(Get-Date -Format 'yyyy-MM-dd')
docker run --rm --link db:db mcr.microsoft.com/mssql-tools /opt/mssql-tools/bin/sqlcmd -S db -U sa -P $env:SA_PASSWORD -d Todos -C -b -Q "UPDATE dbo.Setting SET Value = '$dateval' WHERE Name = 'Build Date';"
$githash = $(git rev-parse --short HEAD)
docker run --rm --link db:db mcr.microsoft.com/mssql-tools /opt/mssql-tools/bin/sqlcmd -S db -U sa -P $env:SA_PASSWORD -d Todos -C -b -Q "UPDATE dbo.Setting SET Value = '$githash' WHERE Name = 'Git Hash';"

#
echo "run app tests against database"

docker run --rm --link db:db mcr.microsoft.com/mssql-tools /opt/mssql-tools/bin/sqlcmd -S db -U sa -P $env:SA_PASSWORD -d Todos -C -b -Q "SELECT * FROM dbo.TaskStatus; SELECT * FROM dbo.Setting;"

docker build --target test -t app-tests ../app-tests
docker run --rm --link db -e ConnectionStrings__DatabaseDevOps="Server=db;Database=Todos;User ID=sa;Password=${env:SA_PASSWORD};TrustServerCertificate=True" -v "${PWD}/test-results:/src/test-results" app-tests

#
echo "clean up"

docker-compose down

#
echo "deploy"

if (!$deploydb_database || !$deploydb_server || !$deploydb_username || $deploydb_password) {
  echo "can't deploy because deploy variables not set"
  exit 1
}

docker run --rm -v "$(pwd)/sql-scripts:/data/sql-scripts" redgate/sqlcompare /IAgreeToTheEULA /token:"$env:REDGATE_AUTH_TOKEN" /email:"$env:REDGATE_AUTH_EMAIL" /scripts1:/data/sql-scripts /s2:$deploydb_server /db2:$deploydb_database /u2:$deploydb_username "/p2:$deploydb_password" /Synchronize /include:Identical

docker run --rm -v "$(pwd)/sql-scripts:/data/sql-scripts" redgate/sqldatacompare /IAgreeToTheEULA /token:"$env:REDGATE_AUTH_TOKEN" /email:"$env:REDGATE_AUTH_EMAIL" /scripts1:/data/sql-scripts /s2:$deploydb_server /db2:$deploydb_database /u2:$deploydb_username "/p2:$deploydb_password" /Synchronize /include:Identical

#
echo "version assets"

$dateval = $(Get-Date -Format 'yyyy-MM-dd')
docker run --rm mcr.microsoft.com/mssql-tools /opt/mssql-tools/bin/sqlcmd -S $deploydb_server -U $deploydb_username -P $deploydb_password -d $deploydb_database -C -b -Q "UPDATE dbo.Setting SET Value = '$dateval' WHERE Name = 'Build Date'; UPDATE dbo.Setting SET Value = '$githash' WHERE Name = 'Git Hash';"
