import 'package:fb_app_check/fb_app_check.dart';
import 'package:test/test.dart';

import 'helpers.dart';

/// Checks one import [directive] written in the app file [from].
Set<String> _imports(String from, String directive) =>
    found(check(from, '$directive\n'));

void main() {
  const todayScreen = 'lib/features/today/presentation/today_screen.dart';

  group('rule 1 feature-barrel', () {
    test('another feature only through its barrel', () {
      expect(
        _imports(
          todayScreen,
          "import 'package:fb_mobile/features/diary/presentation/x.dart';",
        ),
        {'1 feature-barrel'},
      );
      expect(
        _imports(
          todayScreen,
          "import '../../diary/application/diary_controller.dart';",
        ),
        {'1 feature-barrel'},
      );
      expect(
        _imports(
          'lib/app/router/app_router.dart',
          "import 'package:fb_mobile/features/today/presentation/s.dart';",
        ),
        {'1 feature-barrel'},
        reason: 'app/ imports features through their barrels too',
      );
    });

    test('barrels and the own feature pass', () {
      expect(
        _imports(
          todayScreen,
          "import 'package:fb_mobile/features/diary/diary.dart';",
        ),
        isEmpty,
      );
      expect(
        _imports(todayScreen, "import '../../diary/diary.dart';"),
        isEmpty,
      );
      expect(
        _imports(
          todayScreen,
          "import 'package:fb_mobile/features/today/application/c.dart';",
        ),
        isEmpty,
      );
      expect(
        _imports(
          'lib/features/today/today.dart',
          "export 'presentation/today_screen.dart';",
        ),
        isEmpty,
      );
    });
  });

  group('rule 2 presentation-data', () {
    test('presentation/ never imports data/', () {
      expect(
        _imports(
          todayScreen,
          "import 'package:fb_mobile/features/today/data/today_repo.dart';",
        ),
        {'1 presentation-data'},
      );
      expect(_imports(todayScreen, "import '../data/today_repo.dart';"), {
        '1 presentation-data',
      });
    });

    test('application/ may import data/', () {
      expect(
        _imports(
          'lib/features/today/application/today_controller.dart',
          "import '../data/today_repo.dart';",
        ),
        isEmpty,
      );
    });
  });

  group('rule 3 io-package', () {
    test('I/O packages outside data/ and core/ fail', () {
      for (final package in [
        for (final entry in ioPackages) entry.replaceAll('*', ''),
        // Families by prefix.
        'drift_flutter',
        'sqlite3_flutter_libs',
        'sentry_flutter',
        'sentry_dio',
      ]) {
        expect(
          _imports(todayScreen, "import 'package:$package/$package.dart';"),
          {'1 io-package'},
          reason: package,
        );
      }
      expect(
        _imports(
          'lib/app/bootstrap/app_bootstrap.dart',
          "import 'package:sentry_flutter/sentry_flutter.dart';",
        ),
        {'1 io-package'},
        reason: 'S06 A3: app/bootstrap is not on the allow-list',
      );
    });

    test('the list has the platform plugins; only `*` entries match by '
        'prefix', () {
      for (final package in [
        'http',
        'package_info_plus',
        'path_provider',
        'flutter_secure_storage',
        'connectivity_plus',
        'shared_preferences',
        'fb_api_client',
        'drift_dev',
        'sqlite3_flutter_libs',
        'sentry_logging',
      ]) {
        expect(isIoPackage(package), isTrue, reason: package);
      }
      // `http` and `dio` are exact entries, not families.
      for (final package in [
        'http_parser',
        'dio_web_adapter',
        'go_router',
        'intl',
        'flutter_riverpod',
      ]) {
        expect(isIoPackage(package), isFalse, reason: package);
      }
    });

    test('data/ and core/ may import them', () {
      expect(
        _imports(
          'lib/features/today/data/today_repo.dart',
          "import 'package:drift/drift.dart';",
        ),
        isEmpty,
      );
      expect(
        _imports(
          'lib/core/api/dio_factory.dart',
          "import 'package:dio/dio.dart';",
        ),
        isEmpty,
      );
    });
  });

  group('rule 4 core-boundary', () {
    test('core/ never imports features/ or app/', () {
      expect(
        _imports(
          'lib/core/config/x.dart',
          "import 'package:fb_mobile/features/today/today.dart';",
        ),
        {'1 core-boundary'},
      );
      expect(
        _imports('lib/core/config/x.dart', "import '../../app/app.dart';"),
        {'1 core-boundary'},
      );
    });

    test('core/ may import core/', () {
      expect(
        _imports(
          'lib/core/config/x.dart',
          "import 'package:fb_mobile/core/storage/preferences.dart';",
        ),
        isEmpty,
      );
    });
  });

  group('rule 5 feature-app', () {
    test('features never import app/ (S06 A2)', () {
      expect(
        _imports(
          todayScreen,
          "import 'package:fb_mobile/app/router/app_router.dart';",
        ),
        {'1 feature-app'},
      );
      expect(
        _imports(
          'lib/features/today/application/c.dart',
          "import '../../../app/app.dart';",
        ),
        {'1 feature-app'},
      );
    });

    test('features may import core/navigation', () {
      expect(
        _imports(
          todayScreen,
          "import 'package:fb_mobile/core/navigation/navigation.dart';",
        ),
        isEmpty,
      );
    });
  });

  group('rule 6 presentation-io', () {
    test('presentation, app/shell, app/update never import core/api|db|sync '
        '(S06 A3)', () {
      for (final from in [
        todayScreen,
        'lib/app/shell/app_shell.dart',
        'lib/app/update/update_required_screen.dart',
      ]) {
        for (final folder in ['api', 'db', 'sync']) {
          expect(
            _imports(from, "import 'package:fb_mobile/core/$folder/x.dart';"),
            {'1 presentation-io'},
            reason: '$from -> core/$folder',
          );
        }
      }
    });

    test('the client config repository is in core/api, so the update '
        'screen can only reach it through core/config (S06 A-M2)', () {
      expect(
        _imports(
          'lib/app/update/update_check.dart',
          "import 'package:fb_mobile/core/api/client_config_repository.dart';",
        ),
        {'1 presentation-io'},
      );
      expect(
        _imports(
          'lib/app/update/update_check.dart',
          "import 'package:fb_mobile/core/config/client_config.dart';",
        ),
        isEmpty,
      );
    });

    test('other core folders and data/ may', () {
      expect(
        _imports(
          todayScreen,
          "import 'package:fb_mobile/core/l10n/l10n.dart';",
        ),
        isEmpty,
      );
      expect(
        _imports(
          'lib/features/today/data/today_repo.dart',
          "import 'package:fb_mobile/core/db/database.dart';",
        ),
        isEmpty,
      );
      expect(
        _imports(
          'lib/app/bootstrap/app_bootstrap.dart',
          "import 'package:fb_mobile/core/api/api_providers.dart';",
        ),
        isEmpty,
      );
    });
  });

  group('rule 7 go-router', () {
    test('go_router outside app/router/ fails (S06 D2)', () {
      expect(
        _imports(todayScreen, "import 'package:go_router/go_router.dart';"),
        {'1 go-router'},
      );
      expect(
        _imports(
          'lib/app/shell/app_shell.dart',
          "import 'package:go_router/go_router.dart';",
        ),
        {'1 go-router'},
      );
    });

    test('app/router/ may import it', () {
      expect(
        _imports(
          'lib/app/router/app_router.dart',
          "import 'package:go_router/go_router.dart';",
        ),
        isEmpty,
      );
    });
  });

  group('directives', () {
    test('every URI of a conditional import is checked, on the keyword '
        'line', () {
      const source = '''
// header
import 'stub.dart'
    if (dart.library.io) 'package:dio/dio.dart'
    show Dio;
''';
      expect(found(check(todayScreen, source)), {'2 io-package'});
    });

    test('directives in comments and strings are ignored; dart: passes', () {
      const source = '''
import 'dart:async';
// import 'package:dio/dio.dart';
/* import 'package:go_router/go_router.dart'; */
const s = "import 'package:dio/dio.dart';";
''';
      expect(check(todayScreen, source), isEmpty);
    });

    test('a message names the file, line, rule and the fix', () {
      final violation = check(
        todayScreen,
        "\nimport 'package:fb_mobile/features/diary/data/repo.dart';\n",
      ).first;
      expect(
        '$violation',
        '$todayScreen:2: feature-barrel: imports '
            'lib/features/diary/data/repo.dart; another feature is imported '
            'only through its barrel lib/features/diary/diary.dart',
      );
    });
  });
}
