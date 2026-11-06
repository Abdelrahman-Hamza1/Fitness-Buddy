using System.Net;
using FitnessBuddy.Host.Tests.Infrastructure;
using FitnessBuddy.Modules.Admin;
using Microsoft.AspNetCore.Routing;
using Microsoft.Extensions.DependencyInjection;

namespace FitnessBuddy.Host.Tests.Admin;

// B23 T2: the public api role serves no console route; the console exists only in the admin role.
[Trait("Req", "AD-003")]
public sealed class PublicListenerTests(ApiFactory api) : IClassFixture<ApiFactory>
{
    [Fact]
    public void The_api_role_maps_no_endpoint_from_the_admin_module()
    {
        var admin = typeof(AdminModule).Assembly;
        var endpoints = api.Services.GetRequiredService<EndpointDataSource>().Endpoints.OfType<RouteEndpoint>().ToArray();
        Assert.NotEmpty(endpoints);
        Assert.DoesNotContain(endpoints, endpoint => endpoint.RoutePattern.RawText?.TrimStart('/').StartsWith("admin", StringComparison.OrdinalIgnoreCase) == true);
        Assert.DoesNotContain(endpoints, endpoint => endpoint.RequestDelegate?.Method.DeclaringType?.Assembly == admin);
        Assert.DoesNotContain(endpoints, endpoint => endpoint.Metadata.Any(item => item.GetType().Assembly == admin));
    }

    [Theory]
    [InlineData("GET", "/admin")]
    [InlineData("GET", "/admin/")]
    [InlineData("GET", "/admin/signin")]
    [InlineData("POST", "/admin/signin")]
    [InlineData("GET", "/admin/config")]
    [InlineData("GET", "/ADMIN/audit")]
    public async Task Console_paths_are_not_found_on_the_public_listener(string method, string path)
    {
        using var client = api.CreateClient();
        using var request = new HttpRequestMessage(new HttpMethod(method), path);
        using var response = await client.SendAsync(request, TestContext.Current.CancellationToken);
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }
}
