using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using FitnessBuddy.Modules.UserData.Domain;
using FitnessBuddy.Modules.UserData.Infrastructure;
using FitnessBuddy.TestData;

namespace FitnessBuddy.UserData.Tests;

// B18: chatMessage/proposal v1 admission is the schema plus the existing generic
// representability pass. No production change (PA2): these tests pin it.
[Trait("Req", "AC-010")]
public sealed class ChatProposalPayloadTests
{
    private const string Pair = "\U0001F600"; // one supplementary character = two UTF-16 units
    private static readonly string[] JsonFields = ["budgetJson", "interpretationJson", "draftJson"];
    private static readonly bool[] LiveAndTombstone = [false, true];
    private static readonly string[] Sources = ["codec", "synthetic"];

    private static JsonDocument Read(string file) => JsonDocument.Parse(File.ReadAllText(Path.Combine(AppContext.BaseDirectory, file)));

    private static string? Admit(string entity, string raw, bool tombstone = false)
    {
        using var payload = JsonDocument.Parse(raw);
        return SyncPayloads.InvalidReason(new SyncVersion(entity, SyncTestIds.For(entity), 1, "unused", Guid.NewGuid(),
            tombstone ? DateTimeOffset.UnixEpoch : null, payload.RootElement));
    }

    // Live and as a full tombstone: the same rule applies to both (05 §5.5).
    private static void AssertAdmission(bool valid, string entity, string raw, string because)
    {
        foreach (var tombstone in LiveAndTombstone)
        { Assert.True((valid ? null : "invalidPayload") == Admit(entity, raw, tombstone), $"{because} (tombstone={tombstone})"); }
    }

    private static string EntityOf(string field) => field == "budgetJson" || field == "text" || field == "language" ? "chatMessage" : "proposal";

    [Fact, Trait("Rule", "B18.embedded-schema-equals-corpus")]
    public void Embedded_schema_bounds_and_vocabularies_equal_Dart_corpus()
    {
        using var corpus = ChatProposalCases.ReadCorpus();
        using var embedded = JsonDocument.Parse(typeof(SyncPayloads).Assembly.GetManifestResourceStream(
            "FitnessBuddy.Modules.UserData.Infrastructure.Schemas.entities.json")!);
        using var contract = Read("sync-entities.json");
        var constants = corpus.RootElement.GetProperty("constants");
        var words = corpus.RootElement.GetProperty("vocabularies");
        Assert.Equal(["codecVersionMax", "codecVersionMin", "json", "kind", "language", "origin", "text"],
            constants.EnumerateObject().Select(p => p.Name).Order(StringComparer.Ordinal));
        Assert.Equal(["chatMessageRole", "chatMessageStatus", "proposalOutcome", "proposalStatus"],
            words.EnumerateObject().Select(p => p.Name).Order(StringComparer.Ordinal));
        foreach (var entity in ChatProposalCases.Entities)
        {
            // The server enforces the embedded registry; it must be the contract, byte for byte in meaning.
            var schema = embedded.RootElement.GetProperty("entities").GetProperty(entity);
            Assert.True(JsonElement.DeepEquals(contract.RootElement.GetProperty("entities").GetProperty(entity), schema), entity);
            Assert.Equal(["1"], schema.EnumerateObject().Select(p => p.Name));
            var v1 = schema.GetProperty("1");
            var props = v1.GetProperty("properties");
            Assert.False(v1.GetProperty("additionalProperties").GetBoolean());
            Assert.Equal(props.EnumerateObject().Select(p => p.Name).Order(StringComparer.Ordinal),
                v1.GetProperty("required").EnumerateArray().Select(v => v.GetString()!).Order(StringComparer.Ordinal));
            Bound(props, "origin", "maxLength", constants.GetProperty("origin"));
            Bound(props, "codecVersion", "minimum", constants.GetProperty("codecVersionMin"));
            Bound(props, "codecVersion", "maximum", constants.GetProperty("codecVersionMax"));
        }
        var chat = embedded.RootElement.GetProperty("entities").GetProperty("chatMessage").GetProperty("1").GetProperty("properties");
        var proposal = embedded.RootElement.GetProperty("entities").GetProperty("proposal").GetProperty("1").GetProperty("properties");
        Bound(chat, "text", "maxLength", constants.GetProperty("text"));
        Bound(chat, "language", "maxLength", constants.GetProperty("language"));
        Bound(chat, "budgetJson", "maxLength", constants.GetProperty("json"));
        Bound(proposal, "kind", "maxLength", constants.GetProperty("kind"));
        Bound(proposal, "interpretationJson", "maxLength", constants.GetProperty("json"));
        Bound(proposal, "draftJson", "maxLength", constants.GetProperty("json"));
        // Closed codes in contract order; outcome additionally admits null.
        Assert.Equal(Strings(words.GetProperty("chatMessageRole")), Strings(chat.GetProperty("role").GetProperty("enum")));
        Assert.Equal(Strings(words.GetProperty("chatMessageStatus")), Strings(chat.GetProperty("status").GetProperty("enum")));
        Assert.Equal(Strings(words.GetProperty("proposalStatus")), Strings(proposal.GetProperty("status").GetProperty("enum")));
        var outcome = proposal.GetProperty("outcome").GetProperty("enum").EnumerateArray().ToArray();
        Assert.Equal(Strings(words.GetProperty("proposalOutcome")), outcome.Where(v => v.ValueKind != JsonValueKind.Null).Select(v => v.GetString()!));
        Assert.Single(outcome, v => v.ValueKind == JsonValueKind.Null);
        // The generic nested string limit (SyncPayloads.Representable) equals the field limit,
        // so a JSON field at its limit can always carry one inner string of its full length.
        Assert.Null(Admit("chatMessage", ChatProposalCases.With(ChatProposalCases.Baseline("chatMessage"), "budgetJson",
            "\"" + new string('x', constants.GetProperty("json").GetInt32() - 2) + "\"")));

        static void Bound(JsonElement props, string field, string keyword, JsonElement expected) =>
            Assert.Equal(expected.GetDecimal(), props.GetProperty(field).GetProperty(keyword).GetDecimal());
    }

