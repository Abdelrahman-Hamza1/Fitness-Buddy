using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;

namespace FitnessBuddy.Modules.Identity.Infrastructure.Migrations;

[DbContext(typeof(IdentityContext))]
internal sealed class IdentitySnapshot : ModelSnapshot
{
    protected override void BuildModel(ModelBuilder modelBuilder)
    {
        modelBuilder.HasDefaultSchema("identity");
        modelBuilder.HasAnnotation("ProductVersion", "10.0.12");
    }
}
