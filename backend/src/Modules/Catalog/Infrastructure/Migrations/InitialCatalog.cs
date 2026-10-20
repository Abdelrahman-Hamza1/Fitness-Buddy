using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

namespace FitnessBuddy.Modules.Catalog.Infrastructure.Migrations;

[DbContext(typeof(CatalogContext))]
[Migration("202610200001_InitialCatalog")]
internal sealed class InitialCatalog : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) => migrationBuilder.Sql("""
        CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;
        REVOKE ALL ON SCHEMA catalog FROM PUBLIC;
        GRANT USAGE ON SCHEMA catalog TO fb_app;
        CREATE TABLE catalog.pack_releases(version integer PRIMARY KEY, content_sha256 text NOT NULL,
          pack_sha256 text NOT NULL, schema_version integer NOT NULL, pack bytea NOT NULL,
          manifest jsonb NOT NULL);
        CREATE TABLE catalog.current_release(singleton boolean PRIMARY KEY DEFAULT true CHECK(singleton),
          version integer NOT NULL REFERENCES catalog.pack_releases(version));
        CREATE TABLE catalog.foods(id text COLLATE "C" PRIMARY KEY, kind text NOT NULL, source text NOT NULL,
          source_ref text NOT NULL, first_version integer NOT NULL, name_key text NOT NULL, state text NOT NULL,
          active boolean NOT NULL, data jsonb NOT NULL);
        CREATE TABLE catalog.dishes(id text COLLATE "C" PRIMARY KEY, first_version integer NOT NULL,
          default_variant_id text NOT NULL REFERENCES catalog.foods(id), active boolean NOT NULL, data jsonb NOT NULL);
        CREATE TABLE catalog.exercises(id text COLLATE "C" PRIMARY KEY, first_version integer NOT NULL,
          active boolean NOT NULL, data jsonb NOT NULL);
        CREATE TABLE catalog.cities(id text COLLATE "C" PRIMARY KEY, active boolean NOT NULL, data jsonb NOT NULL);
        CREATE TABLE catalog.names(target_id text NOT NULL, food_id text REFERENCES catalog.foods(id),
          lang text NOT NULL, name text NOT NULL, key text COLLATE "C" NOT NULL,
          PRIMARY KEY(target_id,lang,key,name));
        CREATE INDEX names_trgm ON catalog.names USING gin(key public.gin_trgm_ops);
        CREATE INDEX names_tokens ON catalog.names USING gin(to_tsvector('simple',key));
        CREATE INDEX names_food ON catalog.names(food_id);
        CREATE TABLE catalog.servings(food_id text NOT NULL REFERENCES catalog.foods(id), ordinal integer NOT NULL,
          data jsonb NOT NULL, PRIMARY KEY(food_id,ordinal));
        CREATE TABLE catalog.yields(ordinal integer PRIMARY KEY,data jsonb NOT NULL);
        -- B10 owns OFF ingestion. This table stays licence-isolated and is never filled by release import.
        CREATE TABLE catalog.off_cache(code text PRIMARY KEY, data jsonb NOT NULL, expires_at timestamptz NOT NULL);
        GRANT SELECT ON ALL TABLES IN SCHEMA catalog TO fb_app;
        """);
    protected override void Down(MigrationBuilder migrationBuilder) => throw new NotSupportedException("Catalog rollback uses a verified recovery procedure.");
}
