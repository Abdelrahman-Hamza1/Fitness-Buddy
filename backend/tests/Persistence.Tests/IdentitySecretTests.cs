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
        File.SetLastWriteTimeUtc(file, h.Clock.GetUtcNow().AddMinutes(-11).UtcDateTime);
        EmailFileReaper.Prune(h.DirectoryPath, h.Clock);
        Assert.False(File.Exists(file));
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
