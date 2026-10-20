using System.Runtime.InteropServices;

namespace FitnessBuddy.BuildingBlocks.Recovery;

/// <summary>Single-host durable generation. A successful write includes file AND directory fsync (B06 D7).</summary>
public sealed partial class RecoveryFile
{
    private readonly string directory;
    private readonly string marker;
    public RecoveryFile(string directory)
    {
        this.directory = directory;
        marker = Path.Combine(directory, "generation");
    }

    public Guid Read()
    {
        try
        {
            ValidateDirectory();
            ValidateFile(marker);
            var text = File.ReadAllText(marker);
            return text.Length == 37 && text[36] == '\n' && Guid.TryParseExact(text[..36], "D", out var id) && id != Guid.Empty
                ? id : throw new RecoveryUnavailableException();
        }
        catch (Exception exception) when (exception is IOException or UnauthorizedAccessException or ArgumentException)
        { throw new RecoveryUnavailableException(); }
    }

    public bool Exists()
    {
        ValidateDirectory();
        return File.Exists(marker) || new FileInfo(marker).LinkTarget is not null;
    }

    public void Write(Guid generation)
    {
        if (!OperatingSystem.IsLinux()) { throw new RecoveryUnavailableException(); }
        if (generation == Guid.Empty) { throw new RecoveryUnavailableException(); }
        try
        {
            ValidateDirectory();
            if (Exists()) { ValidateFile(marker); }
            var temporary = Path.Combine(directory, ".generation-" + Convert.ToHexStringLower(System.Security.Cryptography.RandomNumberGenerator.GetBytes(16)));
            try
            {
                var options = new FileStreamOptions
                {
                    Mode = FileMode.CreateNew,
                    Access = FileAccess.Write,
                    Share = FileShare.None,
                    UnixCreateMode = UnixFileMode.UserRead | UnixFileMode.UserWrite
                };
                using (var stream = new FileStream(temporary, options))
                {
                    stream.Write(System.Text.Encoding.ASCII.GetBytes(generation.ToString("D") + "\n"));
                    stream.Flush(flushToDisk: true);
                }
                File.Move(temporary, marker, overwrite: true);
                var descriptor = OpenDirectory(directory, 0x10000); // Linux O_DIRECTORY; opens read-only.
                if (descriptor < 0) { throw new RecoveryUnavailableException(); }
                try { if (Fsync(descriptor) != 0) { throw new RecoveryUnavailableException(); } }
                finally { Close(descriptor); }
            }
            finally { File.Delete(temporary); }
        }
        catch (Exception exception) when (exception is IOException or UnauthorizedAccessException or ArgumentException)
        { throw new RecoveryUnavailableException(); }
    }

    private void ValidateDirectory()
    {
        if (!OperatingSystem.IsLinux() || !Path.IsPathFullyQualified(directory)) { throw new RecoveryUnavailableException(); }
        var leaf = new DirectoryInfo(directory);
        if (!leaf.Exists || File.GetUnixFileMode(directory) != (UnixFileMode.UserRead | UnixFileMode.UserWrite | UnixFileMode.UserExecute))
        { throw new RecoveryUnavailableException(); }
        for (var part = leaf; part is not null; part = part.Parent)
        { if (part.LinkTarget is not null) { throw new RecoveryUnavailableException(); } }
    }

    private static void ValidateFile(string path)
    {
        var file = new FileInfo(path);
        if (!OperatingSystem.IsLinux() || !file.Exists || file.LinkTarget is not null || file.Length != 37 ||
            File.GetUnixFileMode(path) != (UnixFileMode.UserRead | UnixFileMode.UserWrite))
        { throw new RecoveryUnavailableException(); }
    }

    [LibraryImport("libc", EntryPoint = "open", StringMarshalling = StringMarshalling.Utf8, SetLastError = true)]
    private static partial int OpenDirectory(string path, int flags);
    [LibraryImport("libc", EntryPoint = "fsync", SetLastError = true)]
    private static partial int Fsync(int descriptor);
    [LibraryImport("libc", EntryPoint = "close", SetLastError = true)]
    private static partial int Close(int descriptor);
}
