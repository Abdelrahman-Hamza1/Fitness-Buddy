using System.Globalization;
using System.Text.Json;
using FitnessBuddy.Modules.Buddy.Domain;

namespace FitnessBuddy.Modules.Buddy.Application;

/// <summary>
/// The phone tools (06 §4.2). Outgoing: the model's arguments with handles mapped back to local IDs, as contract calls with a
/// server-minted call ID. Incoming: the phone's results with local IDs swapped for handles and numbers turned into claims,
/// under the ledger's copy of the per-turn disclosure budget (120 rows, 48 KiB) on top of the phone's own scopes.
/// </summary>
internal static class PhoneTools
{
    public const int MaxRows = 120;
    public const int MaxBytes = 48 * 1024;

    private static readonly Dictionary<string, string> Names = new(StringComparer.Ordinal)
    {
        ["find_my_foods"] = "findMyFoods",
        ["read_diary"] = "readDiary",
        ["read_body"] = "readBody",
        ["read_workouts"] = "readWorkouts",
        ["read_memory"] = "readMemory",
        ["query_data"] = "queryData",
    };

    /// <summary>The contract call, or null when the arguments don't bind or name an unknown handle.</summary>
    public static (PendingCall Pending, BuddyPhoneToolCall Call)? Prepare(AgentToolCall call, TurnWorkspace ws, Guid callId)
    {
        BuddyPhoneToolCall? built = call.Name switch
        {
            "find_my_foods" => AgentTools.Bind<FindMyFoodsToolArgs>(call) is { Query.Length: > 0 and <= 200 } f
                ? new BuddyFindMyFoodsCall(callId, new(f.Query, f.Kinds?.Distinct().ToArray() ?? [])) : null,
            "read_diary" => AgentTools.Bind<ReadDiaryToolArgs>(call) is { } d && MessageNumbers.Day(d.DateHint) && (d.From is null) == (d.To is null)
                && (d.DateHint is not null || d.From is not null) && (d.From is null || d.From <= d.To)
                ? new BuddyReadDiaryCall(callId, new(d.DateHint, d.From is { } from ? new(from, d.To!.Value) : null, Cap(d.SlotHint), Cap(d.Query))) : null,
            "read_body" => AgentTools.Bind<ReadBodyToolArgs>(call) is { } b && b.From <= b.To ? new BuddyReadBodyCall(callId, new(new(b.From, b.To), b.What)) : null,
            "read_workouts" => AgentTools.Bind<ReadWorkoutsToolArgs>(call) is { } w && w.From <= w.To && (w.Exercise is null || ws.Resolve(w.Exercise, "x") is not null)
                ? new BuddyReadWorkoutsCall(callId, new(new(w.From, w.To), ws.Resolve(w.Exercise, "x")?.Id)) : null,
            "read_memory" => AgentTools.Bind<ReadMemoryToolArgs>(call) is { } m ? new BuddyReadMemoryCall(callId, new(Cap(m.Topic))) : null,
            "query_data" => AgentTools.Bind<BuddyQueryPlan>(call) is { } q && Plan(q, ws) is { } plan ? new BuddyQueryDataCall(callId, plan) : null,
            _ => null,
        };
        return built is null ? null : (new PendingCall(callId, call.CallId, Names[call.Name], call.ArgumentsJson), built);
    }

    /// <summary>Exercise handles in the plan become local exercise references; periods beyond 400 days are left to the phone to refuse.</summary>
    private static BuddyQueryPlan? Plan(BuddyQueryPlan q, TurnWorkspace ws)
    {
        if (q.Period is null || q.Filters is { ExerciseRef: { } x } && ws.Resolve(x, "x") is null) { return null; }
        return q with { Filters = q.Filters is { } f ? f with { ExerciseRef = f.ExerciseRef is { } h ? ws.Resolve(h, "x")!.Id : null, Weekdays = f.Weekdays ?? [] } : null };
    }

    /// <summary>The results of the round being continued, in the order of the pending calls, as tool results for the model.</summary>
    public static AgentToolResult[] Ingest(TurnRun run, TurnWorkspace ws)
    {
        var results = run.Results.ToDictionary(r => r.CallId);
        // The ledger holds the turn's disclosed rows and bytes (authoritative, not restorable from a continuation).
        return run.Answered.Select(p =>
        {
            if (run.DisclosureExceeded) { return new AgentToolResult(p.ProviderCallId, AgentTools.Error("budgetExceeded")); }
            var mark = ws.Claims.Count;
            var json = One(p, results[p.CallId], ws);
            return new AgentToolResult(p.ProviderCallId, AgentTools.WithFacts(json, ws.Claims[mark..]));
        }).ToArray();
    }

