/// Local drag order survives old query emissions until acknowledged (A10 D12).
final class SlotEditorState {
  /// No pending local order initially.
  const new({this.orderOverride});

  /// Immutable local order while the command/query catches up.
  final List<String>? orderOverride;

  /// Retain the dropped order without mutating repository rows.
  SlotEditorState dropped(Iterable<String> order) =>
      SlotEditorState(orderOverride: List.unmodifiable(order));

  /// A matching emission acknowledges the local order.
  SlotEditorState onEmission(List<String> order) =>
      orderOverride != null && _same(orderOverride!, order)
      ? const SlotEditorState()
      : this;

  /// A refused command drops the optimistic order.
  SlotEditorState failed() => const SlotEditorState();

  /// Order displayed by the list.
  List<String> visible(List<String> stored) => orderOverride ?? stored;
}

bool _same(List<String> a, List<String> b) =>
    a.length == b.length && a.indexed.every((pair) => pair.$2 == b[pair.$1]);
