import 'dart:async';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

/// The unit system as a widget test drives it: the stream of
/// `unitSystemProvider`, starting at [value], changed with [set] (LC-010).
final class UnitFeed {
  /// Creates a feed that starts as metric and closes with the test.
  new() {
    addTearDown(_changes.close);
  }

  final StreamController<UnitSystem> _changes =
      StreamController<UnitSystem>.broadcast();

  /// The current unit system.
  UnitSystem value = UnitSystem.metric;

  /// The values, current one first.
  Stream<UnitSystem> get stream async* {
    yield value;
    yield* _changes.stream;
  }

  /// Switches to [next] and tells every watcher.
  void set(UnitSystem next) {
    value = next;
    _changes.add(next);
  }

  /// The provider override.
  Override get override => unitSystemProvider.overrideWith((ref) => stream);
}
