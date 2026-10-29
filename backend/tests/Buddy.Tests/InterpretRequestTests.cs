using System.ComponentModel.DataAnnotations;
using FitnessBuddy.Modules.Buddy.Api;

namespace FitnessBuddy.Buddy.Tests;

// Context reference IDs accept TD-070 natural UUIDv5 IDs; client-minted message/proposal IDs stay UUIDv7.
public sealed class InterpretRequestTests
{
    // uuidv5(fbNamespace, 'mealSlot:normal:<key>'), packages/fb_domain/lib/src/diary/meal_slot.dart DefaultSlots (TD-070).
    internal static readonly BuddySlot[] DefaultSlots =
    [
        new(Guid.Parse("4c5aed24-f404-506e-a925-f0ff33099753"), "Breakfast", "04:00-11:00"),
        new(Guid.Parse("ca0daf21-3d15-53c5-b4ec-ee09a5e0c674"), "Lunch", "11:00-16:00"),
        new(Guid.Parse("260cb3fe-def5-53e5-9f5c-d64f61a4ec3e"), "Dinner", "16:00-22:00"),
        new(Guid.Parse("9c906ed8-064d-52d3-b116-803e12ee5630"), "Snacks", null),
    ];
    private static readonly Guid Natural = DefaultSlots[0].Id;

    [Fact]
    [Trait("Rule", "05.1-natural-ids")]
    public void Default_natural_slot_ids_are_accepted()
    {
        Assert.Empty(Validate(Request(slots: DefaultSlots)));
    }

    [Fact]
    [Trait("Rule", "05.1-natural-ids")]
    public void Every_context_reference_list_accepts_natural_ids()
    {
        var context = Context(
            foods: [new(Natural, ["eggs"], [], "cooked", new(155, 13, 1, 11, 0), [])],
            named: [new(Natural, "lunchbox")],
            recent: [new(Natural, new DateOnly(2026, 10, 28), "Breakfast", "eggs", 100)]);
        Assert.Empty(Validate(Request(slots: DefaultSlots, context: context)));
    }

    [Fact]
    [Trait("Rule", "05.1-natural-ids")]
    public void Nil_reference_ids_are_rejected()
    {
        Assert.Contains("slots", Keys(Request(slots: [new(Guid.Empty, "Breakfast", null)])));
        Assert.Contains("context", Keys(Request(context: Context(named: [new(Guid.Empty, "lunchbox")]))));
        Assert.Contains("context", Keys(Request(context: Context(recent: [new(Guid.Empty, new DateOnly(2026, 10, 28), "Breakfast", "eggs", null)]))));
        Assert.Contains("context", Keys(Request(context: Context(foods: [new(Guid.Empty, ["eggs"], [], "cooked", new(155, 13, 1, 11, 0), [])]))));
    }

    [Fact]
    [Trait("Rule", "05.1-natural-ids")]
    public void Request_and_active_proposal_ids_stay_uuidv7_only()
    {
        Assert.Contains("requestId", Keys(Request(requestId: Natural)));
        Assert.Contains("requestId", Keys(Request(requestId: Guid.NewGuid())));
        Assert.Contains("requestId", Keys(Request(requestId: Guid.Empty)));
        Assert.Contains("requestId", Keys(Request(activeProposal: Natural)));
        Assert.Empty(Validate(Request(activeProposal: Guid.CreateVersion7())));
    }

    [Fact]
    [Trait("Req", "AC-041")]
    public void Active_card_is_optional_bounded_and_needs_its_proposal()
    {
        static BuddyActiveCardLine Line(string name = "eggs", double? amount = 2) => new(name, amount, "piece", "cooked");
        static InterpretRequest WithCard(BuddyActiveCard card) => Request(activeProposal: Guid.CreateVersion7(), context: Context() with { ActiveCard = card });
        Assert.Empty(Validate(WithCard(new("Breakfast", "08:00", [.. Enumerable.Repeat(Line(), 30)]))));
        Assert.Empty(Validate(WithCard(new(null, "23:59", []))));
        Assert.Empty(Validate(WithCard(new(null, null, [Line(amount: null)]))));
        Assert.Null(Request().ToInput().Context.ActiveCard);
        Assert.Contains("context", Keys(Request(context: Context() with { ActiveCard = new("Breakfast", "08:00", [Line()]) })));
        Assert.Contains("context", Keys(WithCard(new("Breakfast", null, [.. Enumerable.Repeat(Line(), 31)]))));
        Assert.Contains("context", Keys(WithCard(new("Breakfast", null, [Line(new string('a', 201))]))));
        Assert.Contains("context", Keys(WithCard(new("Breakfast", null, [Line(" ")]))));
        Assert.Contains("context", Keys(WithCard(new("Breakfast", null, [Line(amount: double.NaN)]))));
        Assert.Contains("context", Keys(WithCard(new("Breakfast", null, [Line(amount: 0)]))));
        Assert.Contains("context", Keys(WithCard(new(new string('s', 201), null, [Line()]))));
        Assert.Contains("context", Keys(WithCard(new("Breakfast", null, [null!]))));
        foreach (var time in new[] { "8:00", "24:00", "08:60", "8 am", "" }) { Assert.Contains("context", Keys(WithCard(new("Breakfast", time, [Line()])))); }
        var card = WithCard(new("Breakfast", "08:00", [Line()])).ToInput().Context.ActiveCard!;
        Assert.Equal(("Breakfast", "08:00", "eggs", 2d, "piece", "cooked"), (card.Slot, card.Time, card.Lines[0].Name, card.Lines[0].Amount!.Value, card.Lines[0].UnitCode, card.Lines[0].State));
    }

    [Fact]
    [Trait("Req", "AC-041")]
    public void Duplicate_reference_ids_are_rejected_in_every_list()
    {
        var food = new BuddyPersonalFood(Natural, ["eggs"], [], "cooked", new(155, 13, 1, 11, 0), []);
        Assert.Contains("slots", Keys(Request(slots: [DefaultSlots[0], DefaultSlots[0] with { Name = "Second" }])));
        Assert.Contains("context", Keys(Request(context: Context(foods: [food, food with { Names = ["other"] }]))));
        Assert.Contains("context", Keys(Request(context: Context(named: [new(Natural, "a"), new(Natural, "b")]))));
        Assert.Contains("context", Keys(Request(context: Context(recent: [new(Natural, new DateOnly(2026, 10, 28), "Lunch", "rice", null), new(Natural, new DateOnly(2026, 10, 27), "Lunch", "rice", null)]))));
    }

    private static InterpretRequest Request(Guid? requestId = null, BuddySlot[]? slots = null, Guid? activeProposal = null, BuddyContext? context = null) =>
        new(requestId ?? Guid.CreateVersion7(), "two eggs", new DateTimeOffset(2026, 10, 29, 8, 0, 0, TimeSpan.Zero), 180,
            new(false, null, null), slots ?? [], activeProposal, context ?? Context());

    private static BuddyContext Context(BuddyPersonalFood[]? foods = null, BuddyNamedReference[]? named = null, BuddyRecentEntry[]? recent = null) =>
        new(foods ?? [], named ?? [], named ?? [], [], recent ?? [], named ?? []);

    private static List<ValidationResult> Validate(InterpretRequest request)
    {
        var results = new List<ValidationResult>();
        Validator.TryValidateObject(request, new ValidationContext(request), results, validateAllProperties: true);
        return results;
    }

    private static string[] Keys(InterpretRequest request) => Validate(request).SelectMany(r => r.MemberNames).ToArray();
}
