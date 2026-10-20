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

  /// Permanently delete the current server account.
  ///
  /// Deletes the authenticated guest or registered account and all its user-owned server database records in one transaction. Returns 204 only after commit. A failed transaction leaves the account intact and retryable. After success all old access and refresh credentials are invalid; retrying with them returns 401, including after a lost 204 response. No user identifier or request body is accepted. This operation does not use the generic idempotency response cache. The app obtains confirmation before calling and wipes its local account data after confirmed completion. Existing backups expire within 30 days and cannot be used for direct restoration if they predate a deletion.
  @DELETE('/v1/me')
  Future<void> deleteAccount();

  /// Get the client configuration.
  ///
  /// What the app needs to know about the server's expectations: the minimum supported app version, feature flags and client thresholds. The app fetches it in the background and caches it; it is never on the startup path. Never answers 426: it is how an outdated app learns `minimumAppVersion`.
  @GET('/v1/config')
  Future<ClientConfig> getConfig();
}