    public static IEnumerable<object[]> Payloads() => ChatProposalCases.All().Select(c => new object[] { c.Id, c.Entity, c.Raw, c.Valid });

    [Theory, MemberData(nameof(Payloads)), Trait("Rule", "05.5-payload-validation")]
    public void Payload_matrix_matches_admission_for_live_and_tombstone(string id, string entity, string raw, bool valid) =>
        AssertAdmission(valid, entity, raw, id);

    [Fact, Trait("Rule", "B18.corpus-agreement")]
    public void Corpus_declarations_agree_with_admission_and_asymmetry_lists()
    {
        using var corpus = ChatProposalCases.ReadCorpus();
        var root = corpus.RootElement;
        Assert.Equal(1, root.GetProperty("version").GetInt32());
        var items = root.GetProperty("payloads").EnumerateArray().ToArray();
        var ids = items.Select(c => c.GetProperty("id").GetString()!).ToArray();
        Assert.Equal(ids.Length, ids.Distinct(StringComparer.Ordinal).Count());
        Assert.Equal(235, items.Length);
        // One readable failure listing every disagreeing case, live or tombstone.
        var disagreements = ChatProposalCases.Corpus()
            .SelectMany(c => LiveAndTombstone.Where(t => (c.Valid ? null : "invalidPayload") != Admit(c.Entity, c.Raw, t)).Select(t => $"{c.Id}{(t ? " (tombstone)" : "")}"))
            .ToArray();
        Assert.Empty(disagreements);
        foreach (var item in items)
        {
            Assert.Contains(item.GetProperty("entity").GetString(), ChatProposalCases.Entities);
            Assert.Contains(item.GetProperty("source").GetString(), Sources);
            using var payload = JsonDocument.Parse(item.GetProperty("rawPayload").GetString()!);
            Assert.Equal(JsonValueKind.Object, payload.RootElement.ValueKind);
            if (item.GetProperty("serverAccepts").GetBoolean()) { Assert.True(item.GetProperty("appReads").GetBoolean(), item.GetProperty("id").GetString()); }
        }
        Same(Strings(root.GetProperty("serverRejectsAppTolerates")), items
            .Where(c => !c.GetProperty("serverAccepts").GetBoolean() && c.GetProperty("appReads").GetBoolean())
            .Select(c => c.GetProperty("id").GetString()!));
        foreach (var id in Strings(root.GetProperty("codecServerRejects")))
        {
            var item = items.Single(c => c.GetProperty("id").GetString() == id);
            Assert.Equal("codec", item.GetProperty("source").GetString());
            Assert.False(item.GetProperty("serverAccepts").GetBoolean());
        }
        // Every realistic codec projection is admitted; only the declared pathological ones are not.
        Same(Strings(root.GetProperty("codecServerRejects")), items
            .Where(c => c.GetProperty("source").GetString() == "codec" && !c.GetProperty("serverAccepts").GetBoolean())
            .Select(c => c.GetProperty("id").GetString()!));
        foreach (var scenario in root.GetProperty("restoreScenarios").EnumerateArray())
        {
            foreach (var id in new[] { scenario.GetProperty("messagePayloadId").GetString()! }.Concat(Strings(scenario.GetProperty("cardPayloadIds"))))
            { Assert.True(items.Single(c => c.GetProperty("id").GetString() == id).GetProperty("serverAccepts").GetBoolean(), id); }
        }
        // The pinned asymmetries this step is about (D7, generic nested pass).
        foreach (var id in new[] { "chat-text-lone-high", "chat-text-lone-low", "chat-text-reversed-pair", "chat-budgetJson-raw-lone-high",
            "proposal-draftJson-nested-value-lone-high", "proposal-interpretationJson-nested-key-lone-high", "chat-text-lone-high-tombstone" })
        { Assert.Contains(id, Strings(root.GetProperty("serverRejectsAppTolerates"))); }
    }

