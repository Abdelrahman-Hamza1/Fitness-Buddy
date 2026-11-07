using System.Buffers.Text;
using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using FitnessBuddy.Modules.Buddy.Application;
using Microsoft.Extensions.Options;

namespace FitnessBuddy.Modules.Buddy.Infrastructure;

/// <summary>
/// AES-256-GCM continuation (TD-125). The key is a private file outside git (<c>Buddy:Agent:SealKeyFile</c>, base64 of 32 bytes),
/// read once and never logged. Associated data binds the API version, user, turn and round, so a continuation can't be
/// replayed for another account, turn or round. Expiry and the ledger state are checked by the caller.
/// </summary>
internal sealed class AesGcmContinuationSealer : IContinuationSealer, IDisposable
{
    private const string Prefix = "c1.";
    private const string ApiVersion = "v1";
    internal static readonly JsonSerializerOptions Json = new(JsonSerializerDefaults.Web)
    {
        Converters = { new JsonStringEnumConverter(JsonNamingPolicy.CamelCase) },
        NumberHandling = JsonNumberHandling.AllowNamedFloatingPointLiterals,
    };
    private readonly AesGcm? aes;

    public AesGcmContinuationSealer(IOptions<BuddyAgentOptions> options, IOptions<BuddyOptions> buddy)
    {
        var path = options.Value.SealKeyFile;
        if (!buddy.Value.Enabled || path.Length == 0) { return; }
        aes = new AesGcm(ReadKey(path), 16);
    }

    internal AesGcmContinuationSealer(byte[] key) => aes = new AesGcm(key, 16);

    public bool Available => aes is not null;

    public string Seal(ContinuationState state)
    {
        var gcm = aes ?? throw new InvalidOperationException("The Buddy agent has no continuation key.");
        var plain = JsonSerializer.SerializeToUtf8Bytes(state, Json);
        var output = new byte[12 + plain.Length + 16];
        RandomNumberGenerator.Fill(output.AsSpan(0, 12));
        gcm.Encrypt(output.AsSpan(0, 12), plain, output.AsSpan(12, plain.Length), output.AsSpan(12 + plain.Length), Bind(state.UserId, state.TurnId, state.Round));
        return Prefix + Base64Url.EncodeToString(output);
    }

    public ContinuationState? Open(string sealedText, Guid userId, Guid turnId, int round)
    {
        if (aes is not { } gcm || !sealedText.StartsWith(Prefix, StringComparison.Ordinal)) { return null; }
        byte[] data;
        try { data = Base64Url.DecodeFromChars(sealedText.AsSpan(Prefix.Length)); }
        catch (FormatException) { return null; }
        if (data.Length < 12 + 16 + 2) { return null; }
        var plain = new byte[data.Length - 28];
        try { gcm.Decrypt(data.AsSpan(0, 12), data.AsSpan(12, plain.Length), data.AsSpan(12 + plain.Length), plain, Bind(userId, turnId, round)); }
        catch (AuthenticationTagMismatchException) { return null; }
        var state = JsonSerializer.Deserialize<ContinuationState>(plain, Json);
        return state is { Version: 1 } && state.UserId == userId && state.TurnId == turnId && state.Round == round ? state : null;
    }

    public void Dispose() => aes?.Dispose();

    private static byte[] Bind(Guid userId, Guid turnId, int round) => Encoding.UTF8.GetBytes(string.Create(CultureInfo.InvariantCulture,
        $"fitness-buddy/buddy-continuation|api:{ApiVersion}|{userId:D}|{turnId:D}|{round}"));

    private static byte[] ReadKey(string path)
    {
        var file = new FileInfo(path);
        if (!file.Exists || file.LinkTarget is not null || file.Length is < 40 or > 128
            || !OperatingSystem.IsWindows() && (File.GetUnixFileMode(file.FullName) & (UnixFileMode)63) != 0)
        { throw new InvalidOperationException("Buddy continuation key is missing or not private."); }
        byte[] key;
        try { key = Convert.FromBase64String(File.ReadAllText(file.FullName).Trim()); }
        catch (FormatException) { throw new InvalidOperationException("Invalid Buddy continuation key file."); }
        return key.Length == 32 ? key : throw new InvalidOperationException("Invalid Buddy continuation key file.");
    }
}
