namespace FitnessBuddy.Host.Observability;

/// <summary>TD-058: decorate each sink; Sentry instead scrubs its serialized event in BeforeSend.</summary>
internal sealed class ScrubbingLoggerProvider(ILoggerProvider inner) : ILoggerProvider, ISupportExternalScope, IAsyncDisposable
{
    public ILoggerProvider Inner { get; } = inner;

    public ILogger CreateLogger(string categoryName) => new ScrubbingLogger(Inner.CreateLogger(categoryName));

    public void SetScopeProvider(IExternalScopeProvider scopeProvider)
    {
        if (Inner is ISupportExternalScope scoped)
        {
            scoped.SetScopeProvider(new SafeScopeProvider(scopeProvider));
        }
    }

    public void Dispose() => Inner.Dispose();

    public ValueTask DisposeAsync()
    {
        if (Inner is IAsyncDisposable asyncDisposable)
        {
            return asyncDisposable.DisposeAsync();
        }

        Inner.Dispose();
        return ValueTask.CompletedTask;
    }

    private sealed class SafeScopeProvider(IExternalScopeProvider source) : IExternalScopeProvider
    {
        public void ForEachScope<TState>(Action<object?, TState> callback, TState state) => source.ForEachScope((scope, value) =>
        {
            var safe = Safe(scope);
            if (safe.Length != 0) { callback(safe, value); }
        }, state);
        public IDisposable Push(object? state) => source.Push(Safe(state));
        private static KeyValuePair<string, object?>[] Safe(object? state) => state is IEnumerable<KeyValuePair<string, object?>> fields ?
            fields.Where(field => field.Key is "TraceId" or "SpanId" or "RequestId")
                .Where(field => field.Value?.ToString() is { } text && text.Length == (field.Key == "SpanId" ? 16 : 32)
                    && text.All(character => char.IsAsciiHexDigit(character)))
                .ToArray() : [];
    }

    private sealed class ScrubbingLogger(ILogger logger) : ILogger
    {
        public IDisposable? BeginScope<TState>(TState state) where TState : notnull => logger.BeginScope(state);

        public bool IsEnabled(LogLevel logLevel) => logger.IsEnabled(logLevel);

        public void Log<TState>(LogLevel logLevel, EventId eventId, TState state, Exception? exception,
            Func<TState, Exception?, string> formatter) =>
            logger.Log(logLevel, eventId, state, exception is null ? null : new ScrubbedException(exception), formatter);
    }
}

internal static class ScrubbingLoggerRegistration
{
    public static bool IsSentryProvider(ILoggerProvider provider) =>
        (provider.GetType().Assembly.GetName().Name, provider.GetType().FullName) is
            ("Sentry.Extensions.Logging", "Sentry.Extensions.Logging.SentryLoggerProvider") or
            ("Sentry.Extensions.Logging", "Sentry.Extensions.Logging.SentryStructuredLoggerProvider") or
            ("Sentry.AspNetCore", "Sentry.AspNetCore.SentryAspNetCoreLoggerProvider") or
            ("Sentry.AspNetCore", "Sentry.AspNetCore.SentryAspNetCoreStructuredLoggerProvider");

    /// <summary>Run last, after all providers are registered. The meta test fails on any unwrapped sink.</summary>
    public static void ScrubLoggerProviders(this IServiceCollection services)
    {
        for (var index = 0; index < services.Count; index++)
        {
            var descriptor = services[index];
            if (descriptor.ServiceType != typeof(ILoggerProvider))
            {
                continue;
            }

            services[index] = ServiceDescriptor.Describe(typeof(ILoggerProvider), provider =>
            {
                var inner = (ILoggerProvider)(descriptor.ImplementationInstance
                    ?? descriptor.ImplementationFactory?.Invoke(provider)
                    ?? ActivatorUtilities.CreateInstance(provider, descriptor.ImplementationType!));
                return inner is ScrubbingLoggerProvider || IsSentryProvider(inner) ? inner : new ScrubbingLoggerProvider(inner);
            }, descriptor.Lifetime);
        }
    }
}
