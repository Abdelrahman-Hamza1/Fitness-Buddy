using FitnessBuddy.BuildingBlocks.Persistence;
using Microsoft.EntityFrameworkCore;

namespace FitnessBuddy.Modules.UserData.Infrastructure;

// The hot path is parameterized SQL; EF owns schema migrations, not tracked document entities.
internal sealed class UserDataContext(DbContextOptions<UserDataContext> options) : ModuleDbContext(options, "userdata");
