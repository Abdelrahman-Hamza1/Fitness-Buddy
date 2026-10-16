import 'dart:io';

Future<void> main(List<String> args) async {
  if (args.single == 'exit') {
    stderr.writeln('content-canary-never-forward');
    exitCode = 1;
    return;
  }
  // Deliberately never completes: the runner must kill and reap it.
  await Future<void>.delayed(const Duration(days: 1));
}
