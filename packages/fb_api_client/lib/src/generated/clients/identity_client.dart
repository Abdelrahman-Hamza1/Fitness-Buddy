// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/auth_tokens.dart';
import '../models/email_challenge.dart';
import '../models/email_link_start_request.dart';
import '../models/email_start_request.dart';
import '../models/email_verify_request.dart';
import '../models/google_sign_in_request.dart';
import '../models/json_web_key_set.dart';
import '../models/link_identity_request.dart';
import '../models/refresh_request.dart';

part 'identity_client.g.dart';

@RestApi()
abstract class IdentityClient {
  factory IdentityClient(Dio dio, {String? baseUrl}) = _IdentityClient;

  /// createAnonymous.
  ///
  /// Token responses are never cached or replayed. Email delivery is a private laptop adapter until B14.
  @POST('/v1/auth/anonymous')
  Future<AuthTokens> createAnonymous();

  /// signInGoogle.
  ///
  /// Token responses are never cached or replayed. Email delivery is a private laptop adapter until B14.
  @POST('/v1/auth/google')
  Future<AuthTokens> signInGoogle({@Body() required GoogleSignInRequest body});

  /// startEmailSignIn.
  ///
  /// Token responses are never cached or replayed. Email delivery is a private laptop adapter until B14.
  @POST('/v1/auth/email/start')
  Future<EmailChallenge> startEmailSignIn({
    @Body() required EmailStartRequest body,
  });

  /// verifyEmailSignIn.
  ///
  /// Token responses are never cached or replayed. Email delivery is a private laptop adapter until B14.
  @POST('/v1/auth/email/verify')
  Future<AuthTokens> verifyEmailSignIn({
    @Body() required EmailVerifyRequest body,
  });

  /// refreshSession.
  ///
  /// Token responses are never cached or replayed. Email delivery is a private laptop adapter until B14.
  @POST('/v1/auth/refresh')
  Future<AuthTokens> refreshSession({@Body() required RefreshRequest body});

  /// logoutSession.
  ///
  /// Token responses are never cached or replayed. Email delivery is a private laptop adapter until B14.
  @POST('/v1/auth/logout')
  Future<void> logoutSession();

  /// linkIdentity.
  ///
  /// Token responses are never cached or replayed. Email delivery is a private laptop adapter until B14.
  @POST('/v1/auth/link/{provider}')
  Future<AuthTokens> linkIdentity({
    @Path('provider') required String provider,
    @Body() required LinkIdentityRequest body,
  });

  /// startEmailLink.
  ///
  /// Sends the guest-upgrade email code. Requires the live guest bearer (401 when missing or stale, 403 for a registered account), so the app never gets a silent no-code challenge. Email delivery is a private laptop adapter until B14.
  @POST('/v1/auth/link/email/start')
  Future<EmailChallenge> startEmailLink({
    @Body() required EmailLinkStartRequest body,
  });

  /// Get public token verification keys.
  ///
  /// Only public ES256 verification material is returned; private signing keys are never exposed.
  @GET('/.well-known/jwks.json')
  Future<JsonWebKeySet> getJwks();
}
