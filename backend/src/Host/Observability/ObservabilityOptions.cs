namespace FitnessBuddy.Host.Observability;

internal sealed class ObservabilityOptions
{
    public const string SectionName = "Observability";

    public bool ConsoleExporter { get; set; }
}
