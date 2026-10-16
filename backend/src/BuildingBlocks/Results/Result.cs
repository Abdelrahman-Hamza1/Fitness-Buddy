namespace FitnessBuddy.BuildingBlocks.Results;

/// <summary>The outcome of an operation without a value: success, or an expected <see cref="Results.Error"/>.</summary>
public sealed class Result
{
    private static readonly Result SuccessInstance = new(null);
    private readonly Error? error;

    private Result(Error? error) => this.error = error;

    public bool IsSuccess => error is null;

    public bool IsFailure => !IsSuccess;

    /// <summary>The failure. Reading it on a success is a programming error.</summary>
    public Error Error => error ?? throw new InvalidOperationException("A successful result has no error.");

    public static Result Success() => SuccessInstance;

    public static Result Failure(Error error)
    {
        ArgumentNullException.ThrowIfNull(error);
        return new Result(error);
    }

    public static implicit operator Result(Error error) => Failure(error);
}

/// <summary>The outcome of an operation: a value, or an expected <see cref="Results.Error"/>. Exactly one of them.</summary>
public sealed class Result<T>
{
    private readonly T? value;
    private readonly Error? error;

    private Result(T? value, Error? error)
    {
        this.value = value;
        this.error = error;
    }

    public bool IsSuccess => error is null;

    public bool IsFailure => !IsSuccess;

    /// <summary>The value. Reading it on a failure is a programming error.</summary>
    public T Value => IsSuccess ? value! : throw new InvalidOperationException("A failed result has no value.");

    /// <summary>The failure. Reading it on a success is a programming error.</summary>
    public Error Error => error ?? throw new InvalidOperationException("A successful result has no error.");

#pragma warning disable CA1000 // Factory methods on the generic type read best at the call site: Result<T>.Success(x).
    public static Result<T> Success(T value) => new(value, null);

    public static Result<T> Failure(Error error)
    {
        ArgumentNullException.ThrowIfNull(error);
        return new Result<T>(default, error);
    }
#pragma warning restore CA1000

    public static implicit operator Result<T>(T value) => Success(value);

    public static implicit operator Result<T>(Error error) => Failure(error);

    public TOut Match<TOut>(Func<T, TOut> onSuccess, Func<Error, TOut> onFailure)
    {
        ArgumentNullException.ThrowIfNull(onSuccess);
        ArgumentNullException.ThrowIfNull(onFailure);
        return IsSuccess ? onSuccess(value!) : onFailure(error!);
    }
}
