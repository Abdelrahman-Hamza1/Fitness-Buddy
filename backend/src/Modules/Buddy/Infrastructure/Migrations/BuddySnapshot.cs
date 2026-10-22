using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;

namespace FitnessBuddy.Modules.Buddy.Infrastructure.Migrations;

[DbContext(typeof(BuddyContext))]
internal sealed class BuddySnapshot : ModelSnapshot
{
    protected override void BuildModel(ModelBuilder modelBuilder)
    {
        modelBuilder.HasDefaultSchema("buddy"); modelBuilder.HasAnnotation("ProductVersion", "10.0.12");
    }
}
