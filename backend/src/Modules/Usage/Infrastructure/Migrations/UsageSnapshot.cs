using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;

namespace FitnessBuddy.Modules.Usage.Infrastructure.Migrations;

[DbContext(typeof(UsageContext))]
internal sealed class UsageSnapshot : ModelSnapshot
{
    protected override void BuildModel(ModelBuilder modelBuilder)
    {
        modelBuilder.HasDefaultSchema("usage"); modelBuilder.HasAnnotation("ProductVersion", "10.0.12");
    }
}
