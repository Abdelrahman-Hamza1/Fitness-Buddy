using System.Collections.Concurrent;
using System.Net;
using FitnessBuddy.Host.Observability;
using FitnessBuddy.Host.Tests.Infrastructure;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using OpenTelemetry.Trace;

namespace FitnessBuddy.Host.Tests.Observability;

// Proves the console/OTLP configuration in 08 §7 using real exporters and an HTTP receiver.
[Collection("Observability")]
[Trait("Rule", "08.7-observability")]
public sealed class ExporterTests
{
    [Fact]
    public async Task Otlp_exporter_sends_traces_when_the_endpoint_is_configured()
    {
        var received = new ConcurrentQueue<byte[]>();
        var receiverBuilder = WebApplication.CreateBuilder();
        receiverBuilder.WebHost.ConfigureKestrel(options => options.Listen(IPAddress.Loopback, 0));
        await using var receiver = receiverBuilder.Build();
        receiver.MapPost("/v1/traces", async (HttpContext context) =>
        {
            using var data = new MemoryStream();
            await context.Request.Body.CopyToAsync(data, Api.Ct);
            received.Enqueue(data.ToArray());
            context.Response.ContentType = "application/x-protobuf";
        });
        await receiver.StartAsync(Api.Ct);
        var builder = WebApplication.CreateBuilder(new WebApplicationOptions { EnvironmentName = "Testing" });
        builder.Configuration.AddInMemoryCollection(new Dictionary<string, string?>
        {
            ["OTEL_EXPORTER_OTLP_ENDPOINT"] = receiver.Urls.Single(),
            ["OTEL_EXPORTER_OTLP_PROTOCOL"] = "http/protobuf",
            ["Sentry:Dsn"] = "",
        });
        builder.WebHost.ConfigureKestrel(options => options.Listen(IPAddress.Loopback, 0));
        builder.AddFbObservability("api");
        await using var app = builder.Build();
        app.MapGet("/trace-probe", () => "ok");
        await app.StartAsync(Api.Ct);
        using var client = new HttpClient();
        using var response = await client.GetAsync(app.Urls.Single() + "/trace-probe", Api.Ct);
        response.EnsureSuccessStatusCode();
        Assert.True(app.Services.GetRequiredService<TracerProvider>().ForceFlush(5000));
        Assert.NotEmpty(received);
        Assert.Contains(received, body => System.Text.Encoding.UTF8.GetString(body).Contains("/trace-probe", StringComparison.Ordinal));
    }

    [Theory]
    [InlineData("Development", true, true)]
    [InlineData("Development", false, false)]
    [InlineData("Testing", true, false)]
    public async Task Console_exporter_is_on_only_when_configured_in_Development(string environment, bool enabled, bool expected)
    {
        var original = Console.Out;
        using var output = new StringWriter(System.Globalization.CultureInfo.InvariantCulture);
        Console.SetOut(output);
        try
        {
            var builder = WebApplication.CreateBuilder(new WebApplicationOptions { EnvironmentName = environment });
            builder.Configuration.AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Observability:ConsoleExporter"] = enabled.ToString(),
                ["Sentry:Dsn"] = "",
            });
            builder.WebHost.ConfigureKestrel(options => options.Listen(IPAddress.Loopback, 0));
            builder.AddFbObservability("api");
            await using var app = builder.Build();
            await app.StartAsync(Api.Ct);
            using var request = new HttpClient();
            using var response = await request.GetAsync(app.Urls.First() + "/absent", Api.Ct);
            Assert.True(app.Services.GetRequiredService<TracerProvider>().ForceFlush(5000));
            await app.StopAsync(Api.Ct);
        }
        finally
        {
            Console.SetOut(original);
        }

        Assert.Equal(expected, output.ToString().Contains("Activity.TraceId:", StringComparison.Ordinal));
    }
}
