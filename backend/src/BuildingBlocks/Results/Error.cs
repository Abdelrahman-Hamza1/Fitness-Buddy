using System.Diagnostics.CodeAnalysis;

namespace FitnessBuddy.BuildingBlocks.Results;

/// <summary>The kind of an expected failure. It decides the HTTP status and problem type.</summary>
public enum ErrorKind
{
    Validation,
    NotFound,
    Conflict,
    VersionConflict,
    Unauthorized,
    Forbidden,
}

/// <summary>
/// An expected failure, returned in a <see cref="Result"/> instead of thrown.
/// <paramref name="Code"/> is a stable machine-readable code for logs and tests (never sent to clients);
/// <paramref name="Detail"/> becomes the problem's <c>detail</c>, so it must be English and contain no user content.
/// </summary>
/// <param name="Kind">What went wrong.</param>
/// <param name="Code">Stable code, e.g. <c>account.not_found</c>.</param>
/// <param name="Detail">Optional explanation for the client.</param>
/// <param name="FieldErrors">Field → messages, for <see cref="ErrorKind.Validation"/>.</param>
[SuppressMessage("Naming", "CA1716:Identifiers should not match keywords", Justification = "C#-only solution: VB's Error keyword doesn't apply.")]
public sealed record Error(
    ErrorKind Kind,
    string Code,
    string? Detail = null,
    IReadOnlyDictionary<string, string[]>? FieldErrors = null)
{
    public static Error Validation(string code, IReadOnlyDictionary<string, string[]> fieldErrors, string? detail = null) =>
        new(ErrorKind.Validation, code, detail, fieldErrors);

    public static Error NotFound(string code, string? detail = null) => new(ErrorKind.NotFound, code, detail);

    public static Error Conflict(string code, string? detail = null) => new(ErrorKind.Conflict, code, detail);

    public static Error VersionConflict(string code, string? detail = null) => new(ErrorKind.VersionConflict, code, detail);

    public static Error Unauthorized(string code, string? detail = null) => new(ErrorKind.Unauthorized, code, detail);

    public static Error Forbidden(string code, string? detail = null) => new(ErrorKind.Forbidden, code, detail);
}
