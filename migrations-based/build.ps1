
$ErrorActionPreference = 'Stop'
#Set-PSDebug -Trace 1

# Environment
$env:SA_PASSWORD = 'p5ssw@rd'

echo "starting local database server"
docker-compose up -d

Write-Host -NoNewline "waiting for database to start..."
$ready = $false
while (-not $ready) {
    docker run --rm --link db:db mcr.microsoft.com/mssql-tools /opt/mssql-tools/bin/sqlcmd -S db -U sa -P $env:SA_PASSWORD -C -b -Q "SELECT * FROM sys.databases" > $null 2>&1
    if ($LASTEXITCODE -eq 0) {
        $ready = $true
    } else {
        Start-Sleep -Seconds 1
        Write-Host -NoNewline "."
    }
}
echo ""

#
echo "create test database"
docker run --rm --link db:db mcr.microsoft.com/mssql-tools /opt/mssql-tools/bin/sqlcmd -S db -U sa -P $env:SA_PASSWORD -Q "IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = 'Todos') BEGIN; CREATE DATABASE Todos; END;"

#
echo "migrate test database from empty to current version"

docker run --rm --link db -v "${PWD}/sql:/flyway/sql" flyway/flyway migrate "-url=jdbc:sqlserver://db:1433;databaseName=Todos;encrypt=true;trustServerCertificate=true" "-user=sa" "-password=$env:SA_PASSWORD"

#
echo "version assets"
$buildDate = (Get-Date).ToString('yyyy-MM-dd')
$gitHash = (git rev-parse --short HEAD).Trim()
docker run --rm --link db:db mcr.microsoft.com/mssql-tools /opt/mssql-tools/bin/sqlcmd -S db -U sa -P $env:SA_PASSWORD -d Todos -Q "UPDATE dbo.Setting SET Value = '$buildDate' WHERE Name = 'Build Date';"
docker run --rm --link db:db mcr.microsoft.com/mssql-tools /opt/mssql-tools/bin/sqlcmd -S db -U sa -P $env:SA_PASSWORD -d Todos -Q "UPDATE dbo.Setting SET Value = '$gitHash' WHERE Name = 'Git Hash';"

#
echo "run app tests against database"
docker run --rm --link db:db mcr.microsoft.com/mssql-tools /opt/mssql-tools/bin/sqlcmd -S db -U sa -P $env:SA_PASSWORD -d Todos -Q "SELECT * FROM dbo.TaskStatus; SELECT * FROM dbo.Setting;"

docker build --target test -t app-tests ../app-tests
docker run --rm --link db -e "ConnectionStrings__DatabaseDevOps=Server=db;Database=Todos;User ID=sa;Password=$env:SA_PASSWORD;TrustServerCertificate=True" -v "${PWD}/test-results:/src/test-results" app-tests

echo "clean up"
docker-compose down

echo "deploy"
if (-not $env:deploydb_database -or -not $env:deploydb_server -or -not $env:deploydb_username -or -not $env:deploydb_password) {
    Write-Error "can't deploy because deploy variables not set"
    exit 1
}

docker run --rm --link db -v "${PWD}/sql:/flyway/sql" flyway/flyway migrate "-url=jdbc:sqlserver://$env:deploydb_server:1433;databaseName=$env:deploydb_database;encrypt=true" "-user=$env:deploydb_username" "-password=$env:deploydb_password"

echo "version assets"
$deployDate = (Get-Date).ToString('yyyy-MM-dd')
$deployGit = (git rev-parse --short HEAD).Trim()
docker run --rm mcr.microsoft.com/mssql-tools /opt/mssql-tools/bin/sqlcmd -S $env:deploydb_server -U $env:deploydb_username -P $env:deploydb_password -d $env:deploydb_database -Q "UPDATE dbo.Setting SET Value = '$deployDate' WHERE Name = 'Build Date'; UPDATE dbo.Setting SET Value = '$deployGit' WHERE Name = 'Git Hash';"
