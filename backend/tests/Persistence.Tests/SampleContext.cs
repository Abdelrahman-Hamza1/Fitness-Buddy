using FitnessBuddy.BuildingBlocks.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

namespace FitnessBuddy.Persistence.Tests;

internal sealed class SampleContext(DbContextOptions<SampleContext> options) : ModuleDbContext(options, "testdata")
{
    public DbSet<SampleRow> SampleRows => Set<SampleRow>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<SampleRow>().HasKey(row => row.Id);
        base.OnModelCreating(modelBuilder);
    }
}

internal sealed class SampleRow
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string Content { get; set; } = "";
    public DateTimeOffset CreatedAt { get; set; }
}

[DbContext(typeof(SampleContext))]
[Migration("202610160002_SampleRows")]
internal sealed class SampleMigration : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql("""
            CREATE TABLE testdata.sample_rows(id uuid CONSTRAINT pk_sample_rows PRIMARY KEY, user_id uuid NOT NULL, content text NOT NULL, created_at timestamptz NOT NULL);
            ALTER TABLE testdata.sample_rows ENABLE ROW LEVEL SECURITY;
            ALTER TABLE testdata.sample_rows FORCE ROW LEVEL SECURITY;
            CREATE POLICY user_isolation ON testdata.sample_rows TO fb_app
                USING(user_id = NULLIF(current_setting('app.user_id', true), '')::uuid)
                WITH CHECK(user_id = NULLIF(current_setting('app.user_id', true), '')::uuid);
            GRANT USAGE ON SCHEMA testdata TO fb_app;
            GRANT SELECT, INSERT, UPDATE, DELETE ON testdata.sample_rows TO fb_app;
            CREATE TABLE testdata.effects(id uuid PRIMARY KEY, count integer NOT NULL);
            GRANT SELECT, INSERT, UPDATE, DELETE ON testdata.effects TO fb_app;
            """);
    }
    protected override void Down(MigrationBuilder migrationBuilder) => migrationBuilder.Sql("DROP TABLE testdata.sample_rows, testdata.effects;");
}
