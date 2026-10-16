using FitnessBuddy.BuildingBlocks.Results;
using Microsoft.AspNetCore.Http;

namespace FitnessBuddy.BuildingBlocks.Web.Problems;

/// <summary>Maps <see cref="Error"/>s to RFC 9457 problem results (04 §4.2 "Errors").</summary>
public static class ErrorResults
{
    /// <summary>
    /// Validation → 400 <c>validation-failed</c> with <c>errors</c>; VersionConflict → 412 <c>version-conflict</c>;
    /// the others → their status with the framework's default type and title.
    /// </summary>
    public static IResult ToProblem(this Error error)
    {
        ArgumentNullException.ThrowIfNull(error);
        return error.Kind switch
        {
            ErrorKind.Validation => TypedResults.ValidationProblem(
                error.FieldErrors ?? new Dictionary<string, string[]>(),
                detail: error.Detail,
                type: ProblemTypes.ValidationFailed,
                title: ProblemTitles.ValidationFailed),
            ErrorKind.VersionConflict => TypedResults.Problem(
                statusCode: StatusCodes.Status412PreconditionFailed,
                detail: error.Detail,
                type: ProblemTypes.VersionConflict,
                title: ProblemTitles.VersionConflict),
            ErrorKind.NotFound => TypedResults.Problem(statusCode: StatusCodes.Status404NotFound, detail: error.Detail),
            ErrorKind.Conflict => TypedResults.Problem(statusCode: StatusCodes.Status409Conflict, detail: error.Detail),
            ErrorKind.Unauthorized => TypedResults.Problem(statusCode: StatusCodes.Status401Unauthorized, detail: error.Detail),
            ErrorKind.Forbidden => TypedResults.Problem(statusCode: StatusCodes.Status403Forbidden, detail: error.Detail),
            _ => throw new ArgumentOutOfRangeException(nameof(error), error.Kind, "Unknown error kind."),
        };
    }

    public static IResult ToHttpResult<T>(this Result<T> result, Func<T, IResult> onSuccess)
    {
        ArgumentNullException.ThrowIfNull(result);
        return result.Match(onSuccess, ToProblem);
    }

    public static IResult ToHttpResult(this Result result, Func<IResult> onSuccess)
    {
        ArgumentNullException.ThrowIfNull(result);
        ArgumentNullException.ThrowIfNull(onSuccess);
        return result.IsSuccess ? onSuccess() : result.Error.ToProblem();
    }
}
