# Bump the SDK tag/digest together with backend/global.json; image-smoke checks the version.
FROM mcr.microsoft.com/dotnet/sdk:10.0.403-noble@sha256:212fe4cb74627d5adf9817a4088906ae3edff1bd853bb27565d4b46731efe61e AS build
WORKDIR /src
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1 DOTNET_NOLOGO=1
COPY global.json Directory.Build.props Directory.Packages.props nuget.config ./
COPY src/BuildingBlocks/FitnessBuddy.BuildingBlocks.csproj src/BuildingBlocks/
COPY src/Modules/Buddy/FitnessBuddy.Modules.Buddy.csproj src/Modules/Buddy/
COPY src/Modules/Account/FitnessBuddy.Modules.Account.csproj src/Modules/Account/
COPY src/Modules/Identity/FitnessBuddy.Modules.Identity.csproj src/Modules/Identity/
COPY src/Modules/UserData/FitnessBuddy.Modules.UserData.csproj src/Modules/UserData/
COPY src/Modules/Catalog/FitnessBuddy.Modules.Catalog.csproj src/Modules/Catalog/
COPY src/Modules/Usage/FitnessBuddy.Modules.Usage.csproj src/Modules/Usage/
COPY src/Host/FitnessBuddy.Host.csproj src/Host/
RUN dotnet restore src/Host/FitnessBuddy.Host.csproj
COPY src/ src/
RUN dotnet publish src/Host/FitnessBuddy.Host.csproj -c Release --no-restore -o /app \
    -p:OpenApiGenerateDocuments=false -p:UseAppHost=false -p:UseSharedCompilation=false -m:1

# Match the patched runtime used by the pinned SDK. Extra supplies ICU/tzdata for later Arabic work.
FROM mcr.microsoft.com/dotnet/aspnet:10.0.14-noble-chiseled-extra@sha256:a9298ccc39c6258ae71228479e2f3f8d2ceb6639a9927262a4b0ff7d319a0e7e AS runtime
WORKDIR /app
COPY --from=build /app ./
USER $APP_UID
EXPOSE 8080
# No shell/HEALTHCHECK in the chiseled image; the proxy probes /health/ready (B13).
ENTRYPOINT ["dotnet", "FitnessBuddy.Host.dll"]
CMD ["api"]
