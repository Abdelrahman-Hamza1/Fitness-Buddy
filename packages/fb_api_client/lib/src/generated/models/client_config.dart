// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'client_config.freezed.dart';
part 'client_config.g.dart';

/// Server-controlled settings for the app.
@Freezed()
abstract class ClientConfig with _$ClientConfig {
  const factory ClientConfig({
    /// The oldest app version (`MAJOR.MINOR.PATCH`) the server still serves. Older apps are asked to update (426).
    required String minimumAppVersion,

    /// Feature flags by name. A flag the app doesn't know is ignored; a missing flag means off.
    required Map<String, bool> featureFlags,

    /// Numeric client thresholds by name (for example the AI confidence minimum, AI-060). A missing threshold means the app's built-in default.
    required Map<String, double> thresholds,
  }) = _ClientConfig;

  factory ClientConfig.fromJson(Map<String, Object?> json) =>
      _$ClientConfigFromJson(json);
}
