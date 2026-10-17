import 'dart:io';

import 'package:fb_catalog/src/release/id_lock.dart';

/// Runs `git` and returns stdout (trimmed), or `null` when it fails.
String? _git(List<String> args) {
  try {
    final r = Process.runSync('git', args);
    return r.exitCode == 0 ? (r.stdout as String).trim() : null;
  } on ProcessException {
    return null;
  }
}

/// The commit to compare the lock with (same idea as
/// `tools/scripts/contract-breaking.sh`): [flag] / `CATALOG_BASE_REF` when
/// given, else the merge-base with `origin/main`, and on `main` itself the
/// previous commit. `null` (no comparison) outside git or without
/// `origin/main` (shallow clones: CI fetches the full history).
String? resolveBaseRef({String? flag}) {
  final given = flag ?? Platform.environment['CATALOG_BASE_REF'];
  if (given != null && given.isNotEmpty) {
    if (given.startsWith('-')) {
      throw FormatException('the base ref must be a git ref, not "$given"');
    }
    return given;
  }
  final head = _git(['rev-parse', 'HEAD']);
  final base = _git(['merge-base', 'HEAD', 'origin/main']);
  if (head == null || base == null) return null;
  if (base == head) return _git(['rev-parse', '--verify', '-q', 'HEAD^']);
  return base;
}

/// The lock file as of [ref], or `null` when the file didn't exist there.
IdLock? readLockAt(String ref, String path) {
  if (_git(['cat-file', '-e', '$ref:$path']) == null) return null;
  final text = _git(['show', '$ref:$path']);
  return text == null ? null : IdLock.parse(text, source: '$ref:$path');
}

/// The current commit, for the manifest.
String? currentCommit() => _git(['rev-parse', 'HEAD']);
