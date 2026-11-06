using FitnessBuddy.BuildingBlocks.Persistence;
using Microsoft.EntityFrameworkCore;

namespace FitnessBuddy.Modules.Admin.Infrastructure;

/// <summary>Migration history for the <c>admin</c> schema. Data access uses parameterized commands on a <see cref="DatabaseSession"/>.</summary>
internal sealed class AdminContext(DbContextOptions<AdminContext> options) : ModuleDbContext(options, "admin");
