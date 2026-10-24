import 'package:fb_mobile/core/catalog/catalog_providers.dart';
import 'package:fb_mobile/core/config/app_config.dart';
import 'package:fb_mobile/core/config/package_info.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'about_info.g.dart';

/// Only the public credit fields needed by About (never notes or licences).
final class AboutCredit {
  /// Creates a source credit.
  const new({required this.name, required this.credit});

  /// Source name.
  final String name;

  /// Required credit line.
  final String credit;
}

/// Version and offline attribution, without display text.
final class AboutInfo {
  /// Creates About data.
  const new({
    required this.version,
    required this.build,
    required this.flavor,
    required this.packVersion,
    required this.activeCredits,
  });

  /// App semantic version.
  final String version;

  /// App build number.
  final String build;

  /// Compiled flavor.
  final AppFlavor flavor;

  /// Null when the pack is unreadable or absent.
  final int? packVersion;

  /// Null when unavailable; only active source credits otherwise.
  final List<AboutCredit>? activeCredits;
}

/// Lazy package and pack reads; absent credits preserve the rest of About.
@riverpod
Future<AboutInfo> aboutInfo(Ref ref) async {
  final flavor = ref.watch(appConfigProvider).flavor;
  final catalog = ref.watch(offlineCatalogProvider);
  final package = await ref.watch(packageInfoProvider.future);
  final info = await catalog.info();
  return AboutInfo(
    version: package.version,
    build: package.buildNumber,
    flavor: flavor,
    packVersion: info?.packVersion,
    activeCredits: info == null
        ? null
        : List.unmodifiable([
            for (final source in info.attribution)
              if (source.status == 'active')
                AboutCredit(name: source.name, credit: source.credit),
          ]),
  );
}
