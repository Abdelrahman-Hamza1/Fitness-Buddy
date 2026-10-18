using System.Security.Cryptography;
using FitnessBuddy.BuildingBlocks.Ids;
using FitnessBuddy.Modules.Identity;
using FitnessBuddy.Modules.Identity.Application;
using FitnessBuddy.Modules.Identity.Contracts;
using FitnessBuddy.Modules.Identity.Infrastructure;

namespace FitnessBuddy.Persistence.Tests;

internal sealed class IdentityHarness(PostgresFixture postgres) : IAsyncDisposable
{
    public string DirectoryPath { get; } = Path.Combine(Path.GetTempPath(), "fb-identity-" + Guid.NewGuid());
    public TestClock Clock { get; } = new();
    public IdentityOptions Options { get; private set; } = null!;
    public IdentityTokens Tokens { get; private set; } = null!;
    public PostgresIdentityStore Store { get; private set; } = null!;
    public IdentityService Service { get; private set; } = null!;
    public CapturingEmail Email { get; } = new();
    public Guid Device { get; } = Guid.NewGuid();
    public async Task InitializeAsync()
    {
        Directory.CreateDirectory(DirectoryPath);
        if (!OperatingSystem.IsWindows()) { File.SetUnixFileMode(DirectoryPath, UnixFileMode.UserRead | UnixFileMode.UserWrite | UnixFileMode.UserExecute); }
        foreach (var name in new[] { "v1.key", "v2.key", "pepper" })
        {
            var file = Path.Combine(DirectoryPath, name); await File.WriteAllBytesAsync(file, RandomNumberGenerator.GetBytes(32), TestContext.Current.CancellationToken);
            if (!OperatingSystem.IsWindows()) { File.SetUnixFileMode(file, UnixFileMode.UserRead | UnixFileMode.UserWrite); }
        }
        Options = new IdentityOptions { Enabled = true, WrappingKeysDirectory = DirectoryPath, PepperFile = Path.Combine(DirectoryPath, "pepper"), GoogleClientIds = ["test-client"] };
        // Every fixture can decrypt the shared synthetic keyring. The test master remains private and temporary.
        await using (var command = postgres.App.CreateCommand("SELECT wrapping_version FROM identity.read_keyring() LIMIT 1"))
        {
            if (await command.ExecuteScalarAsync(TestContext.Current.CancellationToken) is string)
            {
                var shared = SharedKeys!;
                foreach (var version in new[] { "v1", "v2" }) { await File.WriteAllBytesAsync(Path.Combine(DirectoryPath, version + ".key"), shared[version], TestContext.Current.CancellationToken); }
            }
            else { SharedKeys = new Dictionary<string, byte[]> { ["v1"] = await File.ReadAllBytesAsync(Path.Combine(DirectoryPath, "v1.key"), TestContext.Current.CancellationToken), ["v2"] = await File.ReadAllBytesAsync(Path.Combine(DirectoryPath, "v2.key"), TestContext.Current.CancellationToken) }; }
        }
        await IdentityModule.MaintainSigningKeysAsync(postgres.MigratorConnection, DirectoryPath, "v1", "ensure", Clock, TestContext.Current.CancellationToken);
        Tokens = new IdentityTokens(postgres.App, Microsoft.Extensions.Options.Options.Create(Options), Clock);
        Store = new PostgresIdentityStore(postgres.App, Clock);
        Service = new IdentityService(Store, Tokens, new FakeGoogle(), Email, new UuidV7IdGenerator(Clock), Clock, Microsoft.Extensions.Options.Options.Create(Options));
    }
    private static Dictionary<string, byte[]>? SharedKeys { get; set; }
    public SessionMaterial Material() => new(Guid.NewGuid(), Device, RandomNumberGenerator.GetBytes(32));
    public async Task<IdentitySession> GuestAsync() => (await Store.CreateGuestAsync(Guid.NewGuid(), Material(), TestContext.Current.CancellationToken))!;
    public ValueTask DisposeAsync() { Directory.Delete(DirectoryPath, true); return ValueTask.CompletedTask; }
    internal sealed class FakeGoogle : IGoogleIdentityVerifier
    {
        public Task<GoogleIdentity?> VerifyAsync(string idToken, CancellationToken ct) => Task.FromResult<GoogleIdentity?>(idToken.StartsWith("valid-", StringComparison.Ordinal) ? new GoogleIdentity(idToken, "synthetic@example.invalid") : null);
    }
    internal sealed class CapturingEmail : IEmailSender
    {
        public Guid Challenge { get; private set; }
        public string Code { get; private set; } = "";
        public int Count { get; private set; }
        public Task SendAsync(Guid challenge, string address, string code, DateTimeOffset expiresAt, CancellationToken ct)
        { Challenge = challenge; Code = code; Count++; return Task.CompletedTask; }
    }
}
