using FitnessBuddy.BuildingBlocks.Results;
using FitnessBuddy.BuildingBlocks.Web.Problems;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.HttpResults;

namespace FitnessBuddy.BuildingBlocks.Tests;

/// <summary>Error → problem mapping (04 §4.2 "Errors"; the app maps these to its Failures, UX-052).</summary>
[Trait("Rule", "04.4.2-errors")]
public sealed class ErrorResultsTests
{
    [Fact]
    public void ErrorResults_map_validation_to_400_validation_failed_with_errors()
    {
        var errors = new Dictionary<string, string[]> { ["name"] = ["Required."] };

        var result = Error.Validation("thing.invalid", errors).ToProblem();

        var problem = Assert.IsType<ValidationProblem>(result).ProblemDetails;
        Assert.Equal(StatusCodes.Status400BadRequest, problem.Status);
        Assert.Equal(ProblemTypes.ValidationFailed, problem.Type);
        Assert.Equal(ProblemTitles.ValidationFailed, problem.Title);
        Assert.Equal(["Required."], problem.Errors["name"]);
    }

    [Fact]
    public void ErrorResults_map_version_conflict_to_412_version_conflict()
    {
        var result = Error.VersionConflict("thing.stale", "The resource changed.").ToProblem();

        var problem = Assert.IsType<ProblemHttpResult>(result).ProblemDetails;
        Assert.Equal(StatusCodes.Status412PreconditionFailed, problem.Status);
        Assert.Equal(ProblemTypes.VersionConflict, problem.Type);
        Assert.Equal(ProblemTitles.VersionConflict, problem.Title);
        Assert.Equal("The resource changed.", problem.Detail);
    }

    [Theory]
    [InlineData(ErrorKind.NotFound, 404, "https://tools.ietf.org/html/rfc9110#section-15.5.5", "Not Found")]
    [InlineData(ErrorKind.Conflict, 409, "https://tools.ietf.org/html/rfc9110#section-15.5.10", "Conflict")]
    [InlineData(ErrorKind.Unauthorized, 401, "https://tools.ietf.org/html/rfc9110#section-15.5.2", "Unauthorized")]
    [InlineData(ErrorKind.Forbidden, 403, "https://tools.ietf.org/html/rfc9110#section-15.5.4", "Forbidden")]
    public void ErrorResults_map_each_ErrorKind_to_status_and_type(ErrorKind kind, int status, string type, string title)
    {
        var result = new Error(kind, "thing.code").ToProblem();

        var problem = Assert.IsType<ProblemHttpResult>(result).ProblemDetails;
        Assert.Equal(status, problem.Status);
        Assert.Equal(type, problem.Type);
        Assert.Equal(title, problem.Title);
        Assert.Null(problem.Detail);
    }

    [Fact]
    public void ErrorResults_cover_every_ErrorKind()
    {
        foreach (var kind in Enum.GetValues<ErrorKind>())
        {
            var result = new Error(kind, "thing.code", FieldErrors: new Dictionary<string, string[]>()).ToProblem();
            Assert.True(result is ProblemHttpResult or ValidationProblem, kind.ToString());
        }
    }

    [Fact]
    public void ToHttpResult_maps_success_with_the_callback_and_failure_to_a_problem()
    {
        Result<int> success = 7;
        Result<int> failure = Error.NotFound("thing.not_found");

        Assert.Equal(7, Assert.IsType<Ok<int>>(success.ToHttpResult(TypedResults.Ok)).Value);
        Assert.Equal(404, Assert.IsType<ProblemHttpResult>(failure.ToHttpResult(TypedResults.Ok)).StatusCode);
        Assert.IsType<NoContent>(Result.Success().ToHttpResult(TypedResults.NoContent));
    }
}
