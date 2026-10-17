import 'package:fb_domain/fb_domain.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'clock_provider.g.dart';

/// The app's clock (S08 D7). `fb_domain`'s `SystemClock` is wired in by the
/// composition root (`lib/app/app_scope.dart`), the only place that imports
/// `package:fb_domain/system.dart`; tests pass a `ManualClock`.
@Riverpod(keepAlive: true)
Clock clock(Ref ref) => throw UnimplementedError(
  'clockProvider must be overridden (see lib/app/app_scope.dart).',
);