    [Fact, Trait("Rule", "B18.utf16-limits")]
    public void B18_json_string_limit_counts_utf16_units_including_supplementary_characters()
    {
        foreach (var (field, limit) in new[] { ("budgetJson", 32768), ("interpretationJson", 32768), ("draftJson", 32768), ("text", 8192) })
        {
            var entity = EntityOf(field);
            var json = field != "text";
            // JSON fields carry JSON text: a JSON string literal of exactly n units.
            string Value(string body) => json ? "\"" + body + "\"" : body;
            int Body(int units) => json ? units - 2 : units;
            var cases = new (string Name, string Value, int Units, bool Valid)[]
            {
                ("ascii-limit", Value(new string('x', Body(limit))), limit, true),
                ("ascii-over", Value(new string('x', Body(limit) + 1)), limit + 1, false),
                // A pair ending exactly at the limit fits; a pair straddling it does not.
                ("pair-ends-at-limit", Value(new string('x', Body(limit) - 2) + Pair), limit, true),
                ("pair-straddles-limit", Value(new string('x', Body(limit) - 1) + Pair), limit + 1, false),
                // Units, not code points or bytes: limit/2 supplementary characters fit
                // (about 2x the limit in UTF-8 bytes); one more unit does not.
                ("all-pairs-limit", Value(string.Concat(Enumerable.Repeat(Pair, Body(limit) / 2))), limit, true),
                ("all-pairs-over", Value(string.Concat(Enumerable.Repeat(Pair, Body(limit) / 2)) + "x"), limit + 1, false),
            };
            foreach (var test in cases)
            {
                Assert.Equal(test.Units, test.Value.Length);
                var raw = ChatProposalCases.With(ChatProposalCases.Baseline(entity), field, test.Value);
                AssertAdmission(test.Valid, entity, raw, $"{field} {test.Name}");
            }
            Assert.True(Encoding.UTF8.GetByteCount(cases[4].Value) > limit * 3 / 2);
        }
    }

