import 'dart:convert';
import 'dart:io';

/// A bounded private pipe. Even fixture/decoder/timeout failures reap the child.
Future<ProcessResult> runCli(
  String executable,
  List<String> arguments,
  List<Map<String, dynamic>> requests, {
  String? workingDirectory,
  Duration timeout = const Duration(seconds: 80),
}) async {
  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
  );
  final output = process.stdout
      .transform(const Utf8Decoder(allowMalformed: true))
      .join();
  // Diagnostics may contain SDK/file content; consume without returning them.
  final diagnostics = process.stderr.drain<void>();
  try {
    return await (() async {
      for (final request in requests) {
        process.stdin.writeln(jsonEncode(request));
      }
      await process.stdin.close();
      final code = await process.exitCode;
      final text = await output;
      await diagnostics;
      return ProcessResult(process.pid, code, text, '');
    })().timeout(timeout);
  } finally {
    process.kill(ProcessSignal.sigkill);
    // A broken pipe while cleaning up is expected after an early child exit.
    try {
      await process.stdin.close();
    } on Exception {
      // No content-bearing diagnostics at this boundary.
    }
    await process.exitCode;
    await output;
    await diagnostics;
  }
}
