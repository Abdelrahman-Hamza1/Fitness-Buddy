using System.Text.Json;
using System.Text.Json.Serialization;
using FitnessBuddy.Modules.Buddy.Domain;
using Microsoft.Extensions.AI;

namespace FitnessBuddy.Modules.Buddy.Application;

internal enum ToolKind { Unknown, Server, Phone, Action, Terminal }

/// <summary>A tool the model may call (TD-127): its kind, the step line it shows, and the C# record its arguments bind to.</summary>
internal sealed record ToolDef(string Name, ToolKind Kind, BuddyStepCode? Step, Type Args, string Description);

// Terminal tools (06 §4.4).
internal enum DeclineTopic { OffTopic, Medical, Supplements }
internal sealed record AskUserArgs(string Text, string[] Options);
internal sealed record DeclineArgs(DeclineTopic Reason);

/// <summary>
/// The tool declarations (schemas generated from C# records, versioned with the prompt, TD-127). Arguments are bound
/// strictly; an unbindable call gets an <c>invalidArgs</c> result and the model may try again in its next step.
/// </summary>
internal static class AgentTools
{
    public static readonly JsonSerializerOptions Json = new(JsonSerializerDefaults.Web)
    {
        Converters = { new JsonStringEnumConverter(JsonNamingPolicy.CamelCase, allowIntegerValues: false) },
        RespectNullableAnnotations = true,
        AllowOutOfOrderMetadataProperties = true,
        UnmappedMemberHandling = JsonUnmappedMemberHandling.Skip,
    };

    private static readonly ToolDef[] Definitions =
    [
        // Server tools: shared data, inline.
        new("search_foods", ToolKind.Server, BuddyStepCode.SearchingFoods, typeof(SearchFoodsArgs),
            "Search the food catalog (query in canonical English, optional Arabic name, state, kind food|dish|branded, limit ≤ 8). Returns food handles with per-100 g claims and servings."),
        new("get_dish", ToolKind.Server, BuddyStepCode.SearchingFoods, typeof(GetDishArgs), "Details of a food or dish handle: typical portions (claims) and close variants (handles)."),
        new("lookup_barcode", ToolKind.Server, BuddyStepCode.SearchingFoods, typeof(LookupBarcodeArgs), "Look up a packaged product by its barcode digits: name, brand and per-100 claims, or not found."),
        new("compute", ToolKind.Server, BuddyStepCode.Computing, typeof(ComputeArgs),
            "Compute grams, kcal and macros for food handles with amounts (code does the arithmetic). Returns claims per item and totals."),
        new("check_fit", ToolKind.Server, BuddyStepCode.CheckingFit, typeof(CheckFitArgs),
            "Check 1–4 food options (items as in propose_food_log, with amounts) against what's left today: claims for each option's kcal and protein, what would be left, and whether it fits. Use before suggest_foods."),
        new("exercise_search", ToolKind.Server, BuddyStepCode.SearchingExercises, typeof(ExerciseSearchArgs),
            "Find library exercises by name (any language or shorthand, limit ≤ 8): exercise handles with name, equipment, muscle group and whether loads are per dumbbell. The user's custom exercises come from read_workouts."),
        // Phone tools: the user's own data, read on the phone under its scopes; they pause the turn.
        new("find_my_foods", ToolKind.Phone, BuddyStepCode.ReadingYourFoods, typeof(FindMyFoodsToolArgs), "Find the user's personal foods, saved meals, batches and usual meals by name (≤ 20)."),
        new("read_diary", ToolKind.Phone, BuddyStepCode.ReadingDiary, typeof(ReadDiaryToolArgs), "Read diary entries for a day (dateHint) or a range of at most 31 days, optionally one slot or a food query (≤ 40 rows)."),
        new("read_body", ToolKind.Phone, BuddyStepCode.ReadingBody, typeof(ReadBodyToolArgs), "Read weight, the weight trend (≤ 365 days, aggregates) or body measurements (≤ 31 days)."),
        new("read_workouts", ToolKind.Phone, BuddyStepCode.ReadingWorkouts, typeof(ReadWorkoutsToolArgs), "Read workout sessions of at most 90 days (≤ 15 sessions), optionally one exercise handle, with PRs."),
        new("read_memory", ToolKind.Phone, BuddyStepCode.ReadingMemory, typeof(ReadMemoryToolArgs), "Read what the user asked Buddy to remember (≤ 30 items), optionally about one topic."),
        new("query_data", ToolKind.Phone, BuddyStepCode.Computing, typeof(BuddyQueryPlan),
            "Answer a question about the user's data with a QueryPlan (metric, op, period ≤ 400 days, filters). Returns computed claims only. Valid: remaining+today with nutrients; total/average/max/min with nutrients, sets, volume; latest/change with weight, weightTrend, measurement, exercisePr; count with workouts, sets, weighIns, loggedDays; last with exerciseLastDate."),
        // Action tools: proposals (cards) the user confirms; never writes.
        new("propose_food_log", ToolKind.Action, null, typeof(FoodLogArgs), "Propose logging foods eaten (one call per meal or time group)."),
        new("propose_diary_edit", ToolKind.Action, null, typeof(DiaryEditArgs), "Propose changing logged diary entries (entry handles from read_diary): a new absolute amount, a replacement food, and/or a move."),
        new("propose_diary_delete", ToolKind.Action, null, typeof(DiaryDeleteArgs), "Propose deleting logged diary entries (entry handles)."),
        new("propose_diary_copy", ToolKind.Action, null, typeof(DiaryCopyArgs), "Propose copying a logged meal (source day hint and slot) to another day/slot."),
        new("propose_saved_meal", ToolKind.Action, null, typeof(SavedMealArgs), "Propose logging a saved meal (op log, meal handle) or saving a meal (op create: a name plus a card handle, entry handles or a day/slot)."),
        new("propose_batch", ToolKind.Action, null, typeof(BatchArgs), "Propose a home-cooked batch (op create with ingredients), a portion of an open batch (op portion, batch handle) or closing one (op close)."),
        new("propose_personal_food", ToolKind.Action, null, typeof(PersonalFoodArgs), "Propose saving a personal food: name, aliases, components and/or the nutrition figures exactly as the user wrote them."),
        new("propose_memory", ToolKind.Action, null, typeof(MemoryArgs), "Propose remembering or forgetting a habit, portion, alias, brand or nickname the user stated."),
        new("propose_weigh_in", ToolKind.Action, null, typeof(WeighInArgs), "Propose a weigh-in the user stated (the value exactly as written)."),
        new("propose_measurement", ToolKind.Action, null, typeof(MeasurementArgs),
            "Propose a body measurement the user stated (waist, chest, hips, arm, thigh, neck in cm or in; bodyFat in percent), the value exactly as written."),
        new("propose_workout", ToolKind.Action, null, typeof(WorkoutArgs),
            "Propose a workout session: one entry per exercise with mention (the user's words), exercise (a library code from the list, or a handle from exercise_search/read_workouts; null if nothing fits), notation (the exact set text the user wrote for it, e.g. \"3x8 80\", \"8,8,7 @80\", \"+10 3x8\", \"30 min\"; code reads the numbers) and sets only when there is no such text. Dumbbell loads are per dumbbell; set perDumbbell false only if the user gave a total. For \"same as last … but …\", pass copyFrom (a workout handle from read_workouts) and only the changed exercises."),
        new("propose_import", ToolKind.Action, null, typeof(ImportArgs),
            "Propose importing pasted dated rows (weight, or one measurement kind): per row the original text exactly as pasted, the date as YYYY-MM-DD when readable, the value and the unit as written (null when missing). The app reviews units, jumps and duplicates."),
        new("suggest_foods", ToolKind.Action, null, typeof(SuggestArgs), "Suggest 2–4 food options the user asked for; each option is a ready food card."),
        // Terminal tools.
        new("ask_user", ToolKind.Terminal, null, typeof(AskUserArgs), "Ask the user one short question with 2–4 short options; ends the turn. At most two per turn."),
        new("decline", ToolKind.Terminal, null, typeof(DeclineArgs), "Decline a medical, supplement-dosing or off-topic request with the app's template; ends the turn."),
    ];

