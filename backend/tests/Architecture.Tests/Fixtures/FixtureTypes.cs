using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.DependencyInjection;

// Synthetic violations: these types are never loaded into the application.
namespace Fixture.Broken.Alpha.Infrastructure
{
    internal sealed class Adapter;
}

namespace Fixture.Broken.Alpha.Domain
{
    internal sealed class DomainLeak
    {
        public static object Leak() => new Alpha.Infrastructure.Adapter();
    }
}

namespace Fixture.Broken.Alpha.Application
{
    internal sealed class ModuleLeak
    {
        public static object Leak() => new Beta.Application.Handler();
    }

    internal sealed class HttpLeak
    {
        public static IResult Leak() => Results.Ok();
    }

    internal sealed class StaticTimeLeak
    {
        public static DateTimeOffset Now() => DateTimeOffset.UtcNow;
    }

    internal sealed class DateTimeLeak
    {
        public static DateTime Now() => DateTime.Now;
        public static DateTime UtcNow() => DateTime.UtcNow;
    }

    internal sealed class ProviderLeak
    {
        public static TimeProvider Clock() => TimeProvider.System;
        public static DateTimeOffset Now() => DateTimeOffset.Now;
    }

    internal sealed class StaticIdLeak
    {
        public static Guid NewId() => Guid.NewGuid();
    }
}

namespace Fixture.Broken.Beta.Application
{
    internal sealed class Handler;

    public sealed class PublicLeak;
}

namespace Fixture.Broken.BuildingBlocks
{
    internal sealed class CoreHttpLeak
    {
        public static IResult Leak() => Results.Ok();
    }
}

namespace Fixture.Clean.Beta.Contracts
{
    public interface IPort;
}

namespace Fixture.Clean.Alpha.Application
{
    internal sealed class Handler(Beta.Contracts.IPort port)
    {
        public Beta.Contracts.IPort Port { get; } = port;
    }
}

namespace Fixture.Clean.Alpha.Api
{
    public sealed record ValidatedRequest([property: Required] string Name);
}

namespace Fixture.Broken.Alpha.Api
{
    internal sealed class ApiLeak
    {
        public static object Leak() => new Alpha.Infrastructure.Adapter();
    }
}

namespace Fixture.Broken.Alpha.Infrastructure
{
    internal sealed class InfrastructureLeak
    {
        public static object Leak() => new Alpha.Api.ApiLeak();
    }
}

namespace Fixture.Broken.Host
{
    internal sealed class CompositionRoot;
}

namespace Fixture.Broken.Alpha.Application
{
    internal sealed class HostLeak
    {
        public static object Leak() => new Fixture.Broken.Host.CompositionRoot();
    }

    internal sealed class HttpLoggingLeak
    {
        public static object Leak() => new Microsoft.AspNetCore.HttpLogging.HttpLoggingOptions();
    }

    internal sealed class OtherRequestLeak
    {
        public static object Leak() => new Beta.Api.ValidatedRequest("value");
    }
}

namespace Fixture.Broken.Beta.Api
{
    public sealed record ValidatedRequest([property: Required] string Name);
}

namespace Fixture.Broken.BuildingBlocks
{
    internal sealed class CoreModuleLeak
    {
        public static object Leak() => new Alpha.Infrastructure.Adapter();
    }
}

namespace Fixture.Broken.Alpha.Application
{
    internal sealed class HttpLoggingRegistrationLeak
    {
        public static void Leak(IServiceCollection services) => services.AddHttpLogging();
    }

    internal sealed class HttpLoggingMiddlewareLeak
    {
        public static void Leak(IApplicationBuilder app) => app.UseHttpLogging();
    }
}
