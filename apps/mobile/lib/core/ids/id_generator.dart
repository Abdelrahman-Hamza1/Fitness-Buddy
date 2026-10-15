import 'package:fb_domain/fb_domain.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'id_generator.g.dart';

/// The app's ID source (UUIDv7, `05` §1). `fb_domain`'s system generator is
/// wired in by the composition root (`lib/app/app_scope.dart`), the only
/// place that imports `package:fb_domain/system.dart`; tests may pass a
/// seeded one.
@Riverpod(keepAlive: true)
IdGenerator idGenerator(Ref ref) => throw UnimplementedError(
  'idGeneratorProvider must be overridden (see lib/app/app_scope.dart).',
);