    [Fact, Trait("Rule", "B18.closed-vocabularies")]
    public void B18_proposal_status_accepts_pending_confirmed_discarded_superseded()
    {
        var baseline = ChatProposalCases.Baseline("proposal");
        foreach (var status in new[] { "pending", "confirmed", "discarded", "superseded" }) { AssertAdmission(true, "proposal", Set("status", status), status); }
        // Engine `active` is not a wire code (A21 D9); no case folding, no aliases.
        foreach (var status in new[] { "active", "Pending", "PENDING", "resolved", "unchanged", "", " pending" }) { AssertAdmission(false, "proposal", Set("status", status), status); }
        AssertAdmission(false, "proposal", ChatProposalCases.With(baseline, "status", null), "status null");
        AssertAdmission(true, "proposal", ChatProposalCases.With(baseline, "outcome", null), "outcome null");
        foreach (var outcome in new[] { "unchanged", "adjusted", "discarded" }) { AssertAdmission(true, "proposal", Set("outcome", outcome), outcome); }
        foreach (var outcome in new[] { "adjusted chips", "adjustedChips", "Adjusted", "pending", "superseded", "" }) { AssertAdmission(false, "proposal", Set("outcome", outcome), outcome); }
        // No status <-> outcome pairing (D6): lifecycle semantics belong to A23's applier.
        AssertAdmission(true, "proposal", ChatProposalCases.With(Set("status", "pending"), "outcome", "discarded"), "pending+discarded");
        AssertAdmission(true, "proposal", ChatProposalCases.With(Set("status", "confirmed"), "outcome", null), "confirmed+null");
        var chat = ChatProposalCases.Baseline("chatMessage");
        foreach (var role in new[] { "user", "assistant" }) { AssertAdmission(true, "chatMessage", ChatProposalCases.With(chat, "role", role), role); }
        foreach (var role in new[] { "system", "tool", "User", "" }) { AssertAdmission(false, "chatMessage", ChatProposalCases.With(chat, "role", role), role); }
        foreach (var status in new[] { "queued", "pending_offline", "processing", "done", "failed" }) { AssertAdmission(true, "chatMessage", ChatProposalCases.With(chat, "status", status), status); }
        foreach (var status in new[] { "sent", "pendingOffline", "DONE", "pending" }) { AssertAdmission(false, "chatMessage", ChatProposalCases.With(chat, "status", status), status); }

        string Set(string field, string value) => ChatProposalCases.With(baseline, field, value);
    }

    [Fact, Trait("Rule", "B18.null-refs-not-from-chat")]
    public void B18_proposal_not_created_from_chat_admits_null_message_refs_and_interpretation()
    {
        var notFromChat = ChatProposalCases.Raw("proposal-not-from-chat");
        using (var parsed = JsonDocument.Parse(notFromChat))
        {
            foreach (var field in new[] { "originMessageId", "budgetMessageId", "interpretationJson" })
            { Assert.Equal(JsonValueKind.Null, parsed.RootElement.GetProperty(field).ValueKind); }
        }
        // AI-056 target change, DY-004 incomplete day, WO-022 template update, and an open future kind.
        foreach (var kind in new[] { "targetChange", "dayIncomplete", "templateUpdate", "someFutureKind" })
        { AssertAdmission(true, "proposal", ChatProposalCases.With(notFromChat, "kind", kind), kind); }
        // No kind <-> nullability pairing (D6): a foodLog row with null refs is admitted; A21 restore rejects it.
        AssertAdmission(true, "proposal", ChatProposalCases.With(notFromChat, "kind", "foodLog"), "foodLog with null refs");
        AssertAdmission(true, "proposal", ChatProposalCases.Raw("proposal-foodlog-null-refs"), "corpus foodLog null refs");
        // Each ref may be null on its own (no pairing between the two refs either).
        var baseline = ChatProposalCases.Baseline("proposal");
        foreach (var field in new[] { "originMessageId", "budgetMessageId", "interpretationJson" })
        { AssertAdmission(true, "proposal", ChatProposalCases.With(baseline, field, null), field + " null alone"); }
        // Still required: the keys must be present, and draftJson/codecVersion are non-null.
        foreach (var field in new[] { "originMessageId", "budgetMessageId", "interpretationJson", "draftJson", "codecVersion" })
        {
            var absent = JsonNode.Parse(notFromChat)!.AsObject(); absent.Remove(field);
            AssertAdmission(false, "proposal", absent.ToJsonString(), field + " missing");
        }
        AssertAdmission(false, "proposal", ChatProposalCases.With(notFromChat, "draftJson", null), "draftJson null");
        AssertAdmission(false, "proposal", ChatProposalCases.With(notFromChat, "codecVersion", null), "codecVersion null");
    }

