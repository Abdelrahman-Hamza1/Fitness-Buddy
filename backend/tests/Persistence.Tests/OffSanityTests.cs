using System.Text.Json;
using FitnessBuddy.Modules.Catalog.Application;
using FitnessBuddy.Modules.Catalog.Infrastructure;

namespace FitnessBuddy.Persistence.Tests;

/// <summary>B22: the OFF sanity checks, on OFF-shaped payloads (no network). Mapper repairs, then <see cref="OffSanity.Check"/> decides.</summary>
[Trait("Req", "FD-012")]
[Trait("Rule", "07.3-off-sanity")]
public sealed class OffSanityTests
{
    private static (OffProduct Product, OffVerdict Verdict) Run(string nutriments, string extra = "")
    {
        using var doc = JsonDocument.Parse("{\"product_name\":\"Synthetic oat biscuit\"," + extra + "\"nutriments\":{" + nutriments + "}}");
        var product = OffMapper.Map(doc.RootElement, "5000000000001");
        return (product, OffSanity.Check(product.Per100, product.Basis));
    }

    [Fact]
    public void A_consistent_product_passes_untouched()
    {
        var (p, v) = Run("\"energy-kcal_100g\":258,\"energy-kj_100g\":1080,\"proteins_100g\":6,\"carbohydrates_100g\":45,\"fat_100g\":6,\"fiber_100g\":3");
        Assert.False(v.Rejected); Assert.Empty(v.Warnings); Assert.Empty(p.Corrections!); Assert.Equal(258, p.Per100.Kcal);
    }

    [Fact]
    public void Energy_only_in_kj_is_converted_to_kcal()
    {
        var (p, v) = Run("\"energy-kj_100g\":1046,\"proteins_100g\":6,\"carbohydrates_100g\":45,\"fat_100g\":6");
        Assert.Equal(250, p.Per100.Kcal!.Value, 3); Assert.Equal([OffSanity.KjConverted], p.Corrections!); Assert.Empty(v.Warnings);
    }

    [Fact]
    public void A_kcal_field_that_holds_the_kj_number_is_fixed_from_the_kj_field()
    {
        var (p, v) = Run("\"energy-kcal_100g\":1046,\"energy-kj_100g\":1046,\"proteins_100g\":6,\"carbohydrates_100g\":45,\"fat_100g\":6");
        Assert.Equal(250, p.Per100.Kcal!.Value, 3); Assert.Equal([OffSanity.KjInKcal], p.Corrections!); Assert.False(v.Rejected); Assert.Empty(v.Warnings);
    }

    [Fact]
    public void Kcal_that_is_4184_times_the_macro_energy_is_fixed_without_a_kj_field()
    {
        // 1046 would be rejected as too high; the macros (258 kcal x 4.184 = 1079) show it is kJ.
        var (p, v) = Run("\"energy-kcal_100g\":1046,\"proteins_100g\":6,\"carbohydrates_100g\":45,\"fat_100g\":6");
        Assert.Equal(250, p.Per100.Kcal!.Value, 3); Assert.Equal([OffSanity.KjInKcal], p.Corrections!); Assert.False(v.Rejected);
    }

    [Fact]
    public void Only_per_serving_data_with_a_serving_in_grams_is_scaled_to_per_100()
    {
        var (p, v) = Run("\"energy-kcal_serving\":75,\"proteins_serving\":1.8,\"carbohydrates_serving\":13.5,\"fat_serving\":1.8", "\"serving_quantity\":30,\"serving_quantity_unit\":\"g\",");
        Assert.Equal(250, p.Per100.Kcal!.Value, 3); Assert.Equal(6, p.Per100.ProteinG!.Value, 3); Assert.Equal(45, p.Per100.CarbsG!.Value, 3);
        Assert.Equal([OffSanity.PerServingScaled], p.Corrections!); Assert.False(v.Rejected);
    }

