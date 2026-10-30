using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

namespace FitnessBuddy.Modules.Catalog.Infrastructure.Migrations;

/// <summary>B10a: the application role writes the licence-isolated OFF cache (and only it); the expiry job scans by date.</summary>
[DbContext(typeof(CatalogContext))]
[Migration("202610300001_OffCacheWrites")]
internal sealed class OffCacheWrites : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) => migrationBuilder.Sql("""
        GRANT SELECT, INSERT, UPDATE, DELETE ON catalog.off_cache TO fb_app;
        CREATE INDEX off_cache_expires ON catalog.off_cache(expires_at);
        """);
    protected override void Down(MigrationBuilder migrationBuilder) => throw new NotSupportedException("Catalog rollback uses a verified recovery procedure.");
}