    [Fact, Trait("Rule", "B18.no-attachments")]
    public void B18_chatMessage_excludes_local_attachment_paths()
    {
        using var contract = Read("sync-entities.json");
        string[] Fields(string entity) => contract.RootElement.GetProperty("entities").GetProperty(entity).GetProperty("1").GetProperty("properties")
            .EnumerateObject().Select(p => p.Name).Order(StringComparer.Ordinal).ToArray();
        Assert.Equal(["budgetJson", "codecVersion", "createdAtMs", "editedByUser", "language", "origin", "replyToMessageId", "role", "status", "text"], Fields("chatMessage"));
        Assert.Equal(["budgetMessageId", "codecVersion", "createdAtMs", "draftJson", "editedByUser", "interpretationJson", "kind", "origin", "originMessageId", "outcome", "resolvedAtMs", "status"], Fields("proposal"));
        foreach (var entity in ChatProposalCases.Entities)
        {
            var baseline = ChatProposalCases.Baseline(entity);
            foreach (var extra in new[] { "attachmentRefs", "attachmentsJson", "attachments", "localPath", "imagePath", "imagesJson" })
            {
                AssertAdmission(false, entity, ChatProposalCases.With(baseline, extra, new JsonArray("/data/user/0/synthetic/image.jpg")), entity + " " + extra);
                AssertAdmission(false, entity, ChatProposalCases.With(baseline, extra, null), entity + " " + extra + " null");
            }
        }
    }

    [Fact, Trait("Rule", "B18.opaque-engine-json")]
    public void B18_opaque_interpretation_draft_and_budget_JSON_round_trip_without_engine_validation()
    {
        var odd = new[]
        {
            "{}", "[]", "null", "1", "-0.5", "true", "\"text\"", "{ \"a\" :  1 }", "{\"codecVersion\":999}",
            "{\"notAnEngineKey\":[1,2,{\"x\":null}],\"issued\":{\"9/9/9\":\"not-a-uuid\"}}", "[[],[{}],\"\U0001F600\"]",
        };
        foreach (var field in JsonFields)
        {
            var entity = EntityOf(field);
            foreach (var value in odd)
            {
                var raw = ChatProposalCases.With(ChatProposalCases.Baseline(entity), field, value);
                AssertAdmission(true, entity, raw, $"{field} {value}");
                // Admission never rewrites the payload: the opaque string is exactly what was sent.
                using var payload = JsonDocument.Parse(raw);
                Assert.Equal(value, payload.RootElement.GetProperty(field).GetString());
            }
            // The version fingerprint canonicalizes the top-level document but never the opaque
            // string: re-encoding the inner JSON (whitespace) is a different version.
            var baseline = ChatProposalCases.Baseline(entity);
            var compact = Fingerprint(entity, ChatProposalCases.With(baseline, field, "{\"a\":1}"));
            var reordered = JsonNode.Parse(ChatProposalCases.With(baseline, field, "{\"a\":1}"))!.AsObject();
            var shuffled = new JsonObject(reordered.Reverse().Select(p => KeyValuePair.Create(p.Key, p.Value?.DeepClone())));
            Assert.Equal(compact, Fingerprint(entity, shuffled.ToJsonString()));
            Assert.NotEqual(compact, Fingerprint(entity, ChatProposalCases.With(baseline, field, "{ \"a\": 1 }")));
        }
        var cardWithMismatchedCopies = JsonNode.Parse(ChatProposalCases.Raw("codec-six-item-card-1"))!.AsObject();
        // Top-level status/codecVersion are not compared with the copies inside draftJson (D6).
        cardWithMismatchedCopies["status"] = "superseded"; cardWithMismatchedCopies["codecVersion"] = 7;
        AssertAdmission(true, "proposal", cardWithMismatchedCopies.ToJsonString(), "top-level vs draft copies");

        static string Fingerprint(string entity, string raw)
        {
            using var payload = JsonDocument.Parse(raw);
            return Convert.ToHexString(SyncPayloads.Fingerprint(new(entity, Guid.Empty, 1, "unused", Guid.Empty, null, payload.RootElement)));
        }
    }

