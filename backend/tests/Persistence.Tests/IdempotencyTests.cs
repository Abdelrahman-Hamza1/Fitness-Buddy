using System.Net;
using System.Text;
using System.Text.Json;

namespace FitnessBuddy.Persistence.Tests;

// Server deduplication foundation for MN-005; allowance accounting/Buddy integration are later steps.
[Trait("Rule", "04.4.2-idempotency")]
public sealed class IdempotencyTests(PostgresFixture database)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;
    private readonly TestClock clock = new();

    [Fact]
    [Trait("Req", "MN-005")]
    public async Task Replay_preserves_status_body_and_safe_headers_without_repeating_effect()
    {
        await using var api = new IdempotencyApi(database, clock);
        using var client = api.CreateClient();
        var id = Guid.CreateVersion7();
        var user = Guid.CreateVersion7();
        using var first = await SendAsync(client, id, user, "one");
        using var replay = await SendAsync(client, id, user, "one");
        Assert.Equal(HttpStatusCode.Created, first.StatusCode);
        Assert.Equal(first.StatusCode, replay.StatusCode);
        Assert.Equal(await first.Content.ReadAsStringAsync(Ct), await replay.Content.ReadAsStringAsync(Ct));
        Assert.Equal(first.Headers.ETag, replay.Headers.ETag);
        Assert.True(first.Headers.Contains("Set-Cookie"));
        Assert.False(replay.Headers.Contains("Set-Cookie"));
        Assert.NotEqual(first.Headers.GetValues("X-Request-Id"), replay.Headers.GetValues("X-Request-Id"));
        Assert.Equal(1, await EffectCountAsync(id));
    }

    [Fact]
    public async Task Same_key_different_payload_is_409_without_running_handler()
    {
        await using var api = new IdempotencyApi(database, clock);
        using var client = api.CreateClient();
        var id = Guid.CreateVersion7();
        var user = Guid.CreateVersion7();
        using var first = await SendAsync(client, id, user, "key", "first");
        using var conflict = await SendAsync(client, id, user, "key", "different");
        Assert.Equal(HttpStatusCode.Conflict, conflict.StatusCode);
        Assert.Equal(1, await EffectCountAsync(id));
    }

    [Fact]
    public async Task Concurrent_same_key_requests_commit_one_effect()
    {
        await using var api = new IdempotencyApi(database, clock);
        using var client = api.CreateClient();
        var id = Guid.CreateVersion7();
        var user = Guid.CreateVersion7();
        var results = await Task.WhenAll(Enumerable.Range(0, 6).Select(_ => SendAsync(client, id, user, "concurrent")));
        try
        {
            foreach (var response in results) { Assert.Equal(HttpStatusCode.Created, response.StatusCode); }
            var bodies = await Task.WhenAll(results.Select(response => response.Content.ReadAsStringAsync(Ct)));
            Assert.Single(bodies.Distinct(StringComparer.Ordinal));
            Assert.Equal(1, await EffectCountAsync(id));
        }
        finally { foreach (var response in results) { response.Dispose(); } }
    }

    [Fact]
    public async Task Keys_are_isolated_by_user_and_route_and_expire_at_24_hours()
    {
        await using var api = new IdempotencyApi(database, clock);
        using var client = api.CreateClient();
        var firstId = Guid.CreateVersion7();
        var secondId = Guid.CreateVersion7();
        var user = Guid.CreateVersion7();
        using var first = await SendAsync(client, firstId, user, "shared");
        using var otherUser = await SendAsync(client, firstId, Guid.CreateVersion7(), "shared");
        using var otherRoute = await SendAsync(client, secondId, user, "shared");
        Assert.Equal(HttpStatusCode.Created, otherUser.StatusCode);
        Assert.Equal(HttpStatusCode.Created, otherRoute.StatusCode);
        Assert.NotEqual(await first.Content.ReadAsStringAsync(Ct), await otherUser.Content.ReadAsStringAsync(Ct));
        clock.Advance(TimeSpan.FromHours(24) - TimeSpan.FromSeconds(1));
        using var beforeExpiry = await SendAsync(client, firstId, user, "shared");
        Assert.Equal(await first.Content.ReadAsStringAsync(Ct), await beforeExpiry.Content.ReadAsStringAsync(Ct));
        clock.Advance(TimeSpan.FromSeconds(1));
        using var afterExpiry = await SendAsync(client, firstId, user, "shared");
        Assert.Equal(3, await EffectCountAsync(firstId));
    }

    [Theory]
    [InlineData(null, 400)]
    [InlineData("has space", 400)]
    [InlineData("valid", 401)]
    public async Task Missing_invalid_key_or_missing_identity_fails_closed(string? key, int expectedStatus)
    {
        await using var api = new IdempotencyApi(database, clock);
        using var client = api.CreateClient();
        var id = Guid.CreateVersion7();
        using var response = await SendAsync(client, id, expectedStatus == 401 ? null : Guid.CreateVersion7(), key);
        Assert.Equal(expectedStatus, (int)response.StatusCode);
        Assert.Equal(0, await EffectCountAsync(id));
    }

    [Fact]
    public async Task Server_error_rolls_back_business_effect_and_does_not_cache_failure()
    {
        await using var api = new IdempotencyApi(database, clock);
        using var client = api.CreateClient();
        var id = Guid.CreateVersion7();
        var user = Guid.CreateVersion7();
        using var first = await SendAsync(client, id, user, "retry", query: "?fail=true");
        using var second = await SendAsync(client, id, user, "retry", query: "?fail=true");
        Assert.Equal(HttpStatusCode.InternalServerError, first.StatusCode);
        Assert.Equal(HttpStatusCode.InternalServerError, second.StatusCode);
        Assert.Equal(0, await EffectCountAsync(id));
        using var success = await SendAsync(client, id, user, "retry");
        Assert.Equal(HttpStatusCode.Created, success.StatusCode);
        Assert.Equal(1, await EffectCountAsync(id));
    }

    [Fact]
    public async Task Replayed_problem_uses_current_request_trace_id()
    {
        await using var api = new IdempotencyApi(database, clock);
        using var client = api.CreateClient();
        var id = Guid.CreateVersion7();
        var user = Guid.CreateVersion7();
        using var first = await SendAsync(client, id, user, "rejected", query: "?reject=true");
        using var replay = await SendAsync(client, id, user, "rejected", query: "?reject=true");
        Assert.Equal(HttpStatusCode.UnprocessableEntity, replay.StatusCode);
        using var problem = JsonDocument.Parse(await replay.Content.ReadAsStringAsync(Ct));
        Assert.Equal(replay.Headers.GetValues("X-Request-Id").Single(), problem.RootElement.GetProperty("traceId").GetString());
        Assert.Equal(1, await EffectCountAsync(id));
    }

    [Theory]
    [InlineData("?throw=true")]
    [InlineData("?large=true")]
    public async Task Unhandled_exception_or_oversized_response_rolls_back_effect(string query)
    {
        await using var api = new IdempotencyApi(database, clock);
        using var client = api.CreateClient();
        var id = Guid.CreateVersion7();
        var user = Guid.CreateVersion7();
        using var response = await SendAsync(client, id, user, "failed", query: query);
        Assert.Equal(HttpStatusCode.InternalServerError, response.StatusCode);
        Assert.DoesNotContain("private-failure", await response.Content.ReadAsStringAsync(Ct), StringComparison.Ordinal);
        Assert.Equal(0, await EffectCountAsync(id));
        using var retry = await SendAsync(client, id, user, "failed");
        Assert.Equal(HttpStatusCode.Created, retry.StatusCode);
        Assert.Equal(1, await EffectCountAsync(id));
    }

    [Fact]
    public async Task Oversized_request_is_rejected_before_handler_or_database_transaction()
    {
        await using var api = new IdempotencyApi(database, clock);
        using var client = api.CreateClient();
        var id = Guid.CreateVersion7();
        using var response = await SendAsync(client, id, Guid.CreateVersion7(), "big", new string('x', 256 * 1024 + 1));
        Assert.Equal(HttpStatusCode.RequestEntityTooLarge, response.StatusCode);
        Assert.Equal(0, await EffectCountAsync(id));
    }

    [Fact]
    public async Task Request_cancellation_rolls_back_and_releases_key_for_a_retry()
    {
        await using var api = new IdempotencyApi(database, clock);
        using var client = api.CreateClient();
        using var cancelled = CancellationTokenSource.CreateLinkedTokenSource(Ct);
        var id = Guid.CreateVersion7();
        var user = Guid.CreateVersion7();
        var pending = SendAsync(client, id, user, "cancelled", query: "?wait=true", cancellationToken: cancelled.Token);
        await api.Signals.Started.Task.WaitAsync(TimeSpan.FromSeconds(10), Ct);
        cancelled.Cancel();
        await Assert.ThrowsAnyAsync<OperationCanceledException>(() => pending);
        Assert.Equal(0, await EffectCountAsync(id));
        using var retry = await SendAsync(client, id, user, "cancelled");
        Assert.Equal(HttpStatusCode.Created, retry.StatusCode);
        Assert.Equal(1, await EffectCountAsync(id));
    }

    private static async Task<HttpResponseMessage> SendAsync(HttpClient client, Guid id, Guid? user, string? key, string body = "{}", string query = "", CancellationToken? cancellationToken = null)
    {
        using var request = new HttpRequestMessage(HttpMethod.Post, "/v1/_persistence/" + id + query);
        request.Headers.Add("X-App-Version", "0.1.0");
        request.Headers.Add("X-Platform", "android");
        request.Headers.Add("X-Device-Id", "0192a5d4-7c3e-7b1a-9f2e-3c4d5e6f7a8b");
        if (user is not null) { request.Headers.Add("Test-User", user.ToString()); }
        if (key is not null) { request.Headers.Add("Idempotency-Key", key); }
        request.Content = new StringContent(body, Encoding.UTF8, "application/json");
        return await client.SendAsync(request, cancellationToken ?? Ct);
    }
    private async Task<int> EffectCountAsync(Guid id)
    {
        await using var command = database.App.CreateCommand("SELECT count FROM testdata.effects WHERE id=$1");
        command.Parameters.AddWithValue(id);
        return (int?)await command.ExecuteScalarAsync(Ct) ?? 0;
    }
}
