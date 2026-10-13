// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';

import 'clients/buddy_client.dart';

/// Fitness Buddy generator fixture `v0.0.0`
class FixtureApi {
  FixtureApi(Dio dio, {String? baseUrl}) : _dio = dio, _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '0.0.0';

  BuddyClient? _buddy;

  BuddyClient get buddy => _buddy ??= BuddyClient(_dio, baseUrl: _baseUrl);
}
