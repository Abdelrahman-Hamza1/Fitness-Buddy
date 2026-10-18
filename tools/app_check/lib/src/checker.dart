import 'package:fb_app_check/src/rules.dart';
import 'package:fb_app_check/src/source_scanner.dart';

/// Packages that do I/O or reach the platform (network, database, device
/// storage, error reporting, device info): only `features/*/data/` and
/// `core/` may import them (rule 3, S06 plan D16 + A3). An entry ending in
/// `*` names a family by prefix (`sentry*` is `sentry`, `sentry_flutter`,
/// `sentry_dio`, …). A step that adds an I/O or platform plugin adds it here.
const Set<String> ioPackages = {
  'connectivity_plus',
  'dio',
  'drift*',
  'fb_api_client',
  'flutter_secure_storage',
  'http',
  'package_info_plus',
  'path_provider',
  'sentry*',
  'shared_preferences',
  'sqlite3*',
};

/// Whether [package] is one of the [ioPackages] (exactly, or by a family
/// prefix).
bool isIoPackage(String package) => ioPackages.any(
  (entry) => entry.endsWith('*')
      ? package.startsWith(entry.substring(0, entry.length - 1))
      : package == entry,
);

/// Named arguments whose string value the user sees or hears (rule 8).
const Set<String> textArguments = {
  'counterText',
  'errorText',
  'helperText',
  'hint',
  'hintText',
  'label',
  'labelText',
  'message',
  'prefixText',
  'semanticLabel',
  'semanticsLabel',
  'subtitle',
  'suffixText',
  'text',
  'title',
  'tooltip',
};

/// Whether [path] (`lib/...`) is generated code, which app_check skips:
/// `*.g.dart`, `*.freezed.dart` and gen-l10n output (`lib/l10n/gen/`). By
/// path only: a hand-written file can't opt out with a header.
bool isGenerated(String path) =>
    path.endsWith('.g.dart') ||
    path.endsWith('.freezed.dart') ||
    path.startsWith('lib/l10n/gen/');

/// The rules an `// app-check: allow <rule-id> <reason>` comment may name:
/// the lexical UI ones. The boundary and write-path rules have no
/// exceptions (TD-052).
const Set<Rule> allowableRules = {Rule.rawString, Rule.directional};

/// Checks one file of the app.
///
/// [path] is relative to the app folder and starts with `lib/` (forward
/// slashes). [packageName] is the app's package (`fb_mobile`), used to
/// resolve `package:fb_mobile/...` imports. Returns the violations sorted by
/// line; none for generated files and non-Dart files.
///
/// With [packageMode] (a UI package such as `fb_design_system`, D17) only the
/// lexical rules run, on every file of `lib/`: `raw-string` and `directional`.
List<Violation> checkFile({
  required String path,
  required String source,
  required String packageName,
  bool packageMode = false,
}) {
  if (!path.endsWith('.dart') || isGenerated(path)) return const [];
  final scanned = ScannedSource.scan(source);
  final file = _AppPath(path, package: packageMode);
  final directives = packageMode
      ? const <(int, String)>[]
      : _directiveUris(scanned).toList();
  final found = [
    for (final (line, uri) in directives)
      ..._checkImport(file, uri, line, packageName),
    if (file.mayCallDriftWrites &&
        directives.any((d) => _reachesDatabase(file.path, d.$2, packageName)))
      ..._checkDriftWrites(file, scanned),
    if (file.showsText) ..._checkRawStrings(file, scanned),
    ..._checkDirectional(file, scanned),
  ];
  final allows = _allows(scanned);

  final result = <Violation>[];
  final seen = <String>{};
  for (final violation in found) {
    if (allows[violation.line] case _Allow(:final rule?)
        when rule == violation.rule) {
      continue;
    }
    if (seen.add('${violation.line} ${violation.rule.id}')) {
      result.add(violation);
    }
  }
  for (final MapEntry(key: line, value: allow) in allows.entries) {
    if (allow.problem case final problem?) {
      result.add(
        Violation(
          path: path,
          line: line,
          rule: Rule.invalidAllow,
          message: problem,
        ),
      );
    }
  }
  return result..sort();
}

