import 'package:fb_mobile/core/config/app_config.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'buddy_trace.g.dart';

/// Whether this build asks for and shows Buddy's trace (AI-172, A66 D14):
/// dev builds, and the owner's builds made with
/// `--dart-define=FB_BUDDY_TRACE=true`. The server honours it only with
/// `Buddy:Agent:TraceEnabled`; the trace stays on the phone.
@Riverpod(keepAlive: true)
bool buddyTraceEnabled(Ref ref) =>
    ref.watch(appConfigProvider).flavor == AppFlavor.dev ||
    const bool.fromEnvironment('FB_BUDDY_TRACE');
