using FitnessBuddy.BuildingBlocks.Persistence;
using Microsoft.EntityFrameworkCore;

namespace FitnessBuddy.Modules.Catalog.Infrastructure;

internal sealed class CatalogContext(DbContextOptions<CatalogContext> options) : ModuleDbContext(options, "catalog");