/// The number of valid `// app-check: allow <rule-id> <reason>` comments in
/// the app file [path] (0 for generated and non-Dart files).
int allowCount({required String path, required String source}) {
  if (!path.endsWith('.dart') || isGenerated(path)) return 0;
  return _allows(ScannedSource.scan(source)).values
      .where((a) => a.problem == null)
      .length;
}

final RegExp _allowComment = RegExp(r'//\s*app-check:\s*allow\b(.*)$');

/// One `// app-check: allow` comment: the rule it silences, or why it is
/// invalid (then it silences nothing).
final class _Allow {
  const new({this.rule, this.problem});

  final Rule? rule;
  final String? problem;
}

/// The `// app-check: allow` comments of [scanned], by 1-based line.
Map<int, _Allow> _allows(ScannedSource scanned) {
  const usage =
      'use `// app-check: allow <rule-id> <reason>`, where <rule-id> is '
      'raw-string or directional';
  final allowable = {for (final rule in allowableRules) rule.id: rule};
  final boundaries = {
    for (final rule in Rule.values)
      if (!allowable.containsKey(rule.id) && rule != Rule.invalidAllow) rule.id,
  };
  return {
    for (var line = 1; line <= scanned.lineCount; line++)
      if (_allowComment.firstMatch(scanned.lineText(line)) case final match?)
        line: switch (match[1]!.trim().split(RegExp(r'\s+'))) {
          [] || [''] => const _Allow(
            problem:
                '`// app-check: allow` needs a rule id and a reason; $usage',
          ),
          [final id, ...] when boundaries.contains(id) => _Allow(
            problem:
                "`$id` can't be allowed: boundary and write-path rules have "
                'no exceptions; fix the code',
          ),
          [final id, ...] when !allowable.containsKey(id) => _Allow(
            problem: 'unknown rule `$id` in `// app-check: allow`; $usage',
          ),
          [final id] => _Allow(
            problem: '`// app-check: allow $id` needs a reason; $usage',
          ),
          [final id, ...] => _Allow(rule: allowable[id]),
        },
  };
}

/// Where a file sits in the app's folder layout (`03-architecture.md` §3.2).
final class _AppPath {
  new(this.path, {this.package = false})
    : _feature = _featurePath.firstMatch(path);

  /// A UI package checked with `--package`: every file shows text.
  final bool package;

  static final RegExp _featurePath = RegExp(r'^lib/features/([^/]+)/(.+)$');

  final String path;
  final RegExpMatch? _feature;

  /// The feature folder name, or null outside `lib/features/`.
  String? get feature => _feature?.group(1);

  /// The path inside the feature folder (`presentation/x.dart`).
  String? get inFeature => _feature?.group(2);

  bool get isBarrel => inFeature != null && inFeature == '$feature.dart';
  bool get isPresentation => inFeature?.startsWith('presentation/') ?? false;
  bool get isApplication => inFeature?.startsWith('application/') ?? false;
  bool get isData => inFeature?.startsWith('data/') ?? false;
  bool get isCore => path.startsWith('lib/core/');
  bool get isApp => path.startsWith('lib/app/');
  bool get isMain => path == 'lib/main.dart';

  /// UI code that shows text: presentation, `app/`, `main.dart` (rule 8).
  bool get showsText => package || isPresentation || isApp || isMain;

  /// Presentation code that must not reach HTTP, the database or sync
  /// through `core/` (rule 6, S06 A3).
  bool get isPresentationLayer =>
      isPresentation ||
      path.startsWith('lib/app/shell/') ||
      path.startsWith('lib/app/update/');

  /// `core/db/` (the database, its tables and the write guard).
  bool get isCoreDb => path.startsWith('lib/core/db/');

  /// The row writer, `core/db/write/` (rule 10).
  bool get isDbWrite => path.startsWith('lib/core/db/write/');

  /// The single writer, the only importer of [isDbWrite] code (rule 10).
  bool get isApplier => path == applierPath;

  /// `core/changes/` (rule 13).
  bool get isCoreChanges => path.startsWith('lib/core/changes/');

