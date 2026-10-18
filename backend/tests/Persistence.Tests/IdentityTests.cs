using FitnessBuddy.Modules.Identity;
using FitnessBuddy.Modules.Identity.Application;
using Microsoft.IdentityModel.JsonWebTokens;
using Npgsql;

namespace FitnessBuddy.Persistence.Tests;

[Trait("Req", "AC-001")]
[Trait("Req", "AC-002")]
[Trait("Req", "AC-003")]
public sealed class IdentityTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;
    private async Task<IdentityHarness> HarnessAsync() { var h = new IdentityHarness(postgres); await h.InitializeAsync(); return h; }

    [Fact]
    public async Task Guest_tokens_validate_and_logout_immediately_revokes_the_session()
    {
        await using var h = await HarnessAsync();
        var tokens = Assert.IsType<IssuedTokens>(await h.Service.GuestAsync(h.Device, Ct));
        Assert.True(tokens.IsAnonymous);
        Assert.Equal(43, tokens.RefreshToken.Length);
        Assert.NotNull(await h.Tokens.ValidateAsync(tokens.AccessToken, Ct));
        var jwt = new JsonWebToken(tokens.AccessToken);
        var sid = Guid.Parse(jwt.GetClaim("sid").Value);
        Assert.NotNull(await h.Store.ReadSessionAsync(tokens.UserId, sid, Ct));
        await h.Store.RevokeAsync(tokens.UserId, sid, Ct);
        Assert.Null(await h.Store.ReadSessionAsync(tokens.UserId, sid, Ct));
        Assert.Null(await h.Service.RefreshAsync(tokens.RefreshToken, Ct));
    }
    [Fact]
    public async Task Refresh_rotates_and_reuse_revokes_new_token_and_access_session()
    {
        await using var h = await HarnessAsync();
        var first = (await h.Service.GuestAsync(h.Device, Ct))!;
        var second = (await h.Service.RefreshAsync(first.RefreshToken, Ct))!;
        Assert.NotEqual(first.RefreshToken, second.RefreshToken);
        Assert.Null(await h.Service.RefreshAsync(first.RefreshToken, Ct));
        Assert.Null(await h.Service.RefreshAsync(second.RefreshToken, Ct));
        var sid = Guid.Parse(new JsonWebToken(second.AccessToken).GetClaim("sid").Value);
        Assert.Null(await h.Store.ReadSessionAsync(second.UserId, sid, Ct));
    }
    [Fact]
    public async Task Concurrent_refresh_reuses_the_family_and_never_issues_two_live_successors()
    {
        await using var h = await HarnessAsync();
        var first = (await h.Service.GuestAsync(h.Device, Ct))!;
        var results = await Task.WhenAll(h.Service.RefreshAsync(first.RefreshToken, Ct), h.Service.RefreshAsync(first.RefreshToken, Ct));
        var successor = Assert.Single(results, r => r is not null)!;
        Assert.Null(await h.Service.RefreshAsync(successor.RefreshToken, Ct));
    }
    [Fact]
    public async Task Refresh_family_has_absolute_thirty_day_expiry()
    {
        await using var h = await HarnessAsync();
        var first = (await h.Service.GuestAsync(h.Device, Ct))!;
        h.Clock.Advance(TimeSpan.FromDays(29));
        var second = (await h.Service.RefreshAsync(first.RefreshToken, Ct))!;
        Assert.Equal(first.RefreshExpiresAt, second.RefreshExpiresAt);
        h.Clock.Advance(TimeSpan.FromDays(2));
        Assert.Null(await h.Service.RefreshAsync(second.RefreshToken, Ct));
    }
    [Fact]
    public async Task Google_identity_is_subject_based_and_does_not_auto_link_matching_email()
    {
        await using var h = await HarnessAsync();
        var subject = "valid-" + Guid.NewGuid();
        var first = (await h.Service.GoogleAsync(subject, h.Device, Ct))!;
        var again = (await h.Service.GoogleAsync(subject, h.Device, Ct))!;
        var other = (await h.Service.GoogleAsync("valid-" + Guid.NewGuid(), h.Device, Ct))!;
        Assert.False(first.IsAnonymous);
        Assert.Equal(first.UserId, again.UserId);
        Assert.NotEqual(first.UserId, other.UserId);
        Assert.Null(await h.Service.GoogleAsync("invalid-proof", h.Device, Ct));
    }
    [Fact]
    public async Task Google_link_preserves_id_revokes_guest_credentials_and_conflict_never_transfers_identity()
    {
        await using var h = await HarnessAsync();
        var guest = await h.GuestAsync();
        var subject = "valid-" + Guid.NewGuid();
        var linked = (await h.Service.LinkAsync(guest, "google", subject, null, null, h.Device, Ct))!;
        Assert.Equal(guest.UserId, linked.UserId);
        Assert.False(linked.IsAnonymous);
        Assert.Null(await h.Store.ReadSessionAsync(guest.UserId, guest.SessionId, Ct));
        var second = await h.GuestAsync();
        await Assert.ThrowsAsync<IdentityConflictException>(() => h.Service.LinkAsync(second, "google", subject, null, null, h.Device, Ct));
        Assert.NotNull(await h.Store.ReadSessionAsync(second.UserId, second.SessionId, Ct));
    }
    [Fact]
    public async Task Different_guest_sessions_cannot_both_link_concurrently()
    {
        await using var h = await HarnessAsync();
        var guest = await h.GuestAsync();
        // Test-only migrator seeds a second session for the same guest; API has no such capability.
        var m = h.Material();
        await using var source = FitnessBuddy.BuildingBlocks.Persistence.DatabaseConfiguration.CreateSource(postgres.MigratorConnection);
        await using var command = source.CreateCommand("SELECT * FROM identity.new_session($1,$2,$3,$4,$5)");
        command.Parameters.AddWithValue(guest.UserId); command.Parameters.AddWithValue(m.SessionId); command.Parameters.AddWithValue(m.DeviceId); command.Parameters.AddWithValue(m.RefreshHash); command.Parameters.AddWithValue(h.Clock.GetUtcNow());
        await command.ExecuteNonQueryAsync(Ct);
        var other = (await h.Store.ReadSessionAsync(guest.UserId, m.SessionId, Ct))!;
        var results = await Task.WhenAll(h.Service.LinkAsync(guest, "google", "valid-" + Guid.NewGuid(), null, null, h.Device, Ct), h.Service.LinkAsync(other, "google", "valid-" + Guid.NewGuid(), null, null, h.Device, Ct));
        Assert.Single(results, r => r is not null);
        Assert.Null(await h.Store.ReadSessionAsync(guest.UserId, guest.SessionId, Ct));
        Assert.Null(await h.Store.ReadSessionAsync(other.UserId, other.SessionId, Ct));
    }
    [Fact]
    public async Task Email_sign_in_consumes_code_once_and_normalizes_address()
    {
        await using var h = await HarnessAsync();
        var email = Guid.NewGuid() + "@example.invalid";
        var start = await h.Service.StartEmailAsync(email, "signIn", null, Guid.NewGuid().ToString(), Ct);
        var first = (await h.Service.VerifyEmailAsync(start.Id, h.Email.Code, h.Device, Ct))!;
        Assert.False(first.IsAnonymous);
        Assert.Null(await h.Service.VerifyEmailAsync(start.Id, h.Email.Code, h.Device, Ct));
        h.Clock.Advance(TimeSpan.FromMinutes(2));
        var again = await h.Service.StartEmailAsync(email.ToUpperInvariant(), "signIn", null, Guid.NewGuid().ToString(), Ct);
        Assert.Equal(first.UserId, (await h.Service.VerifyEmailAsync(again.Id, h.Email.Code, h.Device, Ct))!.UserId);
    }
    [Fact]
    public async Task Email_wrong_attempts_persist_and_expired_codes_are_rejected()
    {
        await using var h = await HarnessAsync();
        var start = await h.Service.StartEmailAsync(Guid.NewGuid() + "@example.invalid", "signIn", null, Guid.NewGuid().ToString(), Ct);
        var right = h.Email.Code;
        var wrong = right == "000000" ? "999999" : "000000";
        for (var i = 0; i < 5; i++) { Assert.Null(await h.Service.VerifyEmailAsync(start.Id, wrong, h.Device, Ct)); }
        Assert.Null(await h.Service.VerifyEmailAsync(start.Id, right, h.Device, Ct));
        var expired = await h.Service.StartEmailAsync(Guid.NewGuid() + "@example.invalid", "signIn", null, Guid.NewGuid().ToString(), Ct);
        h.Clock.Advance(TimeSpan.FromMinutes(11));
        Assert.Null(await h.Service.VerifyEmailAsync(expired.Id, h.Email.Code, h.Device, Ct));
    }
    [Fact]
    public async Task Email_throttles_are_persistent_and_newest_challenge_invalidates_previous()
    {
        await using var h = await HarnessAsync();
        var address = Guid.NewGuid() + "@example.invalid";
        var first = await h.Service.StartEmailAsync(address, "signIn", null, Guid.NewGuid().ToString(), Ct);
        var code = h.Email.Code;
        var denied = await h.Service.StartEmailAsync(address, "signIn", null, Guid.NewGuid().ToString(), Ct);
        Assert.Equal(1, h.Email.Count);
        Assert.Null(await h.Service.VerifyEmailAsync(denied.Id, code, h.Device, Ct));
        h.Clock.Advance(TimeSpan.FromMinutes(2));
        await h.Service.StartEmailAsync(address, "signIn", null, Guid.NewGuid().ToString(), Ct);
        Assert.Equal(2, h.Email.Count);
        Assert.Null(await h.Service.VerifyEmailAsync(first.Id, code, h.Device, Ct));
    }
    [Fact]
    public async Task Email_link_proof_is_bound_to_purpose_and_guest_session()
    {
        await using var h = await HarnessAsync();
        var guest = await h.GuestAsync(); var other = await h.GuestAsync();
        var start = await h.Service.StartEmailAsync(Guid.NewGuid() + "@example.invalid", "link", guest, Guid.NewGuid().ToString(), Ct);
        var code = h.Email.Code;
        Assert.Null(await h.Service.VerifyEmailAsync(start.Id, code, h.Device, Ct));
        Assert.Null(await h.Service.LinkAsync(other, "email", null, start.Id, code, h.Device, Ct));
        var linked = (await h.Service.LinkAsync(guest, "email", null, start.Id, code, h.Device, Ct))!;
        Assert.Equal(guest.UserId, linked.UserId);
        Assert.False(linked.IsAnonymous);
    }
    [Fact]
    public async Task Simultaneous_email_consumption_issues_only_one_session()
    {
        await using var h = await HarnessAsync();
        var start = await h.Service.StartEmailAsync(Guid.NewGuid() + "@example.invalid", "signIn", null, Guid.NewGuid().ToString(), Ct);
        var results = await Task.WhenAll(h.Service.VerifyEmailAsync(start.Id, h.Email.Code, h.Device, Ct), h.Service.VerifyEmailAsync(start.Id, h.Email.Code, h.Device, Ct));
        Assert.Single(results, result => result is not null);
    }
    [Fact]
    public async Task Simultaneous_email_and_google_upgrade_share_the_same_user_lock()
    {
        await using var h = await HarnessAsync(); var guest = await h.GuestAsync();
        var start = await h.Service.StartEmailAsync(Guid.NewGuid() + "@example.invalid", "link", guest, Guid.NewGuid().ToString(), Ct);
        var results = await Task.WhenAll(h.Service.LinkAsync(guest, "email", null, start.Id, h.Email.Code, h.Device, Ct), h.Service.LinkAsync(guest, "google", "valid-" + Guid.NewGuid(), null, null, h.Device, Ct));
        Assert.Single(results, result => result is not null);
    }
    [Fact]
    public async Task Logout_refresh_and_link_race_never_leave_old_guest_credentials_live()
    {
        await using var h = await HarnessAsync(); var first = (await h.Service.GuestAsync(h.Device, Ct))!;
        var sid = Guid.Parse(new JsonWebToken(first.AccessToken).GetClaim("sid").Value);
        var guest = (await h.Store.ReadSessionAsync(first.UserId, sid, Ct))!;
        var link = h.Service.LinkAsync(guest, "google", "valid-" + Guid.NewGuid(), null, null, h.Device, Ct);
        var refresh = h.Service.RefreshAsync(first.RefreshToken, Ct);
        var logout = h.Store.RevokeAsync(first.UserId, sid, Ct);
        await Task.WhenAll(link, refresh, logout);
        Assert.Null(await h.Store.ReadSessionAsync(first.UserId, sid, Ct));
        Assert.Null(await h.Service.RefreshAsync(first.RefreshToken, Ct));
        if (await link is { } linked) { Assert.Equal(first.UserId, linked.UserId); Assert.False(linked.IsAnonymous); }
    }

    [Fact]
    [Trait("Rule", "04.6-authz")]
    public async Task Guessed_session_ids_and_direct_table_or_helper_access_are_denied()
    {
        await using var h = await HarnessAsync();
        var a = await h.GuestAsync(); var b = await h.GuestAsync();
        Assert.Null(await h.Store.ReadSessionAsync(a.UserId, b.SessionId, Ct));
        await h.Store.RevokeAsync(a.UserId, b.SessionId, Ct);
        Assert.NotNull(await h.Store.ReadSessionAsync(b.UserId, b.SessionId, Ct));
        foreach (var sql in new[] { "SELECT * FROM identity.users", "SELECT * FROM identity.refresh_tokens", "SELECT * FROM identity.signing_keys", "SELECT identity.take_throttle(decode('00','hex'),100,0,now())", "SELECT * FROM identity.new_session(gen_random_uuid(),gen_random_uuid(),gen_random_uuid(),decode(repeat('00',32),'hex'),now())" })
        {
            await using var command = postgres.App.CreateCommand(sql);
            var error = await Assert.ThrowsAsync<PostgresException>(() => command.ExecuteNonQueryAsync(Ct));
            Assert.Equal("42501", error.SqlState);
        }
        await using var check = postgres.App.CreateCommand("SELECT rolbypassrls OR rolsuper FROM pg_roles WHERE rolname=current_user");
        Assert.False((bool)(await check.ExecuteScalarAsync(Ct))!);
    }
    [Fact]
    [Trait("Rule", "04.5-tokens")]
    public async Task Signing_rotation_overlaps_and_wrapping_rotation_preserves_old_tokens()
    {
        await using var h = await HarnessAsync();
        var guest = await h.GuestAsync();
        var old = await h.Tokens.SignAsync(guest, Ct);
        await IdentityModule.MaintainSigningKeysAsync(postgres.MigratorConnection, h.DirectoryPath, "v1", "rotate", h.Clock, Ct);
        var current = await h.Tokens.SignAsync(guest, Ct);
        Assert.NotEqual(new JsonWebToken(old).Kid, new JsonWebToken(current).Kid);
        Assert.NotNull(await h.Tokens.ValidateAsync(old, Ct));
        Assert.NotNull(await h.Tokens.ValidateAsync(current, Ct));
        await IdentityModule.MaintainSigningKeysAsync(postgres.MigratorConnection, h.DirectoryPath, "v2", "rewrap", h.Clock, Ct);
        Assert.NotNull(await h.Tokens.ValidateAsync(old, Ct));
        Assert.NotNull(await h.Tokens.ValidateAsync(await h.Tokens.SignAsync(guest, Ct), Ct));
        h.Clock.Advance(TimeSpan.FromMinutes(16));
        Assert.Null(await h.Tokens.ValidateAsync(old, Ct));
    }
}
