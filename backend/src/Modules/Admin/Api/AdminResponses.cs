using System.Text.Encodings.Web;
using FitnessBuddy.Modules.Admin.Api.Pages;
using FitnessBuddy.Modules.Admin.Application;
using FitnessBuddy.Modules.Admin.Domain;
using Microsoft.AspNetCore.Antiforgery;
using Microsoft.AspNetCore.Components;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.HttpResults;

namespace FitnessBuddy.Modules.Admin.Api;

/// <summary>Renders console pages (static SSR Razor components) and plain messages. HTML only; no internals (B23 P1).</summary>
internal static class AdminResponses
{
    public static PageView View(HttpContext context, IAntiforgery antiforgery, string title, string? section = null)
    {
        var principal = context.Features.Get<AdminPrincipal>();
        var viewer = principal is null ? null : new ViewerView(principal.Handle, principal.Role == ConsoleRole.Operator);
        return new PageView(title, antiforgery.GetAndStoreTokens(context).RequestToken ?? "", viewer, section);
    }

    public static RazorComponentResult<T> Page<T>(PageView view, IReadOnlyDictionary<string, object?>? parameters = null, int status = StatusCodes.Status200OK)
        where T : IComponent
    {
        var all = new Dictionary<string, object?>(parameters ?? new Dictionary<string, object?>(), StringComparer.Ordinal) { ["View"] = view };
        return new RazorComponentResult<T>(all) { StatusCode = status };
    }

    public static async Task WriteMessageAsync(HttpContext context, int status, string message)
    {
        context.Response.StatusCode = status;
        context.Response.ContentType = "text/html; charset=utf-8";
        await context.Response.WriteAsync("<!DOCTYPE html><html lang=\"en\"><meta charset=\"utf-8\"><title>Fitness Buddy admin</title><link rel=\"stylesheet\" href=\"/admin/assets/admin.css\"><main><p>"
            + HtmlEncoder.Default.Encode(message) + "</p><p><a href=\"/admin\">Back to the console</a></p></main></html>");
    }

    /// <summary>True for a request htmx made (a boosted link or form).</summary>
    public static bool IsHtmx(HttpRequest request) => request.Headers["HX-Request"] == "true";

    /// <summary>
    /// Whether the request loads a page in a tab: browsers say so with <c>Sec-Fetch-Dest: document</c>. Sub-requests (the
    /// favicon, images, scripts) send another destination and never get the sign-in redirect, which would start a new
    /// challenge and replace the cookie the page on screen still needs. A client without fetch metadata counts as a page.
    /// </summary>
    public static bool IsPageNavigation(HttpRequest request) =>
        request.Headers["Sec-Fetch-Dest"].ToString() is "" or "document";

    /// <summary>
    /// A redirect that always ends in a full page load. htmx follows a plain 302 inside the XHR and swaps the target's body into
    /// the current document, which keeps the old CSP and runs no scripts: a sign-in or re-auth page would show no Google button.
    /// For htmx requests the answer is <c>HX-Redirect</c> instead, which makes htmx navigate the browser.
    /// </summary>
    public static IResult FullRedirect(HttpContext context, string target)
    {
        if (!IsHtmx(context.Request)) { return TypedResults.Redirect(target); }
        context.Response.Headers["HX-Redirect"] = target;
        return TypedResults.NoContent();
    }

    /// <summary>A local console path to return to after re-auth, or the console home. Never an open redirect.</summary>
    public static string SafeReturn(string? value) =>
        value is { Length: > 0 and <= 200 } && (value == AdminModule.PathBase || value.StartsWith(AdminModule.PathBase + "/", StringComparison.Ordinal))
            && !value.Contains("//", StringComparison.Ordinal) && !value.Contains('\\', StringComparison.Ordinal) && !value.Contains(':', StringComparison.Ordinal)
            ? value : AdminModule.PathBase;

    public static async Task<string?> FormValueAsync(HttpContext context, string name, CancellationToken cancellationToken)
    {
        if (!context.Request.HasFormContentType) { return null; }
        var form = await context.Request.ReadFormAsync(cancellationToken);
        return form.TryGetValue(name, out var values) && values.Count == 1 ? values[0] : null;
    }
}
