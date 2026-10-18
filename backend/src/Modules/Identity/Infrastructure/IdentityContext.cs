using FitnessBuddy.BuildingBlocks.Persistence;
using Microsoft.EntityFrameworkCore;

namespace FitnessBuddy.Modules.Identity.Infrastructure;

// EF owns migrations; named credential capabilities own atomic authentication operations.
internal sealed class IdentityContext(DbContextOptions<IdentityContext> options) : ModuleDbContext(options, "identity");
