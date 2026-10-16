using System.Security.Cryptography;
using System.Text;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Options;

namespace FitnessBuddy.Modules.UserData.Api;

internal sealed class SpikeOptions
{
    public bool Enabled { get; set; }
    public string Key { get; set; } = "";
    public Guid UserId { get; set; }
}

// A separate, opt-in environment and synthetic principal keep pre-auth spike code fail-closed.
// It never reads identity from an HTTP parameter; B04/B05 replace this with real auth.
internal sealed class SpikeAccess(IHostEnvironment environment, IOptions<SpikeOptions> options)
{
    private bool Enabled => environment.IsEnvironment("SyncSpike") && options.Value.Enabled &&
        options.Value.UserId != Guid.Empty && options.Value.Key.Length >= 64;

    public int Check(string key) => !Enabled ? 501 :
        CryptographicOperations.FixedTimeEquals(SHA256.HashData(Encoding.UTF8.GetBytes(key)),
            SHA256.HashData(Encoding.UTF8.GetBytes(options.Value.Key))) ? 200 : 401;

    public Guid UserId => options.Value.UserId;
}
