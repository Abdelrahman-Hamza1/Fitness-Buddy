import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'package_info.g.dart';

/// The installed app's name, version and build number.
///
/// Lazy: read on the first API request or when the update gate needs it,
/// never before the first frame (UX-001). Tests override it.
@Riverpod(keepAlive: true)
Future<PackageInfo> packageInfo(Ref ref) => PackageInfo.fromPlatform();