    [Fact, Trait("Rule", "B18.no-cross-row-validation")]
    public void B18_row_admission_does_not_require_related_message_or_card_rows()
    {
        // SyncPayloads is static and database-free: admission sees exactly one row.
        Assert.True(typeof(SyncPayloads).IsAbstract && typeof(SyncPayloads).IsSealed);
        var dangling = JsonNode.Parse(ChatProposalCases.Raw("codec-follow-up-m2-card-1"))!.AsObject();
        dangling["originMessageId"] = "019a1b2c-0000-7000-8000-0000000d0d01";
        dangling["budgetMessageId"] = "019a1b2c-0000-7000-8000-0000000d0d02";
        AssertAdmission(true, "proposal", dangling.ToJsonString(), "card bound to absent messages");
        // A budget naming cards that were never sent, a card the budget doesn't list, a reply to an absent message.
        AssertAdmission(true, "chatMessage", ChatProposalCases.Raw("chat-budget-foreign-card"), "budget naming absent card");
        AssertAdmission(true, "proposal", ChatProposalCases.Raw("codec-multi-card-card-2"), "card without its message");
        AssertAdmission(true, "chatMessage", ChatProposalCases.With(ChatProposalCases.Raw("codec-six-item-message"), "replyToMessageId", "019a1b2c-0000-7000-8000-0000000d0d03"), "reply to absent message");
        // A user row carrying a budget and an assistant row without one: no role <-> budget pairing.
        var user = ChatProposalCases.With(ChatProposalCases.Raw("codec-six-item-message"), "role", "user");
        AssertAdmission(true, "chatMessage", user, "user row with budget");
        AssertAdmission(true, "chatMessage", ChatProposalCases.With(ChatProposalCases.With(ChatProposalCases.Baseline("chatMessage"), "budgetJson", null), "codecVersion", null), "assistant without budget");
        AssertAdmission(true, "chatMessage", ChatProposalCases.With(ChatProposalCases.Baseline("chatMessage"), "codecVersion", null), "budget without codecVersion");
    }