  /// Where drift's write calls are allowed (rule 11): the database layer
  /// (A34's sync writes go there too) and the applier's transaction.
  bool get mayCallDriftWrites => !isCoreDb && !isApplier;

  /// `core/api`, `core/db` or `core/sync`.
  bool get isCoreIo =>
      path.startsWith('lib/core/api/') ||
      path.startsWith('lib/core/db/') ||
      path.startsWith('lib/core/sync/');
}

final RegExp _directive = RegExp(
  r'^[ \t]*(?:import|export)\b',
  multiLine: true,
);
final RegExp _packageUri = RegExp('^package:([^/]+)/(.*)');

/// Every URI of every `import` / `export` directive of [scanned], with its
/// line: the URI, then any conditional URIs (`if (dart.library.io) '…'`).
Iterable<(int, String)> _directiveUris(ScannedSource scanned) sync* {
  for (final directive in _directive.allMatches(scanned.code)) {
    final semicolon = scanned.code.indexOf(';', directive.end);
    final end = semicolon == -1 ? scanned.code.length : semicolon;
    final line = scanned.lineOf(directive.start);
    for (final literal in scanned.literals.values) {
      if (literal.start > directive.start && literal.start < end) {
        yield (line, literal.staticText.trim());
      }
    }
  }
}

Iterable<Violation> _checkImport(
  _AppPath from,
  String uri,
  int line,
  String packageName,
) sync* {
  Violation v(Rule rule, String message) =>
      Violation(path: from.path, line: line, rule: rule, message: message);

  final package = _packageUri.firstMatch(uri);
  final external = package != null && package.group(1) != packageName
      ? package.group(1)
      : null;
  if (external != null) {
    if (isIoPackage(external) && !from.isData && !from.isCore) {
      yield v(
        Rule.ioPackage,
        'imports package:$external, which is only allowed in '
        'features/*/data/ and core/; reach it through a repository',
      );
    }
    if (opensConnection(uri) && !from.isCoreDb) {
      yield v(
        Rule.dbWriteCall,
        'imports $uri, which opens database connections, outside core/db/; '
        'an unguarded connection bypasses the write guard: use the '
        'AppDatabase from core/db/ and write with a change set',
      );
    }
    if (external == 'go_router' && !from.path.startsWith('lib/app/router/')) {
      yield v(
        Rule.goRouter,
        'imports package:go_router, which is only allowed in app/router/; '
        'navigate with AppNavigator and AppRoute (core/navigation)',
      );
    }
    return;
  }

  final resolved = _appTarget(from.path, uri, packageName);
  if (resolved == null) return; // dart:, data:, or outside the app.
  final target = _AppPath(resolved);

  if (target.feature != null &&
      target.feature != from.feature &&
      !target.isBarrel &&
      !from.isCore) {
    yield v(
      Rule.featureBarrel,
      'imports $resolved; another feature is imported only through its '
      'barrel lib/features/${target.feature}/${target.feature}.dart',
    );
  }
  if (from.isPresentation && target.isData) {
    yield v(
      Rule.presentationData,
      'presentation/ imports $resolved from data/; go through '
      'application/ (view models, providers)',
    );
  }
  if (from.isCore &&
      (target.feature != null || target.isApp || target.isMain)) {
    yield v(
      Rule.coreBoundary,
      'core/ imports $resolved; core/ never depends on features/ or app/',
    );
  }
  if (from.feature != null && (target.isApp || target.isMain)) {
    yield v(
      Rule.featureApp,
      'a feature imports $resolved; features never import app/ (navigate '
      'through AppNavigator in core/navigation)',
    );
  }
  if (target.isDbWrite && !from.isDbWrite && !from.isApplier) {
    yield v(
      Rule.dbWriteApi,
      'imports $resolved; core/db/write/ is the row writer, imported only '
      'by $applierPath; write user data with a change set '
      '(ChangeSetApplier.apply)',
    );
  }
  if (resolved == writeGuardPath && !from.isCoreDb) {
    yield v(
      Rule.dbWriteCall,
      'imports $resolved (runAuthorizedWrite) outside core/db/; only the '
      'single writer opens a write scope: write user data with a change set',
    );
  }
  if (resolved == seedRowsPath && !from.isCoreDb) {
    yield v(
      Rule.dbWriteCall,
      'imports $resolved (seedRows) outside core/db/; seeds are written by '
      'migrations only: write user data with a change set',
    );
  }
  if (from.isApplication && target.isCoreDb) {
    yield v(
      Rule.applicationDb,
      'application/ imports $resolved from core/db/; read and write through '
      "the feature's data/ repositories",
    );
  }
  if (from.isPresentationLayer && target.isCoreChanges) {
    yield v(
      Rule.presentationChanges,
      'presentation code imports $resolved from core/changes/; change data '
      'through application/ commands',
    );
  }
  if (from.isPresentationLayer && target.isCoreIo) {
    yield v(
      Rule.presentationIo,
      'presentation code imports $resolved; core/api, core/db and core/sync '
      'are reached only through data/ or application/ providers',
    );
  }
}

