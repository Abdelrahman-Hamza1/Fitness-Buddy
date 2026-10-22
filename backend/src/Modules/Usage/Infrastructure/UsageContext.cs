using FitnessBuddy.BuildingBlocks.Persistence;
using Microsoft.EntityFrameworkCore;

namespace FitnessBuddy.Modules.Usage.Infrastructure;

internal sealed class UsageContext(DbContextOptions<UsageContext> options) : ModuleDbContext(options, "usage");
