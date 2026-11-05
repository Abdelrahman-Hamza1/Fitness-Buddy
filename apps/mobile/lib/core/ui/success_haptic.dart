import 'dart:async';

import 'package:flutter/services.dart';

/// One light tick when a direct log lands (A57 A80, D24): a food logged
/// from search, the food sheet or quick-add, and a weigh-in saved. Never on
/// keystrokes or navigation; Buddy's confirm keeps its own.
void successHaptic() => unawaited(HapticFeedback.lightImpact());
