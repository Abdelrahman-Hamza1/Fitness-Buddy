using FitnessBuddy.BuildingBlocks.Persistence;
using Microsoft.EntityFrameworkCore;

namespace FitnessBuddy.Modules.Account.Infrastructure;

internal sealed class AccountContext(DbContextOptions<AccountContext> options) : ModuleDbContext(options, "account");
