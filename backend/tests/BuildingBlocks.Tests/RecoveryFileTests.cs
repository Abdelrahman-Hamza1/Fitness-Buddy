using FitnessBuddy.BuildingBlocks.Recovery;

namespace FitnessBuddy.BuildingBlocks.Tests;

public sealed class RecoveryFileTests : IDisposable
{
    private readonly string directory = Path.Combine(Path.GetTempPath(), "fb-recovery-" + Guid.NewGuid());
    public RecoveryFileTests()
    {
        Directory.CreateDirectory(directory);
        if (!OperatingSystem.IsWindows()) { File.SetUnixFileMode(directory, UnixFileMode.UserRead | UnixFileMode.UserWrite | UnixFileMode.UserExecute); }
    }

    [Fact]
    [Trait("Rule", "08.5-deletion-safe-restore")]
    public void Durable_generation_survives_reopen_and_missing_or_corrupt_state_never_reinitializes()
    {
        var file = new RecoveryFile(directory);
        Assert.Throws<RecoveryUnavailableException>(() => file.Read());
        var first = Guid.NewGuid();
        file.Write(first);
        Assert.Equal(first, new RecoveryFile(directory).Read());
        var second = Guid.NewGuid();
        file.Write(second);
        Assert.Equal(second, file.Read());
        File.WriteAllText(Path.Combine(directory, "generation"), "corrupt");
        Assert.Throws<RecoveryUnavailableException>(() => file.Read());
    }

    [Fact]
    [Trait("Rule", "09.4-private-recovery-state")]
    public void Linked_or_nonprivate_control_state_is_refused()
    {
        if (!OperatingSystem.IsLinux()) { return; }
        var file = new RecoveryFile(directory);
        file.Write(Guid.NewGuid());
        var path = Path.Combine(directory, "generation");
        File.SetUnixFileMode(path, UnixFileMode.UserRead | UnixFileMode.UserWrite | UnixFileMode.GroupRead);
        Assert.Throws<RecoveryUnavailableException>(() => file.Read());
        Assert.Throws<RecoveryUnavailableException>(() => file.Write(Guid.NewGuid()));
        File.Delete(path);
        File.CreateSymbolicLink(path, Path.Combine(directory, "missing"));
        Assert.Throws<RecoveryUnavailableException>(() => file.Read());
        Assert.Throws<RecoveryUnavailableException>(() => file.Write(Guid.NewGuid()));
    }

    public void Dispose() => Directory.Delete(directory, recursive: true);
}