    [Fact]
    public void Per_100_values_equal_to_the_per_serving_ones_of_a_30_g_serving_are_rescaled()
    {
        var (p, _) = Run("\"energy-kcal_100g\":75,\"proteins_100g\":1.8,\"carbohydrates_100g\":13.5,\"fat_100g\":1.8,"
            + "\"energy-kcal_serving\":75,\"proteins_serving\":1.8,\"carbohydrates_serving\":13.5,\"fat_serving\":1.8", "\"serving_quantity\":30,\"serving_quantity_unit\":\"g\",");
        Assert.Equal(250, p.Per100.Kcal!.Value, 3); Assert.Equal(45, p.Per100.CarbsG!.Value, 3); Assert.Equal([OffSanity.PerServingInPer100], p.Corrections!);
    }

    [Fact]
    public void A_serving_of_exactly_100_g_proves_nothing_and_is_left_alone()
    {
        var (p, _) = Run("\"energy-kcal_100g\":250,\"proteins_100g\":6,\"carbohydrates_100g\":45,\"fat_100g\":6,\"energy-kcal_serving\":250,\"proteins_serving\":6,\"carbohydrates_serving\":45,\"fat_serving\":6",
            "\"serving_quantity\":100,\"serving_quantity_unit\":\"g\",");
        Assert.Empty(p.Corrections!); Assert.Equal(250, p.Per100.Kcal);
    }

    [Fact]
    public void Energy_that_does_not_fit_the_macros_is_a_warning_not_a_reject()
    {
        var (_, v) = Run("\"energy-kcal_100g\":400,\"proteins_100g\":6,\"carbohydrates_100g\":45,\"fat_100g\":6");
        Assert.False(v.Rejected); Assert.Equal([OffSanity.EnergyMacrosMismatch], v.Warnings);
    }

    [Fact]
    public void Alcohol_counts_at_7_kcal_per_gram_and_fiber_uses_the_closer_convention()
    {
        var (_, beer) = Run("\"energy-kcal_100g\":43,\"proteins_100g\":0.5,\"carbohydrates_100g\":3.6,\"fat_100g\":0,\"alcohol_100g\":3.8");
        Assert.Empty(beer.Warnings);
        // 4*10 + 4*60 + 9*5 = 325; with fiber separate, +2*20 = 365. Stated 365 matches the EU convention.
        var (_, eu) = Run("\"energy-kcal_100g\":365,\"proteins_100g\":10,\"carbohydrates_100g\":60,\"fat_100g\":5,\"fiber_100g\":20");
        Assert.Empty(eu.Warnings);
    }

    [Theory]
    [InlineData("\"energy-kcal_100g\":1500,\"proteins_100g\":30,\"carbohydrates_100g\":30,\"fat_100g\":50", OffSanity.EnergyTooHigh)]
    [InlineData("\"energy-kcal_100g\":600,\"proteins_100g\":60,\"carbohydrates_100g\":50,\"fat_100g\":20", OffSanity.MacrosTooHeavy)]
    [InlineData("\"energy-kcal_100g\":250,\"proteins_100g\":-6,\"carbohydrates_100g\":45,\"fat_100g\":6", OffSanity.Negative)]
    [InlineData("\"proteins_100g\":6,\"carbohydrates_100g\":45,\"fat_100g\":6", OffSanity.MissingEnergy)]
    [InlineData("\"energy-kcal_100g\":250", OffSanity.MissingMacros)]
    public void Impossible_or_unusable_products_are_rejected(string nutriments, string rule)
    {
        var (_, v) = Run(nutriments);
        Assert.True(v.Rejected); Assert.Contains(rule, v.Rejects);
    }

    [Fact]
    public void Dense_liquids_may_exceed_100_g_of_macros_per_100_ml()
    {
        var (_, v) = Run("\"energy-kcal_100g\":330,\"proteins_100g\":0.4,\"carbohydrates_100g\":82,\"fat_100g\":0", "\"product_quantity_unit\":\"ml\",");
        Assert.False(v.Rejected);
    }
}
