using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

namespace FitnessBuddy.Modules.Usage.Infrastructure.Migrations;

[DbContext(typeof(UsageContext))]
[Migration("202610210001_InitialUsage")]
internal sealed class InitialUsage : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) => migrationBuilder.Sql("""
        REVOKE ALL ON SCHEMA usage FROM PUBLIC;
        GRANT USAGE ON SCHEMA usage TO fb_app;
        CREATE TABLE usage.daily (user_id uuid NOT NULL,day date NOT NULL,model text NOT NULL,calls integer NOT NULL,messages integer NOT NULL,input_tokens bigint NOT NULL,cached_input_tokens bigint NOT NULL,output_tokens bigint NOT NULL,estimated_usd numeric NOT NULL,PRIMARY KEY(user_id,day,model));
        
        ALTER TABLE usage.daily ENABLE ROW LEVEL SECURITY;
        ALTER TABLE usage.daily FORCE ROW LEVEL SECURITY;
        CREATE POLICY user_isolation ON usage.daily TO fb_app
          USING(user_id=NULLIF(current_setting('app.user_id',true),'')::uuid)
          WITH CHECK(user_id=NULLIF(current_setting('app.user_id',true),'')::uuid);
        GRANT SELECT,INSERT,UPDATE,DELETE ON usage.daily TO fb_app;
        REVOKE ALL ON usage.__ef_migrations_history FROM fb_app;
        """);
    protected override void Down(MigrationBuilder migrationBuilder) => migrationBuilder.Sql("DROP TABLE usage.daily;");
}
