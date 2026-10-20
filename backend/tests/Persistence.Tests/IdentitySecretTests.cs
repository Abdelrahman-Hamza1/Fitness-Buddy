using System.Security.Cryptography;
using FitnessBuddy.Modules.Identity.Infrastructure;
using Microsoft.Extensions.Options;

namespace FitnessBuddy.Persistence.Tests;

[Trait("Req", "AC-041")]
[Trait("Rule", "09.4-privacy")]
public sealed class IdentitySecretTests(PostgresFixture postgres)
{
    [Fact]
    public async Task Local_sender_is_explicit_private_bounded_and_prunes_expired_files()
    {
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        var options = h.Options;
        options.Email.LocalFile.Directory = h.DirectoryPath;
        var sender = new LocalFileEmailSender(Options.Create(options), h.Clock);
        await Assert.ThrowsAsync<InvalidOperationException>(() => sender.SendAsync(Guid.NewGuid(), "private@example.invalid", "123456", h.Clock.GetUtcNow().AddMinutes(10), TestContext.Current.CancellationToken));
        options.Email.LocalFile.Enabled = true;
        await Assert.ThrowsAsync<InvalidOperationException>(() => sender.SendAsync(Guid.NewGuid(), "private@example.invalid", "123456", h.Clock.GetUtcNow().AddMinutes(10), TestContext.Current.CancellationToken));
        options.PrivateLaptop = true;
        var challenge = Guid.NewGuid();
        await sender.SendAsync(challenge, "private@example.invalid", "123456", h.Clock.GetUtcNow().AddMinutes(10), TestContext.Current.CancellationToken);
        var file = Path.Combine(h.DirectoryPath, challenge + ".json");
        Assert.True(File.Exists(file));
        if (!OperatingSystem.IsWindows()) { Assert.Equal(UnixFileMode.UserRead | UnixFileMode.UserWrite, File.GetUnixFileMode(file)); }
        File.SetLastWriteTimeUtc(file, h.Clock.GetUtcNow().AddDays(1).UtcDateTime);
        h.Clock.Advance(TimeSpan.FromMinutes(11));
        EmailFileReaper.Prune(h.DirectoryPath, h.Clock);
        Assert.False(File.Exists(file));
    }
    [Fact]
    public async Task Local_delivery_startup_prunes_expired_files_and_refuses_unwritable_cleanup_before_start()
    {
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        h.Options.PrivateLaptop = true; h.Options.Email.LocalFile.Enabled = true; h.Options.Email.LocalFile.Directory = h.DirectoryPath;
        var challenge = Guid.NewGuid();
        await new LocalFileEmailSender(Options.Create(h.Options), h.Clock).SendAsync(challenge, "private@example.invalid", "123456", h.Clock.GetUtcNow().AddMinutes(10), TestContext.Current.CancellationToken);
        var file = Path.Combine(h.DirectoryPath, challenge + ".json");
        File.SetLastWriteTimeUtc(file, h.Clock.GetUtcNow().AddDays(1).UtcDateTime);
        h.Clock.Advance(TimeSpan.FromMinutes(11)); // A stopped process may miss every scheduled sweep.
        using (var restarted = new EmailFileReaper(Options.Create(h.Options), h.Clock))
        {
            await restarted.StartAsync(TestContext.Current.CancellationToken);
            Assert.False(File.Exists(file));
            await restarted.StopAsync(TestContext.Current.CancellationToken);
        }
        if (!OperatingSystem.IsWindows())
        {
            File.SetUnixFileMode(h.DirectoryPath, UnixFileMode.UserRead | UnixFileMode.UserExecute);
            try
            {
                using var blocked = new EmailFileReaper(Options.Create(h.Options), h.Clock);
                await Assert.ThrowsAsync<InvalidOperationException>(() => blocked.StartAsync(TestContext.Current.CancellationToken));
            }
            finally { File.SetUnixFileMode(h.DirectoryPath, UnixFileMode.UserRead | UnixFileMode.UserWrite | UnixFileMode.UserExecute); }
        }
    }

    [Fact]
    public async Task Missing_wrong_and_public_wrapping_secrets_fail_without_replacing_material()
    {
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        Assert.Throws<InvalidOperationException>(() => IdentitySecrets.ReadKey(Path.Combine(h.DirectoryPath, "missing")));
        var file = Path.Combine(h.DirectoryPath, "wrong");
        await File.WriteAllBytesAsync(file, RandomNumberGenerator.GetBytes(31), TestContext.Current.CancellationToken);
        if (!OperatingSystem.IsWindows()) { File.SetUnixFileMode(file, UnixFileMode.UserRead | UnixFileMode.UserWrite); }
        Assert.Throws<InvalidOperationException>(() => IdentitySecrets.ReadKey(file));
        if (!OperatingSystem.IsWindows())
        {
            File.SetUnixFileMode(file, UnixFileMode.UserRead | UnixFileMode.GroupRead);
            Assert.Throws<InvalidOperationException>(() => IdentitySecrets.ReadKey(file));
        }
    }
}
