# build server container
FROM mcr.microsoft.com/dotnet/sdk:10.0-alpine AS build

WORKDIR /src

COPY DatabaseDevOps.sln .
COPY DatabaseDevOps.Tests.csproj .
RUN dotnet restore DatabaseDevOps.sln
COPY . .
RUN dotnet build -c Release --no-restore DatabaseDevOps.sln
RUN dotnet publish -c Release --no-restore -o /dist DatabaseDevOps.Tests.csproj


# Test container
FROM build AS test
ENV ConnectionStrings__DatabaseDevOps=""
CMD ["dotnet", "test", "-c", "Release", "--no-build", "--logger", "junit;LogFilePath=/src/test-results/testresults.xml"]


# Production runtime container
FROM mcr.microsoft.com/dotnet/aspnet:10.0-alpine AS prod

ENV ASPNETCORE_ENVIRONMENT=Production
ENV ASPNETCORE_URLS=http://+:80

# TODO: set in k8s
ENV ConnectionStrings__DatabaseDevOps=""

RUN adduser -D aspnet
USER aspnet

WORKDIR /app
COPY --chown=aspnet --from=build /dist .
