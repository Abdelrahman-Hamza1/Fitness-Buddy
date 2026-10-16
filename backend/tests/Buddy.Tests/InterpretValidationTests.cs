using System.Text.Json.Nodes;
using FitnessBuddy.Modules.Buddy.Infrastructure;

namespace FitnessBuddy.Buddy.Tests;

public sealed class InterpretValidationTests
{
    [Theory]
    [InlineData("nutrients")]
    [InlineData("missing")]
    [InlineData("nullItem")]
    [InlineData("nullIntents")]
    [InlineData("unknownKind")]
    [InlineData("zeroAmount")]
    [InlineData("quotedAmount")]
    [InlineData("integerEnum")]
    [InlineData("nutrientUnit")]
    [InlineData("unknownUnit")]
    [InlineData("duplicateProperty")]
    [InlineData("emptyIntents")]
    [InlineData("invalidShape")]
    [Trait("Req", "AI-070")]
    [Trait("Rule", "06.1-schema-validation")]
    public async Task Untrusted_output_is_validated_beyond_the_native_provider_schema(string mutation)
    {
        var wire = JsonNode.Parse(await OpenAIContractTests.FixtureAsync("en-eggs"))!;
        var value = JsonNode.Parse(wire["output"]![1]!["content"]![0]!["text"]!.GetValue<string>())!;
        var intent = value["intents"]![0]!;
        var item = intent["items"]![0]!;
        switch (mutation)
        {
            case "nutrients": item["calories"] = 200; break;
            case "missing": item.AsObject().Remove("amount"); break;
            case "nullItem": intent["items"]![0] = null; break;
            case "nullIntents": value["intents"] = null; break;
            case "unknownKind": intent["kind"] = "writeDiary"; break;
            case "zeroAmount": item["amount"] = 0; break;
            case "quotedAmount": item["amount"] = "2"; break;
            case "unknownUnit": item["unit"] = "mystery"; break;
            case "nutrientUnit": item["unit"] = "kcal"; break;
            case "duplicateProperty":
                Assert.Null(InterpretProtocol.Parse(value.ToJsonString().Replace("\"amount\":2", "\"amount\":2,\"amount\":3", StringComparison.Ordinal)));
                return;
            case "integerEnum": intent["kind"] = 0; break;
            case "emptyIntents": value["intents"] = new JsonArray(); break;
            case "invalidShape": intent["kind"] = "weighIn"; break;
        }
        Assert.Null(InterpretProtocol.Parse(value.ToJsonString()));
    }

    [Fact]
    [Trait("Req", "AI-015")]
    public async Task Multi_intent_weights_workout_and_ambiguity_are_interpretations_only()
    {
        var wire = JsonNode.Parse(await OpenAIContractTests.FixtureAsync("en-eggs"))!;
        var value = JsonNode.Parse(wire["output"]![1]!["content"]![0]!["text"]!.GetValue<string>())!;
        value["intents"]![0]!["items"]![0]!["ambiguities"] = new JsonArray("portion");
        value["intents"]!.AsArray().Add(JsonNode.Parse("""
            {"kind":"weighIn","timeHint":"today","slotHint":null,"items":[],"weighIn":{"value":97.2,"unit":"kg"},"exercises":[],"reason":null}
            """));
        value["intents"]!.AsArray().Add(JsonNode.Parse("""
            {"kind":"workout","timeHint":null,"slotHint":null,"items":[],"weighIn":null,"exercises":[{"name":"bench press","sets":[{"count":3,"reps":8,"weight":80,"unit":"kg"}]}],"reason":null}
            """));
        var parsed = InterpretProtocol.Parse(value.ToJsonString());
        Assert.NotNull(parsed);
        Assert.Equal(3, parsed.Intents.Length);
        Assert.Equal(97.2m, parsed.Intents[1].WeighIn!.Value);
        Assert.Equal(3, parsed.Intents[2].Exercises[0].Sets[0].Count);
    }
}
