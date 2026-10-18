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
        var directory = new DirectoryInfo(settings.Email.LocalFile.Directory);
        if (!directory.Exists || directory.LinkTarget is not null) { throw new InvalidOperationException("Private email directory must be provisioned explicitly."); }
        if (!OperatingSystem.IsWindows() && (File.GetUnixFileMode(directory.FullName) & (UnixFileMode.GroupRead | UnixFileMode.GroupWrite | UnixFileMode.GroupExecute | UnixFileMode.OtherRead | UnixFileMode.OtherWrite | UnixFileMode.OtherExecute)) != 0)
        { throw new InvalidOperationException("Email directory must be private."); }
        await Gate.WaitAsync(ct);
        try
        {
            foreach (var file in directory.EnumerateFiles("*.json"))
            {
                if (file.LinkTarget is not null) { throw new InvalidOperationException("Linked email files are forbidden."); }
                if (file.LastWriteTimeUtc <= clock.GetUtcNow().AddMinutes(-10).UtcDateTime) { file.Delete(); }
            }
            if (directory.EnumerateFiles("*.json").Count() >= 100) { throw new InvalidOperationException("Local email delivery capacity reached."); }
            var path = Path.Combine(directory.FullName, challenge + ".json");
            var fileOptions = new FileStreamOptions { Access = FileAccess.Write, Mode = FileMode.CreateNew, Share = FileShare.None, Options = FileOptions.Asynchronous };
            if (!OperatingSystem.IsWindows()) { fileOptions.UnixCreateMode = UnixFileMode.UserRead | UnixFileMode.UserWrite; }
            await using var output = new FileStream(path, fileOptions);
            await JsonSerializer.SerializeAsync(output, new { address, code, expiresAt }, cancellationToken: ct);
        }
        finally { Gate.Release(); }
    }
}
