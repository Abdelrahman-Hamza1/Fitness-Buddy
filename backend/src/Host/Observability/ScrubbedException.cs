namespace FitnessBuddy.Host.Observability;

/// <summary>TD-058: sinks keep exception types and stacks, never messages or Data.</summary>
internal sealed class ScrubbedException : Exception
{
    private readonly string? originalStackTrace;

    public ScrubbedException(Exception original)
        : base(original.GetType().FullName, ScrubInner(original))
    {
        originalStackTrace = original.StackTrace;
    }

    public override string? StackTrace => originalStackTrace;

    private static Exception? ScrubInner(Exception original) => original switch
    {
        AggregateException aggregate => new AggregateException(string.Empty,
            aggregate.InnerExceptions.Select(exception => new ScrubbedException(exception))),
        { InnerException: { } inner } => new ScrubbedException(inner),
        _ => null,
    };
}
