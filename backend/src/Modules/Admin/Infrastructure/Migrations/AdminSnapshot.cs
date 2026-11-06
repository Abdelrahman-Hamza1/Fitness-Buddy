using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;

namespace FitnessBuddy.Modules.Admin.Infrastructure.Migrations;

[DbContext(typeof(AdminContext))]
internal sealed class AdminSnapshot : ModelSnapshot
{
    protected override void BuildModel(ModelBuilder modelBuilder)
    {
        modelBuilder.HasAnnotation("ProductVersion", "10.0.12");
        modelBuilder.HasDefaultSchema("admin");
    }
}
