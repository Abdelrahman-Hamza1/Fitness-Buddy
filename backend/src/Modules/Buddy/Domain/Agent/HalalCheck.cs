using System.Text;
using System.Text.RegularExpressions;

namespace FitnessBuddy.Modules.Buddy.Domain;

internal enum HalalFlag { Pork, Alcohol, UnknownSource }

/// <summary>
/// The server's halal keyword check over food names (FD-081/082, B26 D10): the same word lists and exclusions as the app's
/// <c>fb_domain</c> HalalCheck, on names only (catalog foods carry no ingredient text). A warning in search results; suggestions
/// keep only options without any flag when the profile's halal setting is on.
/// </summary>
internal static partial class HalalCheck
{
    public static HalalFlag[] Flags(params string?[] names)
    {
        var text = Fold(string.Join(" \n ", names.Where(n => !string.IsNullOrWhiteSpace(n))));
        if (text.Trim().Length == 0) { return []; }
        var cleaned = " " + text + " ";
        foreach (var phrase in Exclusions) { cleaned = cleaned.Replace(phrase, " ", StringComparison.Ordinal); }
        var flags = new List<HalalFlag>();
        if (Pork.IsMatch(cleaned)) { flags.Add(HalalFlag.Pork); }
        if (Alcohol.IsMatch(cleaned)) { flags.Add(HalalFlag.Alcohol); }
        if (Unknown.IsMatch(cleaned) || ENumbers().IsMatch(cleaned)) { flags.Add(HalalFlag.UnknownSource); }
        return [.. flags];
    }

    private static readonly string[] PorkEn = ["pork", "pig", "pigs", "swine", "porcine", "bacon", "ham", "hams", "lard", "prosciutto", "pancetta", "jambon", "saindoux", "domuz"];
    private static readonly string[] PorkAr = ["خنزير", "لحم خنزير", "شحم خنزير", "دهن خنزير", "بيكون", "جامبون", "لارد"];
    private static readonly string[] AlcoholEn = ["alcohol", "alcoholic", "ethanol", "ethyl alcohol", "wine", "wines", "beer", "liqueur", "liquor", "rum", "brandy",
        "whisky", "whiskey", "vodka", "cognac", "gin", "sherry", "marsala", "kirsch", "mirin"];
    private static readonly string[] AlcoholAr = ["كحول", "كحولي", "كحوليه", "ايثانول", "نبيذ", "خمر", "بيره", "مشروب كحولي", "براندي", "ويسكي", "فودكا"];
    private static readonly string[] UnknownEn = ["gelatin", "gelatine", "mono and diglycerides", "mono and di glycerides", "monoglycerides", "diglycerides", "glycerol",
        "glycerin", "glycerine", "animal fat", "animal fats", "rennet", "pepsin", "l cysteine"];
    private static readonly string[] UnknownAr = ["جيلاتين", "جلاتين", "مستحلب حيواني", "احادي وثنائي الجليسريد", "جليسرين", "جلسرين", "منفحه", "دهن حيواني", "دهون حيوانيه"];
    private static readonly string[] Exclusions = new[]
    {
        "sugar alcohols", "sugar alcohol", "alcohol free", "non alcoholic", "nonalcoholic", "0 alcohol", "wine vinegar", "root beer", "ginger beer",
        "turkey ham", "chicken ham", "beef ham", "turkey bacon", "chicken bacon", "beef bacon", "halal bacon", "microbial rennet", "vegetable rennet",
        "vegetarian rennet", "vegetable glycerin", "vegetable glycerine", "خالي من الكحول", "خال من الكحول", "بدون كحول", "كحول سكري", "كحولات سكريه",
        "منفحه نباتيه", "منفحه ميكروبيه",
    }.Select(p => " " + Fold(p) + " ").ToArray();

    private static readonly Regex Pork = Words(PorkEn, PorkAr);
    private static readonly Regex Alcohol = Words(AlcoholEn, AlcoholAr);
    private static readonly Regex Unknown = Words(UnknownEn, UnknownAr);

    // E441 gelatin, E422 glycerol, E470–E482 emulsifiers of possible animal origin, E542 bone phosphate, E920 L-cysteine.
    [GeneratedRegex(@"(?<=\s)e ?(441|422|470|471|472|473|474|475|477|478|481|482|542|920)[a-f]?(?=\s)")] private static partial Regex ENumbers();

    private static Regex Words(string[] latin, string[] arabic)
    {
        static string Alt(IEnumerable<string> words) => string.Join('|', words.Select(w => Regex.Escape(Fold(w)).Replace(@"\ ", @"\s", StringComparison.Ordinal)));
        // Arabic: an optional و/ف/ب/ل/ك and then the article, on the first word.
        return new Regex($@"(?<=\s)(?:(?:{Alt(latin)})|(?:[وفبلك]?(?:ال)?(?:{Alt(arabic)})))(?=\s)", RegexOptions.CultureInvariant, TimeSpan.FromSeconds(1));
    }

    /// <summary>Lower case, Arabic letter forms folded, everything that isn't a letter or digit a single space.</summary>
    private static string Fold(string text)
    {
        var sb = new StringBuilder(text.Length);
        foreach (var raw in text.ToLowerInvariant())
        {
            var c = raw switch { 'أ' or 'إ' or 'آ' or 'ٱ' => 'ا', 'ى' => 'ي', 'ة' => 'ه', _ => raw };
            if (c is >= 'ً' and <= 'ْ' or 'ٰ' or 'ـ') { continue; }
            sb.Append(char.IsLetterOrDigit(c) ? c : ' ');
        }
        return MultiSpace().Replace(sb.ToString(), " ");
    }

    [GeneratedRegex(@"\s+")] private static partial Regex MultiSpace();
    internal static string Code(HalalFlag flag) => flag switch { HalalFlag.Pork => "pork", HalalFlag.Alcohol => "alcohol", _ => "unknownSource" };
}
