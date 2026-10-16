using FitnessBuddy.BuildingBlocks.Results;

namespace FitnessBuddy.BuildingBlocks.Tests;

public sealed class ResultTests
{
    [Fact]
    public void Result_success_and_failure_are_exclusive()
    {
        var error = Error.NotFound("thing.not_found");

        Result<int> success = 42;
        Assert.True(success.IsSuccess);
        Assert.False(success.IsFailure);
        Assert.Equal(42, success.Value);
        Assert.Throws<InvalidOperationException>(() => success.Error);
        Assert.Equal("ok 42", success.Match(v => $"ok {v}", e => e.Code));

        Result<int> failure = error;
        Assert.False(failure.IsSuccess);
        Assert.True(failure.IsFailure);
        Assert.Same(error, failure.Error);
        Assert.Throws<InvalidOperationException>(() => failure.Value);
        Assert.Equal("thing.not_found", failure.Match(v => $"ok {v}", e => e.Code));

        var plainSuccess = Result.Success();
        Assert.True(plainSuccess.IsSuccess);
        Assert.Throws<InvalidOperationException>(() => plainSuccess.Error);

        Result plainFailure = error;
        Assert.True(plainFailure.IsFailure);
        Assert.Same(error, plainFailure.Error);

        Assert.Throws<ArgumentNullException>(() => Result<int>.Failure(null!));
        Assert.Throws<ArgumentNullException>(() => Result.Failure(null!));
    }
}
