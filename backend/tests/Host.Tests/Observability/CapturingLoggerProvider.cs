using System.Collections.Concurrent;
using Microsoft.Extensions.Logging;

namespace FitnessBuddy.Host.Tests.Observability;

internal sealed class CapturingLoggerProvider : ILoggerProvider, ISupportExternalScope, IAsyncDisposable
{
    private IExternalScopeProvider scopes = new LoggerExternalScopeProvider();

    public ConcurrentQueue<string> Lines { get; } = new();

    public bool Disposed { get; private set; }

    public TaskCompletionSource Disposal { get; } = new(TaskCreationOptions.RunContinuationsAsynchronously);

    public ILogger CreateLogger(string categoryName) => new CapturingLogger(this);

    public void SetScopeProvider(IExternalScopeProvider scopeProvider) => scopes = scopeProvider;

    public void Dispose()
    {
        Disposed = true;
        Disposal.TrySetResult();
    }

    public ValueTask DisposeAsync()
    {
        Dispose();
        return ValueTask.CompletedTask;
    }

    private sealed class CapturingLogger(CapturingLoggerProvider owner) : ILogger
    {
        public IDisposable? BeginScope<TState>(TState state) where TState : notnull => owner.scopes.Push(state);

        public bool IsEnabled(LogLevel logLevel) => true;

        public void Log<TState>(LogLevel logLevel, EventId eventId, TState state, Exception? exception,
            Func<TState, Exception?, string> formatter)
        {
            var parts = new List<string> { formatter(state, exception), $"{exception}" };
            AddState(state, parts);
            owner.scopes.ForEachScope((scope, lines) => AddState(scope, lines), parts);
            owner.Lines.Enqueue(string.Join('\n', parts));
        }

        private static void AddState(object? state, List<string> parts)
        {
            parts.Add($"{state}");
            if (state is IEnumerable<KeyValuePair<string, object?>> values)
            {
                parts.AddRange(values.Select(pair => $"{pair.Key}={pair.Value}"));
            }
        }
    }
}
