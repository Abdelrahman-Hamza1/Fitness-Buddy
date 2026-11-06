using FitnessBuddy.BuildingBlocks.Jobs;
using FitnessBuddy.BuildingBlocks.Messaging;
using FitnessBuddy.BuildingBlocks.Ops;
using FitnessBuddy.Host.Tests.Infrastructure;
using Microsoft.Extensions.DependencyInjection;

namespace FitnessBuddy.Host.Tests.Admin;

// B23b security review: the console shows a queue type only when it is in QueueVocabulary (anything else reads "other"), so
// every handler the roles register must be listed there, or its queue would show as "other".
[Trait("Req", "AD-014")]
public sealed class QueueVocabularyTests
{
    [Fact]
    [Trait("Rule", "B23.P3-closed-codes")]
    public async Task Every_registered_job_and_event_handler_type_is_in_the_console_vocabulary()
    {
        await using var factory = new ApiFactory();
        await using var scope = factory.Services.CreateAsyncScope();
        var jobs = scope.ServiceProvider.GetServices<IJobHandler>().Select(handler => handler.JobType).Distinct().Order(StringComparer.Ordinal).ToArray();
        var events = scope.ServiceProvider.GetServices<IOutboxHandler>().Select(handler => handler.EventType).Distinct().Order(StringComparer.Ordinal).ToArray();
        Assert.Equal(jobs, QueueVocabulary.Default.JobTypes.Order(StringComparer.Ordinal));
        Assert.Equal(events, QueueVocabulary.Default.EventTypes.Order(StringComparer.Ordinal));
        Assert.DoesNotContain(OpsQueues.Other, QueueVocabulary.Default.JobTypes);
    }
}
