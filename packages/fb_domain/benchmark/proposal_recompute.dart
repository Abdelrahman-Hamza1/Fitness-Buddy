import 'dart:io';

import 'support/proposal_workload.dart';

/// Host regression gate, independent of the unmeasured A55 device acceptance.
void main() {
  final workload = ProposalWorkload();
  final result = runProposalBenchmark(workload);
  stdout.writeln(
    result.report(
      mode: 'dart-run-jit',
      host:
          '${Platform.operatingSystem}/${Platform.localHostname}/'
          '${Platform.numberOfProcessors}cpu',
    ),
  );
  if (result.p95Ms > 10) exitCode = 1;
}
