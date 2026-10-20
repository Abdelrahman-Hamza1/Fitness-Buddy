using System.Text.Json;
using FitnessBuddy.Modules.Identity.Application;
using Microsoft.Extensions.Options;

namespace FitnessBuddy.Modules.Identity.Infrastructure;

internal sealed class LocalFileEmailSender(IOptions<IdentityOptions> options, TimeProvider clock) : IEmailSender
{
    private static readonly SemaphoreSlim Gate = new(1);
    public async Task SendAsync(Guid challenge, string address, string code, DateTimeOffset expiresAt, CancellationToken ct)
    {
        var settings = options.Value;
        if (!settings.Email.LocalFile.Enabled || !settings.PrivateLaptop || !Path.IsPathFullyQualified(settings.Email.LocalFile.Directory))
        { throw new InvalidOperationException("No email sender configured."); }
        await Gate.WaitAsync(ct);
        try
        {
            var directory = settings.Email.LocalFile.Directory;
            EmailFileReaper.Prune(directory, clock);
            if (Directory.EnumerateFiles(directory, "*.json").Count() >= 100) { throw new InvalidOperationException("Local email delivery capacity reached."); }
            var path = Path.Combine(directory, challenge + ".json");
            var temporary = Path.Combine(directory, ".pending-" + Convert.ToHexStringLower(System.Security.Cryptography.RandomNumberGenerator.GetBytes(16)) + ".tmp");
            try
            {
                var fileOptions = new FileStreamOptions { Access = FileAccess.Write, Mode = FileMode.CreateNew, Share = FileShare.None, Options = FileOptions.Asynchronous };
                if (!OperatingSystem.IsWindows()) { fileOptions.UnixCreateMode = UnixFileMode.UserRead | UnixFileMode.UserWrite; }
                await using (var output = new FileStream(temporary, fileOptions))
                {
                    await JsonSerializer.SerializeAsync(output, new { address, code, expiresAt }, cancellationToken: ct);
                    await output.FlushAsync(ct);
                }
                // Reapers in another process only see complete JSON files.
                File.Move(temporary, path, overwrite: false);
            }
            finally { File.Delete(temporary); }
        }
        finally { Gate.Release(); }
    }
}
