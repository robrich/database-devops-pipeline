# build server container
FROM mcr.microsoft.com/dotnet/sdk:7.0-alpine as build

WORKDIR /src

COPY DatabaseDevOps.Tests.csproj .
RUN dotnet restore
COPY . .
RUN dotnet build -c Release --no-restore
RUN dotnet publish -c Release --no-restore -o /dist


# Test container
FROM build as test
ENV ConnectionStrings__DatabaseDevOps ""
CMD ["dotnet", "test", "-c", "Release", "--no-build"]


# Production runtime container
FROM mcr.microsoft.com/dotnet/aspnet:7.0-alpine as prod

ENV ASPNETCORE_ENVIRONMENT Production
ENV ASPNETCORE_URLS http://+:80

# TODO: set in k8s
ENV ConnectionStrings__DatabaseDevOps ""

RUN adduser -D aspnet
USER aspnet

WORKDIR /app
COPY --chown=aspnet --from=build /dist .