    // Every entity's free-text strings, top level, plus the nested opaque JSON values and keys
    // (personalFood's nested fields and createdFrom have their own A09 rules and B17 lone-surrogate corpus cases).
    public static IEnumerable<object[]> Utf16Cases()
    {
        using var fixtures = Read("entity-payloads.json");
        using var registry = Read("sync-entities.json");
        foreach (var entity in registry.RootElement.GetProperty("entities").EnumerateObject())
        {
            var raw = fixtures.RootElement.GetProperty(entity.Name).GetRawText();
            foreach (var field in entity.Value.GetProperty("1").GetProperty("properties").EnumerateObject())
            {
                var type = field.Value.GetProperty("type");
                var isString = type.ValueKind == JsonValueKind.Array ? type.EnumerateArray().Any(t => t.GetString() == "string") : type.GetString() == "string";
                if (!isString || field.Value.TryGetProperty("enum", out _) || field.Value.TryGetProperty("format", out _)) { continue; }
                // personalFood.createdFrom is an ASCII-letters code (A09 §3.0), so no pair control can pass.
                if (entity.Name == "personalFood" && field.Name == "createdFrom") { continue; }
                // B21 D13: the workout code and list fields have row-local wire rules (W1 muscle codes, W2
                // aliases as strings, W4 exercise IDs) that the generic controls break; the workout corpus
                // covers lone surrogates in them instead.
                if (entity.Name == "customExercise" && field.Name is "secondaryMusclesJson" or "aliasesJson" ||
                    field.Name == "exerciseId" && entity.Name is "sessionExercise" or "workoutTemplateItem") { continue; }
                if (field.Name.EndsWith("Json", StringComparison.Ordinal))
                {
                    if (entity.Name == "personalFood") { continue; }
                    // value: the raw JSON escape text. "\ud800" at the outer level is a lone unit in the
                    // field string itself; "\\ud800" is a lone unit inside the nested JSON text.
                    yield return [entity.Name, field.Name, "outer", raw, "\"\\\"\\u00e9\\\"\"", "\"\\\"\\ud800\\\"\""];
                    yield return [entity.Name, field.Name, "nested-value", raw, "\"{\\\"a\\\":\\\"x\\\\u00e9\\\"}\"", "\"{\\\"a\\\":\\\"x\\\\ud800\\\"}\""];
                    yield return [entity.Name, field.Name, "nested-value-low", raw, "\"[\\\"\\\\ud83d\\\\ude00\\\"]\"", "\"[\\\"\\\\ude00\\\"]\""];
                    yield return [entity.Name, field.Name, "nested-key", raw, "\"{\\\"\\\\ud83d\\\\ude00\\\":1}\"", "\"{\\\"\\\\ud800\\\":1}\""];
                    yield return [entity.Name, field.Name, "nested-key-reversed", raw, "\"{\\\"k\\\\ud83d\\\\ude00\\\":1}\"", "\"{\\\"k\\\\ude00\\\\ud83d\\\":1}\""];
                }
                else
                {
                    yield return [entity.Name, field.Name, "lone-high", raw, "\"x\\ud83d\\ude00y\"", "\"x\\ud800y\""];
                    yield return [entity.Name, field.Name, "lone-low", raw, "\"x\\ud83d\\ude00y\"", "\"x\\udc00y\""];
                    yield return [entity.Name, field.Name, "reversed-pair", raw, "\"x\\ud83d\\ude00y\"", "\"x\\ude00\\ud83dy\""];
                    yield return [entity.Name, field.Name, "trailing-high", raw, "\"xy\\ud83d\\ude00\"", "\"xy\\ud83d\""];
                }
            }
        }
    }

    [Theory, MemberData(nameof(Utf16Cases)), Trait("Rule", "B18.well-formed-utf16")]
    public void Ill_formed_utf16_is_rejected_for_every_entity(string entity, string field, string shape, string fixture, string wellFormed, string illFormed)
    {
        // The control differs only by a well-formed pair, so the rejection is the unpaired unit.
        AssertAdmission(true, entity, Replace(wellFormed), $"{entity}.{field} {shape} control");
        AssertAdmission(false, entity, Replace(illFormed), $"{entity}.{field} {shape}");

        string Replace(string value)
        {
            var payload = JsonNode.Parse(fixture)!.AsObject(); payload[field] = "\u0001marker\u0001";
            return payload.ToJsonString().Replace("\"\\u0001marker\\u0001\"", value, StringComparison.Ordinal);
        }
    }

    [Fact, Trait("Rule", "B18.well-formed-utf16")]
    public void Ill_formed_utf16_cases_cover_chat_proposal_and_weighIn_note()
    {
        var covered = Utf16Cases().Select(c => $"{c[0]}.{c[1]}").ToHashSet(StringComparer.Ordinal);
        foreach (var field in new[] { "chatMessage.text", "chatMessage.language", "chatMessage.budgetJson", "proposal.kind", "proposal.interpretationJson", "proposal.draftJson", "weighIn.note" })
        { Assert.Contains(field, covered); }
        // Every entity the server admits is covered (the set grows with new entities, e.g. A13a).
        using var registry = JsonDocument.Parse(typeof(SyncPayloads).Assembly.GetManifestResourceStream(
            "FitnessBuddy.Modules.UserData.Infrastructure.Schemas.entities.json")!);
        Same(registry.RootElement.GetProperty("entities").EnumerateObject().Select(e => e.Name),
            Utf16Cases().Select(c => (string)c[0]).Distinct(StringComparer.Ordinal));
    }

