using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;

namespace FitnessBuddy.Modules.UserData.Infrastructure.Migrations;

[DbContext(typeof(UserDataContext))]
internal sealed class UserDataSnapshot : ModelSnapshot
{
    protected override void BuildModel(ModelBuilder modelBuilder)
    {
        modelBuilder.HasDefaultSchema("userdata");
        modelBuilder.HasAnnotation("ProductVersion", "10.0.12");
    }
}
