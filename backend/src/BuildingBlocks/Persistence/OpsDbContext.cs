using Microsoft.EntityFrameworkCore;

namespace FitnessBuddy.BuildingBlocks.Persistence;

// ops tables are raw-SQL infrastructure, not product entities. Migrations remain EF-tracked per schema.
internal sealed class OpsDbContext(DbContextOptions<OpsDbContext> options) : ModuleDbContext(options, "ops");
