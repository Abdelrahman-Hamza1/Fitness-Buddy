using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

namespace FitnessBuddy.Persistence.Tests;

[DbContext(typeof(SampleContext))]
internal sealed class SampleSnapshot : ModelSnapshot
{
    protected override void BuildModel(ModelBuilder modelBuilder)
    {
        modelBuilder.HasAnnotation("ProductVersion", "10.0.12").HasDefaultSchema("testdata");
        modelBuilder.HasAnnotation("Relational:MaxIdentifierLength", 63);
        modelBuilder.HasAnnotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn);
        modelBuilder.Entity("FitnessBuddy.Persistence.Tests.SampleRow", entity =>
        {
            entity.Property<Guid>("Id").ValueGeneratedOnAdd().HasColumnType("uuid").HasColumnName("id");
            entity.Property<Guid>("UserId").HasColumnType("uuid").HasColumnName("user_id");
            entity.Property<string>("Content").IsRequired().HasColumnType("text").HasColumnName("content");
            entity.Property<DateTimeOffset>("CreatedAt").HasColumnType("timestamp with time zone").HasColumnName("created_at");
            entity.HasKey("Id").HasName("pk_sample_rows");
            entity.ToTable("sample_rows", "testdata");
        });
    }
}
