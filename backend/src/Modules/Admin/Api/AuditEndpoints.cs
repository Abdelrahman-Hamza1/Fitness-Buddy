using System.Text;
using FitnessBuddy.Modules.Admin.Api.Pages;
using FitnessBuddy.Modules.Admin.Application;
using Microsoft.AspNetCore.Antiforgery;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;

namespace FitnessBuddy.Modules.Admin.Api;

/// <summary>AD-016: the audit log window (read-only for everyone; there is no edit or delete route) and its CSV export.</summary>
internal static class AuditEndpoints
{
    public static void Map(RouteGroupBuilder group)
    {
        group.MapGet("/audit", ListAsync).WithCapability(AdminCapability.Session);
        group.MapGet("/audit/export.csv", ExportAsync).WithCapability(AdminCapability.Session);
    }

    private static async Task<IResult> ListAsync(HttpContext context, ListAudit list, IAntiforgery antiforgery, string? area, string? actor, string? from,
        string? to, long? cursor, CancellationToken cancellationToken)
    {
        var (filter, dropped) = AuditFilter.Parse(area, actor, from, to);
        var (rows, next) = await list.HandleAsync(filter, cursor is > 0 ? cursor : null, cancellationToken);
        var view = new AuditListView(filter.Area, filter.Actor, filter.From?.ToString("yyyy-MM-dd", System.Globalization.CultureInfo.InvariantCulture),
            filter.Until?.AddDays(-1).ToString("yyyy-MM-dd", System.Globalization.CultureInfo.InvariantCulture),
            [.. rows.Select(row => new AuditRowView(row.Id, row.OccurredAt, row.Actor, row.Area, row.Action, row.Target, row.Outcome, row.Reason, row.BeforeJson, row.AfterJson))],
            next, dropped ? "Some filters weren't valid and were ignored." : null);
        return AdminResponses.Page<AuditPage>(AdminResponses.View(context, antiforgery, "Audit log", "audit"), new Dictionary<string, object?> { ["List"] = view });
    }

    private static async Task<IResult> ExportAsync(HttpContext context, ExportAudit export, string? area, string? actor, string? from, string? to,
        CancellationToken cancellationToken)
    {
        var (filter, _) = AuditFilter.Parse(area, actor, from, to);
        var csv = await export.HandleAsync(context.Features.Get<AdminPrincipal>()!, filter, cancellationToken);
        context.Response.Headers.ContentDisposition = "attachment; filename=\"fitness-buddy-audit.csv\"";
        return TypedResults.Text(csv, "text/csv; charset=utf-8", Encoding.UTF8);
    }
}
