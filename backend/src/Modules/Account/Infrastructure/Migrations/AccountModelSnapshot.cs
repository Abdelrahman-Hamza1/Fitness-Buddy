using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;

namespace FitnessBuddy.Modules.Account.Infrastructure.Migrations;

[DbContext(typeof(AccountContext))]
internal sealed class AccountModelSnapshot : ModelSnapshot
{
    protected override void BuildModel(ModelBuilder modelBuilder)
    {
        modelBuilder.HasAnnotation("ProductVersion", "10.0.12");
        modelBuilder.HasDefaultSchema("account");
    }
}
