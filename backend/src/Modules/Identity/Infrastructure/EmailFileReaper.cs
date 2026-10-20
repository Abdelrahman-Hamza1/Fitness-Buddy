using System.Text.Json;
using FitnessBuddy.Modules.Identity.Application;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Options;

namespace FitnessBuddy.Modules.Identity.Infrastructure;

internal sealed class EmailFileReaper(IOptions<IdentityOptions> options, TimeProvider clock) : BackgroundService
{
    private bool Enabled => options.Value.Enabled && options.Value.PrivateLaptop && options.Value.Email.LocalFile.Enabled;

    public override Task StartAsync(CancellationToken cancellationToken)
    {
        // .NET10 runs ExecuteAsync entirely in the background; its first sweep is not a startup gate.
        if (Enabled) { Prune(options.Value.Email.LocalFile.Directory, clock); }
        return base.StartAsync(cancellationToken);
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        if (!Enabled) { return; }
        using var timer = new PeriodicTimer(TimeSpan.FromMinutes(1), clock);
        while (await timer.WaitForNextTickAsync(stoppingToken)) { Prune(options.Value.Email.LocalFile.Directory, clock); }
    }

    internal static void ValidateDirectory(string path)
    {
        if (!Path.IsPathFullyQualified(path) || !Directory.Exists(path)) { throw new InvalidOperationException("Invalid private email directory."); }
        for (var part = new DirectoryInfo(path); part is not null; part = part.Parent)
        { if (part.LinkTarget is not null) { throw new InvalidOperationException("Linked email directories are forbidden."); } }
        if (!OperatingSystem.IsWindows() && File.GetUnixFileMode(path) != (UnixFileMode.UserRead | UnixFileMode.UserWrite | UnixFileMode.UserExecute))
        { throw new InvalidOperationException("Email directory must be private and writable."); }
        var probe = Path.Combine(path, ".cleanup-" + Convert.ToHexStringLower(System.Security.Cryptography.RandomNumberGenerator.GetBytes(16)));
        var settings = new FileStreamOptions { Mode = FileMode.CreateNew, Access = FileAccess.Write, Share = FileShare.None, Options = FileOptions.DeleteOnClose };
        if (!OperatingSystem.IsWindows()) { settings.UnixCreateMode = UnixFileMode.UserRead | UnixFileMode.UserWrite; }
        using var writable = new FileStream(probe, settings);
    }

    internal static void Prune(string path, TimeProvider clock)
    {
        ValidateDirectory(path);
        var count = 0;
        foreach (var file in new DirectoryInfo(path).EnumerateFiles("*.json"))
        {
            try
            {
                if (file.LinkTarget is not null || file.Length > 4096 ||
                    (!OperatingSystem.IsWindows() && File.GetUnixFileMode(file.FullName) != (UnixFileMode.UserRead | UnixFileMode.UserWrite)))
                { throw new InvalidOperationException("Invalid local delivery state."); }
                using var content = JsonDocument.Parse(File.ReadAllBytes(file.FullName));
                if (!content.RootElement.TryGetProperty("expiresAt", out var expiry) || !expiry.TryGetDateTimeOffset(out var expiresAt))
                { throw new InvalidOperationException("Invalid local delivery state."); }
                if (expiresAt <= clock.GetUtcNow()) { file.Delete(); }
                else if (++count > 100) { throw new InvalidOperationException("Local email delivery capacity reached."); }
            }
            catch (FileNotFoundException) { } // Another process may have reaped the same expired delivery.
            catch (JsonException) { throw new InvalidOperationException("Invalid local delivery state."); }
        }
        // Atomic send can leave an unfinished, unissued file after a crash. Never remove a live writer's temp.
        foreach (var file in new DirectoryInfo(path).EnumerateFiles(".pending-*.tmp"))
        {
            try
            {
                if (file.LinkTarget is not null) { throw new InvalidOperationException("Linked email files are forbidden."); }
                if (file.LastWriteTimeUtc <= clock.GetUtcNow().AddMinutes(-10).UtcDateTime) { file.Delete(); }
            }
            catch (FileNotFoundException) { }
        }
    }
}
