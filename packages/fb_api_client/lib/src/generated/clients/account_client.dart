// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/client_config.dart';
import '../models/current_account.dart';

part 'account_client.g.dart';

@RestApi()
abstract class AccountClient {
  factory AccountClient(Dio dio, {String? baseUrl}) = _AccountClient;

  /// Get the current account.
  ///
  /// Returns the live authenticated account state, including anonymous guest status.
  @GET('/v1/me')
  Future<CurrentAccount> getMe();

  /// Get the client configuration.
  ///
  /// What the app needs to know about the server's expectations: the minimum supported app version, feature flags and client thresholds. The app fetches it in the background and caches it; it is never on the startup path. Never answers 426: it is how an outdated app learns `minimumAppVersion`.
  @GET('/v1/config')
  Future<ClientConfig> getConfig();
}
