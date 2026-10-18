using System.Security.Cryptography;

namespace FitnessBuddy.Modules.Identity.Infrastructure;

internal static class IdentitySecrets
{
    // External secrets must never accidentally become repo files or world-readable mounts.
    public static byte[] ReadKey(string path)
    {
        if (!Path.IsPathFullyQualified(path)) { throw new InvalidOperationException("Identity secret must be an absolute path."); }
        var file = new FileInfo(path);
        if (file.LinkTarget is not null || !file.Exists) { throw new InvalidOperationException("Identity secret is missing or linked."); }
        if (!OperatingSystem.IsWindows() && (File.GetUnixFileMode(path) & (UnixFileMode.GroupRead | UnixFileMode.GroupWrite | UnixFileMode.GroupExecute | UnixFileMode.OtherRead | UnixFileMode.OtherWrite | UnixFileMode.OtherExecute)) != 0)
        {
            throw new InvalidOperationException("Identity secret permissions must be private.");
        }
        var bytes = File.ReadAllBytes(path);
        if (bytes.Length != 32) { CryptographicOperations.ZeroMemory(bytes); throw new InvalidOperationException("Identity secret must contain 32 bytes."); }
        return bytes;
    }
}