/// The single writer (A01 D12): the only file that imports `core/db/write/`.
const String applierPath = 'lib/core/changes/change_set_applier.dart';

/// The write guard (A01 D11): its `runAuthorizedWrite` opens a write scope.
const String writeGuardPath = 'lib/core/db/write_guard.dart';

/// The seed helper (A01 D7): writes rows outside the applier, for
/// migrations.
const String seedRowsPath = 'lib/core/db/seed_rows.dart';

/// The app file (`lib/...`) [uri] names when imported from [from], or null
/// for other packages, `dart:` and paths outside the app.
String? _appTarget(String from, String uri, String packageName) {
  final package = _packageUri.firstMatch(uri);
  if (package == null) return _resolveRelative(from, uri);
  return package.group(1) == packageName ? 'lib/${package.group(2)}' : null;
}

/// The libraries that open or reach a raw database connection (rule 11):
/// sqlite3 (`sqlite3.open`, `execute`), drift's backends (`NativeDatabase`,
/// `DriftIsolate`, remote and web executors) and drift's connection
/// packages. Only `core/db/` (`connection.dart`) may import them, so a
/// repository can't open a connection the write guard doesn't wrap. An
/// entry ending in `/` or `*` matches by prefix.
const Set<String> connectionLibraries = {
  'package:drift/backends.dart',
  'package:drift/isolate.dart',
  'package:drift/native.dart',
  'package:drift/remote.dart',
  'package:drift/wasm.dart',
  'package:drift/web.dart',
  'package:drift/web/',
  'package:drift_flutter/',
  'package:drift_sqflite/',
  'package:sqlite3*',
};

/// Whether [uri] is one of the [connectionLibraries].
bool opensConnection(String uri) => connectionLibraries.any(
  (entry) => entry.endsWith('/') || entry.endsWith('*')
      ? uri.startsWith(entry.replaceAll('*', ''))
      : uri == entry,
);

/// Whether importing [uri] from [from] gives drift's write calls (rule 11):
/// any `package:drift/` library, or anything under `core/db/` (the
/// database, which re-exports drift's API).
bool _reachesDatabase(String from, String uri, String packageName) =>
    uri.startsWith('package:drift/') ||
    uri.startsWith('package:sqlite3') ||
    (_appTarget(from, uri, packageName)?.startsWith('lib/core/db/') ?? false);

/// The drift calls that write (rule 11, A01 D12): statements on the
/// database (`into(`, `update(`, `delete(`, `batch(`, `transaction(`,
/// `custom…(`), the table shortcuts (`insertOne(`, `replace(`, …), the raw
/// executor (`runInsert(`, `runCustom(`, …) and sqlite3's `execute(`.
const Set<String> driftWriteCalls = {
  'batch',
  'customInsert',
  'customStatement',
  'customUpdate',
  'customWriteReturning',
  'delete',
  'deleteAll',
  'deleteWhere',
  'execute',
  'insert',
  'insertAll',
  'insertOnConflictUpdate',
  'insertOne',
  'insertReturning',
  'insertReturningOrNull',
  'into',
  'replace',
  'runBatched',
  'runCustom',
  'runDelete',
  'runInsert',
  'runUpdate',
  'transaction',
  'update',
};

