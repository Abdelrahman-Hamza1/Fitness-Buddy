import 'package:fb_mobile/core/errors/error_reporting.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'test_report.g.dart';

/// What sending the test error report did, without display text.
enum TestReportOutcome {
  /// Both synthetic errors were handed to the reporter.
  sent,

  /// This build has no crash-report address, so nothing can be sent.
  unavailable,
}

/// The About screen's test error report (A11 D17), over the reporter.
final class TestReportSender {
  /// Wires the sender to [enabled] (a DSN is set) and the reporter's [send].
  const new({required this.enabled, required this.send});

  /// Whether this build can report at all.
  final bool enabled;

  /// Sends the handled and the unhandled synthetic error.
  final Future<void> Function() send;

  /// Sends the report, or says it can't be sent (no DSN).
  Future<TestReportOutcome> sendReport() async {
    if (!enabled) return TestReportOutcome.unavailable;
    await send();
    return TestReportOutcome.sent;
  }
}

/// The reporter behind the About gesture; tests override it with a fake.
@riverpod
TestReportSender testReportSender(Ref ref) {
  final reporting = ref.watch(errorReportingProvider);
  return TestReportSender(
    enabled: reporting.config.sentryDsn.isNotEmpty,
    send: reporting.sendTestReport,
  );
}
