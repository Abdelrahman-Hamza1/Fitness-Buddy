import 'package:fb_app_check/fb_app_check.dart';
import 'package:test/test.dart';

import 'helpers.dart';

/// Checks one import [directive] written in the app file [from].
Set<String> _imports(String from, String directive) =>
    found(check(from, '$directive\n'));

void main() {
  const repository = 'lib/features/diary/data/diary_repository.dart';

  group('rule 10 db-write-api', () {
    test('the bad fixture: core/db/write imported from features/x/data '
        'fails', () {
      final source = fixture('db_write_bad.txt');
      expect(found(check(repository, source)), expectedMarks(source));
      expect(
        expectedMarks(source).where((m) => m.endsWith(' db-write-api')),
        hasLength(2),
      );
    });

    test('only the applier and core/db/write itself import it', () {
      const directive =
          "import 'package:fb_mobile/core/db/write/row_writer.dart';";
      for (final path in [
        'lib/core/changes/op_handler.dart',
        'lib/core/db/app_database.dart',
        'lib/core/sync/remote_apply.dart',
        'lib/app/app_scope.dart',
        'lib/features/diary/application/c.dart',
      ]) {
        expect(_imports(path, directive), {
          '1 db-write-api',
          // application/ also may not import core/db/ at all.
          if (path.contains('/application/')) '1 application-db',
        }, reason: path);
      }
      expect(
        _imports('lib/core/changes/change_set_applier.dart', directive),
        isEmpty,
      );
      expect(
        _imports(
          'lib/core/db/write/row_writer.dart',
          "import 'snapshot.dart';",
        ),
        isEmpty,
      );
    });
  });

  group('rule 11 db-write-call', () {
    test('the bad fixture: every drift write call in features/x/data and '
        'the write guard import fail', () {
      final source = fixture('db_write_bad.txt');
      expect(found(check(repository, source)), expectedMarks(source));
      expect(
        expectedMarks(source).where((m) => m.endsWith(' db-write-call')),
        hasLength(26),
      );
    });

    test('the core/db fixture: a file that imports only core/db/ is scanned '
        'too, customSelect running a write fails, seed_rows is restricted', () {
      final source = fixture('db_write_core_db_bad.txt');
      expect(found(check(repository, source)), expectedMarks(source));
      expect(expectedMarks(source), hasLength(10));
    });

    test('a relative import of core/db/ counts like a package one', () {
      const source =
          "import '../../../core/db/app_database.dart';\n"
          'void f(AppDatabase db) => db.into(db.settingsKv);\n';
      expect(found(check(repository, source)), {'2 db-write-call'});
    });

    test('reads, planned RowOps, comments and strings pass', () {
      expect(check(repository, fixture('db_write_ok.txt')), isEmpty);
    });

    test('Map.update in a file without a drift import passes', () {
      const source =
          "import 'package:fb_domain/fb_domain.dart';\n"
          "void f(Map<String, int> m) => m.update('a', (n) => n + 1);\n";
      expect(check(repository, source), isEmpty);
      expect(
        found(
          check(
            repository,
            "import 'package:drift/extensions/json1.dart';\n$source",
          ),
        ),
        {'3 db-write-call'},
        reason: 'any package:drift/ library counts',
      );
    });

    test('core/db and the applier may call them; core/sync may not', () {
      const source =
          "import 'package:drift/drift.dart';\n"
          'Future<void> f(GeneratedDatabase db) =>\n'
          '    db.transaction(() async {});\n';
      for (final path in [
        'lib/core/db/seed_rows.dart',
        'lib/core/db/write/row_writer.dart',
        'lib/core/db/sync_store.dart',
        'lib/core/changes/change_set_applier.dart',
      ]) {
        expect(check(path, source), isEmpty, reason: path);
      }
      for (final path in [
        'lib/core/sync/remote_apply.dart',
        'lib/core/changes/op_handler.dart',
        'lib/core/settings/settings_store.dart',
        'lib/core/undo/undo_stack.dart',
      ]) {
        expect(found(check(path, source)), {'3 db-write-call'}, reason: path);
      }
    });

    test('libraries that open a connection are imported only inside '
        'core/db', () {
      for (final uri in [
        'package:drift/native.dart',
        'package:drift/isolate.dart',
        'package:drift/remote.dart',
        'package:drift/backends.dart',
        'package:drift/wasm.dart',
        'package:drift/web.dart',
        'package:drift/web/workers.dart',
        'package:drift_flutter/drift_flutter.dart',
        'package:sqlite3/sqlite3.dart',
        'package:sqlite3/common.dart',
      ]) {
        final directive = "import '$uri';";
        expect(_imports('lib/core/db/connection.dart', directive), isEmpty);
        expect(
          _imports('lib/core/db/write/row_writer.dart', directive),
          isEmpty,
        );
        for (final path in [
          repository,
          'lib/core/sync/remote_apply.dart',
          'lib/core/settings/settings_store.dart',
        ]) {
          expect(_imports(path, directive), {
            '1 db-write-call',
          }, reason: '$path $uri');
        }
      }
      for (final uri in [
        'package:drift/drift.dart',
        'package:drift/extensions/json1.dart',
      ]) {
        expect(_imports(repository, "import '$uri';"), isEmpty, reason: uri);
      }
    });

    test('the raw executor and sqlite3 execute count as writes', () {
      for (final call in [
        'runInsert',
        'runUpdate',
        'runDelete',
        'runCustom',
        'runBatched',
        'execute',
      ]) {
        final source =
            "import 'package:drift/drift.dart';\n"
            'void f(QueryExecutor e) => e.$call(sql, []);\n';
        expect(found(check(repository, source)), {
          '2 db-write-call',
        }, reason: call);
        expect(
          check('lib/core/db/write_guard.dart', source),
          isEmpty,
          reason: call,
        );
      }
    });

    test('the write guard is imported only inside core/db', () {
      const directive = "import 'package:fb_mobile/core/db/write_guard.dart';";
      expect(_imports('lib/core/db/app_database.dart', directive), isEmpty);
      expect(_imports('lib/core/db/write/row_writer.dart', directive), isEmpty);
      expect(
        _imports('lib/core/db/write/x.dart', "import '../write_guard.dart';"),
        isEmpty,
      );
      for (final path in [
        'lib/core/changes/change_set_applier.dart',
        'lib/core/settings/settings_store.dart',
        'lib/core/sync/remote_apply.dart',
        'lib/features/diary/data/r.dart',
      ]) {
        expect(_imports(path, directive), {'1 db-write-call'}, reason: path);
      }
    });

    test('seed_rows is imported only inside core/db', () {
      const directive = "import 'package:fb_mobile/core/db/seed_rows.dart';";
      expect(
        _imports('lib/core/db/migrations/from_2_to_3.dart', directive),
        isEmpty,
      );
      expect(
        _imports(
          'lib/core/db/migrations/x.dart',
          "import '../seed_rows.dart';",
        ),
        isEmpty,
      );
      for (final path in [
        'lib/core/changes/change_set_applier.dart',
        'lib/core/sync/remote_apply.dart',
        'lib/features/diary/data/r.dart',
      ]) {
        expect(_imports(path, directive), {'1 db-write-call'}, reason: path);
      }
    });

    test('messages name the call and the fix', () {
      final message = check(
        repository,
        "import 'package:drift/drift.dart';\nvoid f() => db.into(t);\n",
      ).single.message;
      expect(message, contains('`into(`'));
      expect(message, contains('ChangeSetApplier'));
    });
  });

  group('rule 12 application-db', () {
    test('the bad fixture: application/ importing core/db fails', () {
      final source = fixture('application_db_bad.txt');
      expect(
        found(
          check('lib/features/diary/application/diary_controller.dart', source),
        ),
        expectedMarks(source),
      );
      expect(expectedMarks(source), hasLength(3));
    });

    test('data/ and core/ may import core/db', () {
      const directive = "import 'package:fb_mobile/core/db/app_database.dart';";
      expect(_imports(repository, directive), isEmpty);
      expect(
        _imports('lib/core/settings/settings_store.dart', directive),
        isEmpty,
      );
    });
  });

  group('rule 13 presentation-changes', () {
    test('the bad fixture: presentation importing core/changes fails', () {
      final source = fixture('presentation_changes_bad.txt');
      expect(
        found(
          check('lib/features/diary/presentation/diary_screen.dart', source),
        ),
        expectedMarks(source),
      );
      expect(expectedMarks(source), hasLength(3));
    });

    test('app/shell and app/update count as presentation; application/ '
        'may', () {
      const directive =
          "import 'package:fb_mobile/core/changes/change_set_applier.dart';";
      expect(_imports('lib/app/shell/s.dart', directive), {
        '1 presentation-changes',
      });
      expect(_imports('lib/app/update/u.dart', directive), {
        '1 presentation-changes',
      });
      expect(
        _imports('lib/features/diary/application/c.dart', directive),
        isEmpty,
      );
    });
  });

  test('an allow comment on these rules is invalid-allow and silences '
      'nothing', () {
    const source =
        "import 'package:drift/drift.dart';\n"
        "import 'package:fb_mobile/core/db/write/row_writer.dart'; "
        '// app-check: allow db-write-api spike\n'
        'void f() => db.into(t); // app-check: allow db-write-call spike\n';
    expect(found(check(repository, source)), {
      '2 db-write-api',
      '2 invalid-allow',
      '3 db-write-call',
      '3 invalid-allow',
    });
    for (final (path, line, rule) in [
      (
        'lib/features/diary/application/c.dart',
        "import 'package:fb_mobile/core/db/app_database.dart';",
        'application-db',
      ),
      (
        'lib/features/diary/presentation/s.dart',
        "import 'package:fb_mobile/core/changes/row_ops.dart';",
        'presentation-changes',
      ),
    ]) {
      expect(found(check(path, '$line // app-check: allow $rule spike\n')), {
        '1 $rule',
        '1 invalid-allow',
      }, reason: rule);
    }
  });

  test('rule ids are unique', () {
    final ids = Rule.values.map((r) => r.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
  });
}