    [Fact, Trait("Rule", "B18.codec-version")]
    public void Codec_version_integer_bounds()
    {
        foreach (var entity in ChatProposalCases.Entities)
        {
            var baseline = ChatProposalCases.Baseline(entity);
            foreach (var value in new[] { "1", "2", "2147483647", "1.0", "1e0", "2147483647.000" }) { AssertAdmission(true, entity, Number(value), $"{entity} {value}"); }
            foreach (var value in new[] { "0", "-1", "2147483648", "1.5", "0.999", "\"1\"", "true", "1e10" }) { AssertAdmission(false, entity, Number(value), $"{entity} {value}"); }
            // Nullable only on chatMessage (user rows have no budget).
            AssertAdmission(entity == "chatMessage", entity, ChatProposalCases.With(baseline, "codecVersion", null), $"{entity} null");

            string Number(string value) => ChatProposalCases.With(baseline, "codecVersion", 0).Replace("\"codecVersion\":0", "\"codecVersion\":" + value, StringComparison.Ordinal);
        }
    }

    [Fact(Timeout = 10000), Trait("Rule", "05.5-payload-validation")]
    public void Near_limit_opaque_json_completes_with_bounded_work()
    {
        // Hostile but bounded inputs (each JSON field <= 32768 units): no claim about throughput,
        // only that admission finishes promptly and gives the declared answer.
        var hostile = new (string Value, bool Valid)[]
        {
            (new string('[', 32768), false),
            (new string('[', 24) + new string(']', 24), true),
            (new string('[', 25) + new string(']', 25), false),
            ("[" + string.Join(',', Enumerable.Repeat("0", 500)) + "]", true),
            ("[" + string.Join(',', Enumerable.Repeat("0", 16000)) + "]", false),
            ("[" + string.Join(',', Enumerable.Repeat("[]", 500)) + "]", true),
            ("\"" + string.Concat(Enumerable.Repeat("\\\\", 16383)) + "\"", true),
            ("\"" + string.Concat(Enumerable.Repeat("\\u0041", 5461)) + "\"", true),
            ("{" + string.Join(',', Enumerable.Range(0, 128).Select(i => $"\"{i:D3}{new string('k', 200)}\":0")) + "}", true),
            ("[" + string.Join(',', Enumerable.Repeat("1." + new string('0', 60) + "1", 400)) + "]", false),
            ("[" + string.Join(',', Enumerable.Repeat("123456789.123456789", 500)) + "]", true),
            ("{" + string.Join(',', Enumerable.Repeat("\"a\":1", 2000)) + "}", false),
        };
        foreach (var test in ChatProposalCases.All().Where(c => c.Raw.Length > 8000).Select(c => (Entity: c.Entity, Raw: c.Raw, Valid: c.Valid))
            .Concat(JsonFields.SelectMany(field => hostile.Select(h => (Entity: EntityOf(field), Raw: ChatProposalCases.With(ChatProposalCases.Baseline(EntityOf(field)), field, h.Value), h.Valid)))))
        {
            TestContext.Current.CancellationToken.ThrowIfCancellationRequested();
            Assert.Equal(test.Valid ? null : "invalidPayload", Admit(test.Entity, test.Raw));
        }
        Assert.All(hostile, h => Assert.InRange(h.Value.Length, 1, 32768));
    }

    private static IEnumerable<string> Strings(JsonElement value) => value.EnumerateArray().Select(v => v.GetString()!);
    private static void Same(IEnumerable<string> a, IEnumerable<string> b) => Assert.Equal(a.Order(StringComparer.Ordinal), b.Order(StringComparer.Ordinal));
}