    private static string One(PendingCall pending, PhoneResultInput result, TurnWorkspace ws)
    {
        if (!result.Ok || result.Data is not { } data) { return AgentTools.Error(result.Error ?? "unavailable"); }
        try
        {
            return pending.Tool switch
            {
                "findMyFoods" => MyFoods(data, ws),
                "readDiary" => Diary(data, ws),
                "readBody" => Body(data, ws),
                "readWorkouts" => Workouts(data, ws),
                "readMemory" => AgentTools.Result(new { ok = true, items = data.GetProperty("items") }),
                "queryData" => Query(data, pending, ws),
                _ => AgentTools.Error("unavailable"),
            };
        }
        catch (Exception e) when (e is KeyNotFoundException or InvalidOperationException or FormatException or JsonException)
        { return AgentTools.Error("invalid"); }
    }

    private static string MyFoods(JsonElement data, TurnWorkspace ws)
    {
        var items = data.GetProperty("items").EnumerateArray().Select(item =>
        {
            var p = item.Deserialize<PhonePersonal>(AgentTools.Json)!;
            return TurnContextBuilder.AddPersonal(ws, new(p.Ref, p.Kind, p.Names, p.Aliases, p.State, p.Per100, p.Servings ?? [],
                (p.Portions ?? []).Select(x => new TurnPortion(x.Label, x.G, x.Nutrients)).ToArray()));
        }).ToArray();
        return AgentTools.Result(new { ok = true, items });
    }

