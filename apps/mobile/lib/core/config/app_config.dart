import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_config.g.dart';

/// The build flavor: which API the app talks to (S06 plan D6).
enum AppFlavor {
  /// The local API on the developer's machine (`dotnet run`, port 5198).
  dev,

  /// The staging API.
  staging,

  /// The production API.
  prod,
}

/// Thrown when the compile-time configuration is missing or invalid.
final class AppConfigException implements Exception {
  /// Creates the exception with a developer-facing [message].
  const new(this.message);

  /// What is wrong, and how to fix it.
  final String message;

  @override
  String toString() => 'AppConfigException: $message';
}

/// Per-flavor configuration, compiled into the app with
/// `--dart-define-from-file=config/<flavor>.json` (S06 plan D6).
///
/// Reading it does no I/O, so it is safe before the first frame (UX-001).
final class AppConfig {
  /// Creates a configuration. Use [AppConfig.fromEnvironment] in the app.
  const new({
    required this.flavor,
    required this.apiBaseUrl,
    required this.sentryDsn,
  });

  /// Reads the defines compiled into this build.
  ///
  /// Throws [AppConfigException] when a key is missing, e.g. when the app was
  /// started without `--dart-define-from-file`. A key that is not defined at
  /// all is reported as missing, not read as an empty string.
  factory fromEnvironment() => AppConfig.fromDefines(
    definedOnly(const {
      flavorKey: bool.hasEnvironment(flavorKey)
          ? String.fromEnvironment(flavorKey)
          : null,
      apiBaseUrlKey: bool.hasEnvironment(apiBaseUrlKey)
          ? String.fromEnvironment(apiBaseUrlKey)
          : null,
      sentryDsnKey: bool.hasEnvironment(sentryDsnKey)
          ? String.fromEnvironment(sentryDsnKey)
          : null,
    }),
  );

  /// Parses the defines in [defines] (the keys of `config/<flavor>.json`).
  ///
  /// [sentryDsnKey] may be empty (error reporting off); the other keys must
  /// be set. The API URL must be `https`, except in the [AppFlavor.dev]
  /// flavor (the local API, S06 plan D6, A8). Throws [AppConfigException]
  /// otherwise.
  factory fromDefines(Map<String, String> defines) {
    String required(String key) {
      final value = defines[key];
      if (value == null || value.isEmpty) {
        throw AppConfigException(
          '$key is ${value == null ? 'missing' : 'empty'}. Run the app with '
          '--dart-define-from-file=config/<flavor>.json (dev, staging, prod).',
        );
      }
      return value;
    }

    final flavorName = required(flavorKey);
    final flavor = AppFlavor.values.asNameMap()[flavorName];
    if (flavor == null) {
      throw AppConfigException(
        '$flavorKey "$flavorName" is not one of '
        '${AppFlavor.values.map((f) => f.name).join(', ')}.',
      );
    }
    final apiBaseUrl = Uri.tryParse(required(apiBaseUrlKey));
    if (apiBaseUrl == null ||
        (!apiBaseUrl.isScheme('http') && !apiBaseUrl.isScheme('https')) ||
        apiBaseUrl.host.isEmpty) {
      throw AppConfigException(
        '$apiBaseUrlKey must be an absolute http(s) URL, '
        'got "${defines[apiBaseUrlKey]}".',
      );
    }
    if (flavor != AppFlavor.dev && !apiBaseUrl.isScheme('https')) {
      throw AppConfigException(
        '$apiBaseUrlKey must be https in the ${flavor.name} flavor '
        '(cleartext http is only for the local API in dev), '
        'got "$apiBaseUrl".',
      );
    }
    final sentryDsn = defines[sentryDsnKey];
    if (sentryDsn == null) {
      throw const AppConfigException(
        '$sentryDsnKey is missing (use "" to turn error reporting off).',
      );
    }
    return AppConfig(
      flavor: flavor,
      apiBaseUrl: apiBaseUrl,
      sentryDsn: sentryDsn,
    );
  }

  /// The defines of [environment] that are set (null = not defined), for
  /// [AppConfig.fromDefines].
  static Map<String, String> definedOnly(Map<String, String?> environment) => {
    for (final MapEntry(:key, :value) in environment.entries) key: ?value,
  };

  /// Define key of [flavor].
  static const flavorKey = 'FB_FLAVOR';

  /// Define key of [apiBaseUrl].
  static const apiBaseUrlKey = 'FB_API_BASE_URL';

  /// Define key of [sentryDsn].
  static const sentryDsnKey = 'FB_SENTRY_DSN';

  /// Every define key the app reads; each `config/*.json` has exactly these.
  static const Set<String> keys = {flavorKey, apiBaseUrlKey, sentryDsnKey};

  /// The build flavor.
  final AppFlavor flavor;

  /// Base URL of the Fitness Buddy API for this flavor.
  final Uri apiBaseUrl;

  /// Sentry DSN; empty turns error reporting off.
  final String sentryDsn;
}

/// The app's [AppConfig]. `main` overrides it with
/// [AppConfig.fromEnvironment]; tests override it with their own value.
@Riverpod(keepAlive: true)
AppConfig appConfig(Ref ref) => throw UnimplementedError(
  'appConfigProvider must be overridden (see lib/main.dart).',
);
