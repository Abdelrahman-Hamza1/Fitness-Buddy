import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../../packages/fb_domain/benchmark/support/proposal_workload.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // covers: AI-040
  // rule: A21 device-performance
  testWidgets('AI-040 six item profile recompute p95 stays within 50 ms', (
    _,
  ) async {
    expect(kProfileMode, isTrue, reason: 'Run this gate with --profile');
    const device = String.fromEnvironment('A21_DEVICE');
    expect(device, isNotEmpty, reason: 'Supply --dart-define=A21_DEVICE=...');
    final workload = ProposalWorkload();
    final result = runProposalBenchmark(workload);
    // Only fixed synthetic scenario, SDK/build/device, timings and checksum.
    // ignore: avoid_print
    print(
      result.report(
        mode: 'flutter-profile',
        host: '${Platform.operatingSystem}/$device',
      ),
    );
    expect(result.p95Ms, lessThanOrEqualTo(50));
  });
}
