import 'package:fb_mobile/features/foods/application/personal_food_form.dart';
import 'package:flutter/widgets.dart';

/// The text a number field shows for a stored buffer: `30.0` reads `30`.
String shownNumber(String buffer) =>
    buffer.contains('.') ? buffer.replaceFirst(RegExp(r'\.0+$'), '') : buffer;

/// The fields that hold a number (everything else is free text, which must
/// never be "cleaned": a name can end in `.0`).
const Set<PersonalFoodField> numericFields = {
  PersonalFoodField.kcal,
  PersonalFoodField.protein,
  PersonalFoodField.carbs,
  PersonalFoodField.fat,
  PersonalFoodField.fiber,
  PersonalFoodField.sugar,
  PersonalFoodField.saturatedFat,
  PersonalFoodField.transFat,
  PersonalFoodField.sodium,
  PersonalFoodField.cholesterol,
  PersonalFoodField.alcohol,
  PersonalFoodField.servingSize,
};

/// One food-specific serving row: its unit and the controller of its size.
final class ServingRowInput {
  /// Creates a row for [unit] showing [text].
  new(this.unit, String text)
    : amount = TextEditingController(text: text),
      focus = FocusNode();

  /// The closed unit code of the row.
  String unit;

  /// The typed size.
  final TextEditingController amount;

  /// The size field's focus.
  final FocusNode focus;

  /// Releases the controller and the focus node.
  void dispose() {
    amount.dispose();
    focus.dispose();
  }
}

/// The text controllers and focus nodes of one open form (the view model
/// keeps the typed values; these are only what the fields edit).
///
/// Made on the first build with data, so a new form starts from the typed
/// state (a search's name) and an edit form from the stored food.
final class PersonalFoodInputs {
  final Map<PersonalFoodField, TextEditingController> _controllers = {};
  final Map<PersonalFoodField, FocusNode> _focus = {};

  /// The serving rows, in the order shown.
  final List<ServingRowInput> servings = [];
  bool _servingsMade = false;

  /// The controller of [field], starting from [state]'s buffer.
  TextEditingController controller(
    PersonalFoodField field,
    PersonalFoodFormState state,
  ) => _controllers.putIfAbsent(
    field,
    () => TextEditingController(text: _initialText(field, state)),
  );

  /// The focus node of [field].
  FocusNode focus(PersonalFoodField field) =>
      _focus.putIfAbsent(field, FocusNode.new);

  String _initialText(PersonalFoodField field, PersonalFoodFormState state) =>
      numericFields.contains(field) && !state.touched.contains(field)
      ? shownNumber(state.text(field))
      : state.text(field);

  /// Makes the serving rows from [state] once.
  void ensureServings(PersonalFoodFormState state) {
    if (_servingsMade) return;
    _servingsMade = true;
    _fillServings(state);
  }

  void _fillServings(PersonalFoodFormState state) {
    for (final row in servings) {
      row.dispose();
    }
    servings
      ..clear()
      ..addAll([
        for (final s in state.servings)
          ServingRowInput(
            s.unit,
            state.touched.contains(PersonalFoodField.servings)
                ? s.amount
                : shownNumber(s.amount),
          ),
      ]);
  }

  /// The serving rows as the view model's input.
  List<PersonalFoodServingInput> get servingInputs => [
    for (final row in servings)
      PersonalFoodServingInput(row.unit, row.amount.text),
  ];

  /// Adds an empty row for [unit].
  void addServing(String unit) => servings.add(ServingRowInput(unit, ''));

  /// Removes and releases the row at [index].
  void removeServing(int index) => servings.removeAt(index).dispose();

  /// After a Reload: shows the view model's buffers again (what was typed
  /// stays, the rest is the stored food's).
  void resync(PersonalFoodFormState state) {
    for (final MapEntry(:key, :value) in _controllers.entries) {
      final text = _initialText(key, state);
      if (value.text != text) value.text = text;
    }
    _fillServings(state);
    _servingsMade = true;
  }

  /// Releases every controller and focus node.
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final node in _focus.values) {
      node.dispose();
    }
    for (final row in servings) {
      row.dispose();
    }
  }
}
