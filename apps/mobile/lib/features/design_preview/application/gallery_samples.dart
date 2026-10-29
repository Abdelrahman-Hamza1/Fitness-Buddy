// The constants are sample data, documented by the class.
// ignore_for_file: public_member_api_docs

/// Sample content of the component gallery: made-up food names, numbers and
/// state names, as data and not UI strings (A02 D15). The gallery's own labels
/// (headings, buttons) are in the ARB file.
abstract final class GallerySamples {
  /// Sample text drawn on each colour pair of the Tokens tab.
  static const String contrastSample = 'Aa';

  // Buttons and chips.
  static const String logIt = 'Log it';
  static const String discard = 'Discard';
  static const String notNow = 'Not now';
  static const String addFood = 'Add food';
  static const String scan = 'Scan';
  static const String more = 'More';
  static const String rename = 'Rename';
  static const String delete = 'Delete';
  static const String longButton = 'Add this meal to the diary for dinner';
  static const String assumption = 'Assumed 1 cup of rice';
  static const String small = 'Small';
  static const String medium = 'Medium';
  static const String large = 'Large';
  static const String coffee = 'Coffee';
  static const String banana = 'Banana';
  static const String yoghurt = 'Greek yoghurt with honey';

  // Cards, rows and headers.
  static const String chickenAndRice = 'Chicken and rice, 520 kcal';
  static const String longText =
      'A long description that wraps at large text sizes';
  static const String breakfast = 'Breakfast';
  static const String twoItems = '2 items';
  static const String oats = 'Oats';
  static const String oatsAmount = '40 g';
  static const String oatsKcal = '150 kcal';
  static const String longRowTitle =
      'Grilled chicken breast with roasted vegetables and tahini sauce';
  static const String longRowSubtitle =
      'A long subtitle that also needs to wrap on narrow screens';
  static const String chicken650 = '650 kcal';
  static const String dinner = 'Dinner';
  static const String add = 'Add';
  static const String seeAll = 'See all';
  static const String longSectionTitle = 'A very long section title that wraps';

  // Numbers.
  static const String kcalLeftValue = '1,240';
  static const String kcalLeft = 'kcal left';
  static const String kcalOverValue = '180';
  static const String kcalOver = 'kcal over';
  static const String hugeValue = '12,345,678';
  static const String protein = 'Protein';
  static const String carbs = 'Carbs';
  static const String fat = 'Fat';
  static const String fiber = 'Fiber';

  // Banners, empty state, input.
  static const String bannerInfo = 'Weights are shown in kilograms.';
  static const String bannerOffline =
      'You are offline. Buddy needs a connection.';
  static const String bannerPending = 'Waiting to sync.';
  static const String bannerError = 'Something went wrong.';
  static const String bannerErrorLong =
      'Could not save this entry, please try again later.';
  static const String retry = 'Retry';
  static const String emptyTitle = 'Nothing logged yet';
  static const String emptyMessage =
      'Tell Buddy what you ate and it shows up here.';
  static const String hint = 'Tell Buddy what you ate';

  /// Hint of the search field.
  static const String searchHint = 'Search foods';
  static const String mealChipLabel = 'Meal';
  static const String lunch = 'Lunch';
  static const String timeChipLabel = 'Time';
  static const String nameFieldLabel = 'Name';
  static const String nameFieldHint = 'Breakfast bowl';
  static const String nameFieldError = 'Give it a name';
  static const String numberFieldLabel = 'Protein';
  static const String numberFieldUnit = 'g';
  static const String numberFieldError = 'More than 100 g in 100 g';

  /// The amount display: number, unit and what a screen reader says.
  static const String amountNumber = '100';
  static const String amountUnit = 'g';
  static const String amountLabel = 'Amount, 100 g';
  static const String longHint =
      'Tell Buddy what you ate, weighed or want to log later';

  // Dates, estimates, sheets, snackbars.
  static const String yesterday = 'Yesterday';
  static const String today = 'Today';
  static const String longDate = 'Wednesday, 30 September 2026';
  static const String estimateRange = '450 to 650 kcal';
  static const String estimateReason =
      'The portion size and the oil used were not stated.';
  static const String sheetTitle = 'Add food';
  static const String sheetBody =
      'Sheet content that explains something helpful.';
  static const String loggedOats = 'Logged Oats, 150 kcal';
  static const String weightSaved = 'Weight saved';

  // Disclosure rows and swipe actions.
  static const String chickenAndRiceDish = 'Chicken and rice';
  static const String threeItems = '3 items';
  static const String dishKcal = '520 kcal';
  static const String swipeDelete = 'Delete';
  static const String swipeMove = 'Move to another meal';
  static const String deleted = 'Deleted';
  static const String moveAsked = 'Pick a meal to move it to';

  // Switch rows and option sheets.
  static const String halalTitle = 'Halal food';
  static const String halalSubtitle = 'Only halal foods';
  static const String optionsTitle = 'Units';
  static const String optionMetric = 'Metric';
  static const String optionMetricHint = 'Grams, millilitres';
  static const String optionImperial = 'Imperial';
  static const String optionImperialHint = 'Ounces, fluid ounces';

  // Reorderable list.
  static const List<String> meals = ['Breakfast', 'Lunch', 'Dinner', 'Snacks'];

  // Units.
  static const String gram = 'g';
  static const String millilitre = 'ml';
  static const String piece = 'piece';
  static const String cup = 'cup';

  // Buddy: chat and proposal card (A22).
  static const String chatUser = '2 eggs and a tsp of oil';
  static const String chatBuddy =
      "Here's your meal. Check it, then tap Log it.";
  static const String cardHeader = 'Breakfast · 8:40 AM';
  static const String cardDish = 'Eggs with oil';
  static const String egg = 'Egg, boiled';
  static const String eggAmount = '2 pieces (100 g)';
  static const String eggKcal = '155 kcal';
  static const String oil = 'Olive oil';
  static const String oilAmount = '1 tsp (4.5 g)';
  static const String oilKcal = '40 kcal';
  static const String oilNote = 'Most of the cooking oil counted';
  static const String oilRange = '30–50 kcal';
  static const String oilReason = 'The amount was guessed.';
  static const String cardTotal = '~195 kcal · Today after this: 1,045 left';
  static const String cardReason = 'Add an amount to log this.';
  static const String logged = 'Logged 195 kcal · 1,045 left today';
  static const String undo = 'Undo';
  static const String composerHint = 'Tell Buddy what you ate…';
  static const String send = 'Send';
  static const String searchFoods = 'Search foods';
}
