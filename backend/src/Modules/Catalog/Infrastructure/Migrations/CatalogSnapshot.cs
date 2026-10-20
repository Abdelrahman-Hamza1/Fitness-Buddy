using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;

namespace FitnessBuddy.Modules.Catalog.Infrastructure.Migrations;

[DbContext(typeof(CatalogContext))]
internal sealed class CatalogSnapshot : ModelSnapshot
{
    protected override void BuildModel(ModelBuilder modelBuilder)
    {
        modelBuilder.HasAnnotation("ProductVersion", "10.0.12");
        modelBuilder.HasDefaultSchema("catalog");
    }
}
