namespace FitnessBuddy.Modules.Identity.Application;

internal sealed class IdentityOptions
{
    public bool Enabled { get; set; }
    public string Issuer { get; set; } = "fitness-buddy";
    public string Audience { get; set; } = "fitness-buddy-api";
    public string WrappingKeysDirectory { get; set; } = "";
    public string PepperFile { get; set; } = "";
    public string[] GoogleClientIds { get; set; } = [];
    public IdentityEmailOptions Email { get; set; } = new();
    public bool PrivateLaptop { get; set; }
}

internal sealed class IdentityEmailOptions
{
    public IdentityLocalFileOptions LocalFile { get; set; } = new();
}
internal sealed class IdentityLocalFileOptions
{
    public bool Enabled { get; set; }
    public string Directory { get; set; } = "";
}