final RegExp _driftWriteCall = RegExp(
  '(?<![\\w\$])(${driftWriteCalls.join('|')})\\s*(?:<[^()]*>\\s*)?\\(',
);

final RegExp _customSelect = RegExp(r'(?<![\w$])customSelect\s*\(');
final RegExp _writeSql = RegExp(
  r'^\s*(?:INSERT|UPDATE|DELETE|REPLACE)\b|\bRETURNING\b'
  r'|^\s*WITH\b[\s\S]*\b(?:INSERT|UPDATE|DELETE|REPLACE)\b',
  caseSensitive: false,
);

Iterable<Violation> _checkDriftWrites(
  _AppPath file,
  ScannedSource scanned,
) sync* {
  for (final call in _driftWriteCall.allMatches(scanned.code)) {
    yield Violation(
      path: file.path,
      line: scanned.lineOf(call.start),
      rule: Rule.dbWriteCall,
      message:
          '`${call[1]}(` writes through drift outside core/db/; only the '
          'ChangeSetApplier writes user data: return RowOps from an op '
          'handler, or apply a change set',
    );
  }
  // A write run as a query: its SQL is the first argument's literals.
  for (final call in _customSelect.allMatches(scanned.code)) {
    final sql = _argumentLiterals(
      scanned,
      call.end,
      wholeList: false,
    ).map((l) => l.staticText).join();
    if (_writeSql.hasMatch(sql)) {
      yield Violation(
        path: file.path,
        line: scanned.lineOf(call.start),
        rule: Rule.dbWriteCall,
        message:
            '`customSelect(` runs a write (INSERT/UPDATE/DELETE/REPLACE or '
            'RETURNING) outside core/db/; only the ChangeSetApplier writes '
            'user data: return RowOps from an op handler, or apply a change '
            'set',
      );
    }
  }
}

/// Resolves a relative [uri] against [from]'s folder: `lib/...`, or null for
/// `dart:` URIs, other schemes and paths that leave the app.
String? _resolveRelative(String from, String uri) {
  if (uri.contains(':')) return null;
  final parts = from.split('/')..removeLast();
  for (final segment in uri.split('/')) {
    if (segment == '..') {
      if (parts.isEmpty) return null;
      parts.removeLast();
    } else if (segment != '.' && segment.isNotEmpty) {
      parts.add(segment);
    }
  }
  final path = parts.join('/');
  return path.startsWith('lib/') ? path : null;
}

final RegExp _textWidget = RegExp(r'\b(?:Text|SelectableText)(?:\.rich)?\s*\(');
final RegExp _textArgument = RegExp(
  '(?<=[(,]\\s*)\\b(${textArguments.join('|')})\\s*:',
);
final RegExp _namedArgument = RegExp(r'\s*[A-Za-z_$][\w$]*\s*:(?!:)');
final RegExp _letter = RegExp(r'\p{L}', unicode: true);

const String _appArbHint = '(lib/l10n/app_en.arb, context.l10n.<key>)';
const String _packageArbHint =
    '(lib/l10n/fb_ds_en.arb, FbLocalizations) or a parameter';

Iterable<Violation> _checkRawStrings(
  _AppPath file,
  ScannedSource scanned,
) sync* {
  Iterable<Violation> report(Iterable<StringLiteral> literals, String where) =>
      literals
          .where((l) => _letter.hasMatch(l.staticText))
          .map(
            (l) => Violation(
              path: file.path,
              line: scanned.lineOf(l.start),
              rule: Rule.rawString,
              message:
                  'raw string ${_snippet(scanned.source, l)} in $where; '
                  'user-facing text comes from the ARB file '
                  '${file.package ? _packageArbHint : _appArbHint}',
            ),
          );

  for (final widget in _textWidget.allMatches(scanned.code)) {
    final name = widget[0]!.replaceAll(RegExp(r'\s'), '');
    yield* report(
      _argumentLiterals(scanned, widget.end, wholeList: true),
      '$name…)',
    );
  }
  for (final argument in _textArgument.allMatches(scanned.code)) {
    yield* report(
      _argumentLiterals(scanned, argument.end, wholeList: false),
      '${argument[1]}:',
    );
  }
}

