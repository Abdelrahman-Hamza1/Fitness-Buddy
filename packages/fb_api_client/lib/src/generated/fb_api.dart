// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';

import 'clients/user_data_client.dart';
import 'clients/account_client.dart';

/// Fitness Buddy API `v0.1.0`.
///
/// The API between the Fitness Buddy app and its backend.
///
/// Contract-first: this document is the source of truth. The Dart client is generated from it and the server is checked against it in CI; when they disagree, the contract wins. Conventions: technical-planning/04-backend.md §4.2 and contracts/README.md.
class FbApi {
  FbApi(Dio dio, {String? baseUrl}) : _dio = dio, _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '0.1.0';

  UserDataClient? _userData;
  AccountClient? _account;

  UserDataClient get userData =>
      _userData ??= UserDataClient(_dio, baseUrl: _baseUrl);

  AccountClient get account =>
      _account ??= AccountClient(_dio, baseUrl: _baseUrl);
}
