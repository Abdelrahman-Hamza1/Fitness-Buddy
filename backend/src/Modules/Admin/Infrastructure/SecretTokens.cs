using System.Security.Cryptography;
using System.Text;
using FitnessBuddy.Modules.Admin.Application;

namespace FitnessBuddy.Modules.Admin.Infrastructure;

internal sealed class SecretTokens : ISecretTokens
{
    public byte[] NewSecret() => RandomNumberGenerator.GetBytes(32);

    public byte[] Hash(ReadOnlySpan<byte> value) => SHA256.HashData(value);

    public byte[] Hash(string value) => SHA256.HashData(Encoding.UTF8.GetBytes(value));
}
