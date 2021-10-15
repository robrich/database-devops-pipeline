FROM mcr.microsoft.com/dotnet/sdk:5.0-alpine

WORKDIR /src

ENV ConnectionStrings__DatabaseDevOps ""

COPY DatabaseDevOps.Tests.csproj .
RUN dotnet restore
COPY . .
RUN dotnet build -c Debug --no-restore

CMD ["dotnet", "test", "--no-build"]
