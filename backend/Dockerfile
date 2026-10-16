# Bump the SDK tag/digest together with backend/global.json; image-smoke checks the version.
FROM mcr.microsoft.com/dotnet/sdk:10.0.402-noble@sha256:0d99ebf1ccad15037b5c98c9fe8979d6b8dbac23812feae2277a0b277b5c5ffa AS build
WORKDIR /src
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1 DOTNET_NOLOGO=1
COPY global.json Directory.Build.props Directory.Packages.props nuget.config ./
COPY src/BuildingBlocks/FitnessBuddy.BuildingBlocks.csproj src/BuildingBlocks/
COPY src/Modules/Account/FitnessBuddy.Modules.Account.csproj src/Modules/Account/
COPY src/Host/FitnessBuddy.Host.csproj src/Host/
RUN dotnet restore src/Host/FitnessBuddy.Host.csproj
COPY src/ src/
RUN dotnet publish src/Host/FitnessBuddy.Host.csproj -c Release --no-restore -o /app \
    -p:OpenApiGenerateDocuments=false -p:UseAppHost=false -p:UseSharedCompilation=false -m:1

# Match the patched runtime used by the pinned SDK. Extra supplies ICU/tzdata for later Arabic work.
FROM mcr.microsoft.com/dotnet/aspnet:10.0.13-noble-chiseled-extra@sha256:3ed6558056b54d5c9dfefb7ff473728e022ff2bf1d976cbf8ee07b05ec594374 AS runtime
WORKDIR /app
COPY --from=build /app ./
USER $APP_UID
EXPOSE 8080
# No shell/HEALTHCHECK in the chiseled image; the proxy probes /health/ready (S05).
ENTRYPOINT ["dotnet", "FitnessBuddy.Host.dll"]
CMD ["api"]
