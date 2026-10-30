/// Adaptive targets & the weekly check-in (A38): the expenditure estimate
/// from logged intake and weight (TG-030–033), the weekly target-change
/// proposal (TG-034–036, AI-056), the incomplete-day suggestion (DY-004)
/// and their Progress cards. Other features and `app/` import only this
/// barrel (`03-architecture.md` §3.2).
library;

export 'application/adaptive_actions.dart'
    show
        AdaptiveActions,
        AdaptiveDone,
        AdaptiveFailed,
        AdaptiveFailure,
        AdaptiveOutcome,
        AdaptivePending,
        CheckInRun,
        adaptiveActionsProvider,
        weeklyCheckInProvider;
export 'application/adaptive_inputs.dart';
export 'application/adaptive_providers.dart';
export 'presentation/adaptive_cards.dart';
