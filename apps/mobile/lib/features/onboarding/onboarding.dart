/// Onboarding (A13b, A51): the first run on a fresh install (D-088,
/// TD-110) and the question screens that set up profile and targets
/// (UX-060), full screens outside the tabs. Other features and `app/`
/// import only this barrel (`03-architecture.md` §3.2).
library;

export 'application/first_run_gate.dart';
export 'application/setup_flow.dart';
export 'presentation/setup_screen.dart';
export 'presentation/welcome_screen.dart';
