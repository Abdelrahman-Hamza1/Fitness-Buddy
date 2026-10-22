using FitnessBuddy.BuildingBlocks.Persistence;
using Microsoft.EntityFrameworkCore;

namespace FitnessBuddy.Modules.Buddy.Infrastructure;

internal sealed class BuddyContext(DbContextOptions<BuddyContext> options) : ModuleDbContext(options, "buddy");
