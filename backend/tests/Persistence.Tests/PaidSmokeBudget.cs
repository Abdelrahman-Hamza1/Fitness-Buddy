using System.Text;

namespace FitnessBuddy.Persistence.Tests;

// Provisioned once outside the test with an fsynced file + parent directory. Never recreate or reset.
// Each byte is a conservative physical-send reservation; a crash can overcount, never erase history.
internal static class PaidSmokeBudget
{
    private static readonly byte[] Header = Encoding.ASCII.GetBytes("B08-max10\n");

    internal static int Count(string path)
    {
        using var file = Open(path);
        return ReadCount(file);
    }

    internal static void Reserve(string path)
    {
        using var file = Open(path);
        if (ReadCount(file) >= 10) { throw new HttpRequestException("Live request budget exhausted."); }
        file.Seek(0, SeekOrigin.End);
        file.WriteByte((byte)'1');
        file.Flush(flushToDisk: true);
    }

    private static FileStream Open(string path)
    {
        if (new FileInfo(path).LinkTarget is not null) { throw new HttpRequestException("Invalid live budget file."); }
        return new FileStream(path, FileMode.Open, FileAccess.ReadWrite, FileShare.None);
    }

    private static int ReadCount(FileStream file)
    {
        if (file.Length < Header.Length || file.Length > Header.Length + 10) { throw new HttpRequestException("Invalid live budget ledger."); }
        var bytes = new byte[(int)file.Length];
        file.ReadExactly(bytes);
        if (!bytes.AsSpan(0, Header.Length).SequenceEqual(Header)
            || bytes.AsSpan(Header.Length).ContainsAnyExcept((byte)'1')) { throw new HttpRequestException("Invalid live budget ledger."); }
        return bytes.Length - Header.Length;
    }
}

public sealed class PaidSmokeBudgetTests
{
    [Fact]
    [Trait("Rule", "PROCESS.A6-owner-paid-scope")]
    public void Reservations_survive_reopen_and_exhaust_without_reset()
    {
        var path = Path.GetTempFileName();
        try
        {
            File.WriteAllText(path, "B08-max10\n11111111");
            PaidSmokeBudget.Reserve(path);
            Assert.Equal(9, PaidSmokeBudget.Count(path));
            PaidSmokeBudget.Reserve(path);
            Assert.Equal(10, PaidSmokeBudget.Count(path));
            Assert.Throws<HttpRequestException>(() => PaidSmokeBudget.Reserve(path));
            Assert.Equal("B08-max10\n1111111111", File.ReadAllText(path));
        }
        finally { File.Delete(path); }
    }

    [Theory]
    [InlineData("")]
    [InlineData("8")]
    [InlineData("B08-max10")]
    [InlineData("B08-max10\n111x")]
    [InlineData("B08-max10\n11111111111")]
    [Trait("Rule", "PROCESS.A6-owner-paid-scope")]
    public void Corrupt_or_truncated_state_fails_closed(string contents)
    {
        var path = Path.GetTempFileName();
        try
        {
            File.WriteAllText(path, contents);
            Assert.Throws<HttpRequestException>(() => PaidSmokeBudget.Reserve(path));
            Assert.Equal(contents, File.ReadAllText(path));
        }
        finally { File.Delete(path); }
    }
}