/// The string literals at the top level of an argument starting at [from]:
/// not inside a nested call, list or closure (`DateFormat('y')`,
/// `l10n.greet('x')` are not user-facing text).
///
/// With [wholeList], walks a whole argument list (from just after `(`),
/// skipping named arguments; otherwise stops at the end of one argument.
Iterable<StringLiteral> _argumentLiterals(
  ScannedSource scanned,
  int from, {
  required bool wholeList,
}) sync* {
  final code = scanned.code;
  var depth = 0;
  var skipping = wholeList && _startsNamedArgument(code, from);
  var i = from;
  while (i < code.length) {
    final literal = scanned.literals[i];
    if (literal != null) {
      if (depth == 0 && !skipping) yield literal;
      i = literal.end;
      continue;
    }
    final c = code[i];
    if (c == '(' || c == '[' || c == '{') {
      depth++;
    } else if (c == ')' || c == ']' || c == '}') {
      if (depth == 0) return;
      depth--;
    } else if (depth == 0 && c == ';') {
      return;
    } else if (depth == 0 && c == ',') {
      if (!wholeList) return;
      skipping = _startsNamedArgument(code, i + 1);
    }
    i++;
  }
}

bool _startsNamedArgument(String code, int at) =>
    _namedArgument.matchAsPrefix(code, at) != null;

String _snippet(String source, StringLiteral literal) {
  final text = source.substring(literal.start, literal.end).split('\n').first;
  return text.length <= 40 ? text : '${text.substring(0, 37)}...';
}

/// Physical left/right APIs and what to use instead (rule 9).
final List<(RegExp, String Function(Match))> _physicalLayout = [
  (
    RegExp(r'(?<=[(,]\s*)\b(left|right)\s*:'),
    (m) =>
        '`${m[1]}:` is a physical side; use `${_side(m[1]!)}:` '
        '(EdgeInsetsDirectional.only, PositionedDirectional, '
        'BorderDirectional, …)',
  ),
  (
    RegExp(r'(?<=[(,]\s*)\b((?:top|bottom)(?:Left|Right))\s*:'),
    (m) =>
        '`${m[1]}:` is a physical corner; use `${_side(m[1]!)}:` '
        '(BorderRadiusDirectional.only)',
  ),
  (
    RegExp(r'\bEdgeInsets\.fromLTRB\b'),
    (m) =>
        '`EdgeInsets.fromLTRB` is physical; use '
        '`EdgeInsetsDirectional.fromSTEB`',
  ),
  (
    RegExp(
      r'\b(Alignment|FractionalOffset)\.'
      r'((?:top|center|bottom)(?:Left|Right))\b',
    ),
    (m) =>
        '`${m[0]}` is physical; use '
        '`AlignmentDirectional.${_side(m[2]!)}`',
  ),
  (
    RegExp(r'\bTextAlign\.(left|right)\b'),
    (m) => '`${m[0]}` is physical; use `TextAlign.${_side(m[1]!)}`',
  ),
  (
    RegExp(r'\bIcons\.\w*?_(?:left|right)(?![A-Za-z0-9])\w*'),
    (m) =>
        '`${m[0]}` names a physical side; use a direction-neutral icon '
        '(Icons.arrow_back / arrow_forward, Icons.adaptive.*), or if this '
        'icon mirrors in RTL add `// app-check: allow directional <reason>`',
  ),
];

/// left → start, right → end, also inside names (topLeft → topStart).
String _side(String physical) => physical
    .replaceAll('left', 'start')
    .replaceAll('right', 'end')
    .replaceAll('Left', 'Start')
    .replaceAll('Right', 'End');

Iterable<Violation> _checkDirectional(
  _AppPath file,
  ScannedSource scanned,
) sync* {
  for (final (pattern, message) in _physicalLayout) {
    for (final match in pattern.allMatches(scanned.code)) {
      yield Violation(
        path: file.path,
        line: scanned.lineOf(match.start),
        rule: Rule.directional,
        message: message(match),
      );
    }
  }
}