    private static string Diary(JsonElement data, TurnWorkspace ws)
    {
        var entries = new List<object>();
        foreach (var row in data.GetProperty("entries").EnumerateArray())
        {
            var id = row.GetProperty("id").GetGuid(); var date = DateOnly.Parse(row.GetProperty("date").GetString()!, CultureInfo.InvariantCulture);
            var slot = row.GetProperty("slot").GetString()!; var name = row.GetProperty("name").GetString()!;
            var grams = Number(row, "grams"); var kcal = Number(row, "kcal");
            if (ws.Entries.All(e => e.Id != id)) { ws.Entries.Add(new(id, date, slot, name, grams)); }
            var day = date.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);
            entries.Add(new
            {
                entry = ws.Handle("e", id.ToString(), name),
                date = day,
                slot,
                name,
                grams = grams is { } g ? ws.AddClaim("grams", "entry", day, ClaimSet.Round(g, 1), date, "g", $"of {name} ({slot}, {day})").Id : null,
                kcal = kcal is { } k ? ws.AddClaim("kcal", "entry", day, ClaimSet.Round(k), date, "kcal", $"in {name} ({slot}, {day})").Id : null,
            });
        }
        return AgentTools.Result(new { ok = true, entries, truncated = data.GetProperty("truncated").GetBoolean() });
    }

    private static string Body(JsonElement data, TurnWorkspace ws)
    {
        var values = data.GetProperty("values").EnumerateArray().Select(v =>
        {
            var date = DateOnly.Parse(v.GetProperty("date").GetString()!, CultureInfo.InvariantCulture);
            var metric = v.GetProperty("metric").GetString()!; var unit = v.GetProperty("unit").GetString()!;
            var day = date.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);
            return new { date = day, metric, value = ws.AddClaim(metric == "weight" ? "weight" : "measurement", "latest", day, v.GetProperty("value").GetDouble(), date, unit, $"{metric} on {day}").Id };
        }).ToArray();
        object? trend = null;
        if (data.TryGetProperty("trend", out var t) && t.ValueKind == JsonValueKind.Object)
        {
            var span = $"from {t.GetProperty("from").GetString()} to {t.GetProperty("to").GetString()}";
            trend = new
            {
                start = ws.AddClaim("weight", "start", span, t.GetProperty("startKg").GetDouble(), null, "kg", "weight at the start, " + span).Id,
                end = ws.AddClaim("weight", "end", span, t.GetProperty("endKg").GetDouble(), null, "kg", "weight at the end, " + span).Id,
                change = ws.AddClaim("weight", "change", span, t.GetProperty("changeKg").GetDouble(), null, "kg", "weight change " + span).Id,
                weekly = Number(t, "weeklyChangeKg") is { } w ? ws.AddClaim("weight", "change", "week", w, null, "kg", "weight change per week").Id : null,
                weighIns = ws.AddClaim("weighIns", "count", span, t.GetProperty("weighIns").GetInt32(), null, "count", "weigh-ins " + span).Id,
            };
        }
        return AgentTools.Result(new { ok = true, values, trend });
    }

    private static string Workouts(JsonElement data, TurnWorkspace ws)
    {
        var sessions = data.GetProperty("sessions").EnumerateArray().Select(s =>
        {
            var day = s.GetProperty("date").GetString()!;
            return new
            {
                workout = ws.Handle("w", s.GetProperty("id").GetGuid().ToString(), day),
                date = day,
                name = s.GetProperty("name").GetString(),
                exercises = s.GetProperty("exercises").EnumerateArray().Select(e => new
                {
                    exercise = ws.Handle("x", e.GetProperty("exerciseRef").GetString()!, e.GetProperty("name").GetString()!),
                    name = e.GetProperty("name").GetString(),
                    sets = e.GetProperty("sets").GetArrayLength(),
                }).ToArray(),
            };
        }).ToArray();
        var prs = data.GetProperty("prs").EnumerateArray().Select(p =>
        {
            var name = p.GetProperty("name").GetString()!; var day = p.GetProperty("date").GetString()!;
            return new
            {
                exercise = ws.Handle("x", p.GetProperty("exerciseRef").GetString()!, name),
                date = day,
                kg = Number(p, "kg") is { } kg ? ws.AddClaim("exercisePr", "max", null, kg, null, "kg", $"best {name} ({day})").Id : null,
                reps = Number(p, "reps") is { } reps ? ws.AddClaim("exercisePr", "max", null, reps, null, "count", $"reps at the best {name} ({day})").Id : null,
            };
        }).ToArray();
        return AgentTools.Result(new { ok = true, sessions, prs });
    }

    private static string Query(JsonElement data, PendingCall pending, TurnWorkspace ws)
    {
        var plan = JsonSerializer.Deserialize<BuddyQueryPlan>(pending.ArgsJson, AgentTools.Json)!;
        var period = ClaimLabels.Of(plan.Period);
        var claims = data.GetProperty("claims").EnumerateArray().Select(c =>
        {
            var metric = c.GetProperty("metric").GetString()!; var operation = c.GetProperty("operation").GetString()!;
            var unit = c.GetProperty("unit").GetString()!;
            DateOnly? date = c.TryGetProperty("date", out var d) && d.ValueKind == JsonValueKind.String ? DateOnly.Parse(d.GetString()!, CultureInfo.InvariantCulture) : null;
            var claim = ws.AddClaim(metric, operation, period, Number(c, "value"), date, unit, ClaimLabels.For(metric, operation, operation == "last" ? null : period));
            var workout = c.TryGetProperty("workoutId", out var w) && w.ValueKind == JsonValueKind.String ? ws.Handle("w", w.GetGuid().ToString(), "workout") : null;
            return new { fact = claim.Id, workout, muscleGroup = c.TryGetProperty("muscleGroup", out var g) ? g.GetString() : null };
        }).ToArray();
        var coverage = data.GetProperty("coverage");
        return AgentTools.Result(new
        {
            ok = true,
            claims,
            days = ws.AddClaim("days", "count", period, coverage.GetProperty("days").GetInt32(), null, "count", "days in the period").Id,
            loggedDays = ws.AddClaim("loggedDays", "count", period, coverage.GetProperty("loggedDays").GetInt32(), null, "count", "logged days in the period").Id,
        });
    }

    /// <summary>Digest (content-free SHA-256), rows and bytes of a continue's results, for the ledger.</summary>
    public static PhoneDisclosure Disclosure(PhoneResultInput[] results)
    {
        var canonical = string.Join('\n', results.OrderBy(r => r.CallId).Select(r =>
            $"{r.CallId:D}|{r.Name}|{r.Ok}|{r.Error}|{(r.Data is { } d ? d.GetRawText() : "")}"));
        var bytes = System.Text.Encoding.UTF8.GetBytes(canonical);
        return new(Convert.ToHexString(System.Security.Cryptography.SHA256.HashData(bytes)).ToLowerInvariant(), results.Sum(r => Math.Max(r.Rows, 0)),
            results.Sum(r => r.Data is { } d ? System.Text.Encoding.UTF8.GetByteCount(d.GetRawText()) : 0));
    }

    private static double? Number(JsonElement row, string name) => row.TryGetProperty(name, out var v) && v.ValueKind == JsonValueKind.Number ? v.GetDouble() : null;
    private static string? Cap(string? s) => s is null ? null : s.Length <= 200 ? s : s[..200];

    private sealed record PhonePortion(string Label, double? G, BuddyNutrients Nutrients);
    private sealed record PhonePersonal(Guid Ref, string Kind, string[] Names, string[] Aliases, string? State, BuddyNutrients? Per100, BuddyServing[]? Servings, PhonePortion[]? Portions);
}