    private static readonly Lazy<IReadOnlyList<AgentToolSpec>> Declared = new(() => Definitions
        .Select(d => new AgentToolSpec(d.Name, d.Description, AIJsonUtilities.CreateJsonSchema(d.Args, serializerOptions: Json))).ToArray());

    /// <summary>The declarations, static and in a fixed order (prompt caching).</summary>
    public static IReadOnlyList<AgentToolSpec> Specs => Declared.Value;

    public static ToolDef? Find(string name) => Definitions.FirstOrDefault(d => string.Equals(d.Name, name, StringComparison.Ordinal));

    /// <summary>Binds a call's arguments; null when they don't fit the tool's record.</summary>
    public static T? Bind<T>(AgentToolCall call) where T : class
    {
        try { return JsonSerializer.Deserialize<T>(call.ArgumentsJson, Json); }
        catch (JsonException) { return null; }
        catch (NotSupportedException) { return null; }
    }

    /// <summary>A size-capped result for the model (≤ 8 KiB, TD-124).</summary>
    public static string Result(object value)
    {
        var json = JsonSerializer.Serialize(value, Json);
        return json.Length <= 8192 ? json : JsonSerializer.Serialize(new { error = "tooLarge" }, Json);
    }
    /// <summary>
    /// The claims a tool created, appended to its result so the model can compare and choose (06 §4): id, metric, operation,
    /// period, value or date, unit and the code label. Within the 8 KiB cap; facts that don't fit are dropped and flagged.
    /// </summary>
    public static string WithFacts(string resultJson, IReadOnlyList<Claim> claims)
    {
        if (claims.Count == 0 || System.Text.Json.Nodes.JsonNode.Parse(resultJson) is not System.Text.Json.Nodes.JsonObject result) { return resultJson; }
        for (var take = claims.Count; take >= 0; take = take > 8 ? take - Math.Max(1, take / 4) : take - 1)
        {
            result["facts"] = System.Text.Json.JsonSerializer.SerializeToNode(claims.Take(take).Select(Fact).ToArray(), Json);
            if (take < claims.Count) { result["factsTruncated"] = true; }
            var json = result.ToJsonString(Json);
            if (json.Length <= 8192 || take == 0) { return json.Length <= 8192 ? json : resultJson; }
        }
        return resultJson;
    }

    public static object Fact(Claim c) => new
    {
        id = c.Id,
        metric = c.Metric,
        operation = c.Operation,
        period = c.Period,
        value = c.Value,
        date = c.Date?.ToString("yyyy-MM-dd", System.Globalization.CultureInfo.InvariantCulture),
        unit = c.Unit,
        label = c.Label,
    };

    public static string Error(string code) => JsonSerializer.Serialize(new { ok = false, error = code }, Json);
}
