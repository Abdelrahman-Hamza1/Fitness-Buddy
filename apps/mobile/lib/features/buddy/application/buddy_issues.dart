import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/errors/error_reporting.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'buddy_issues.g.dart';

/// A content-free Buddy problem worth reporting (A22 D6, D9, PA8). Only the
/// type is reported: never the message, the request, the answer or a parse
/// error (which can quote them).
sealed class BuddyIssue implements Exception {
  const new _();
}

/// The server refused the request (400/409 class): a request the phone
/// built that the server doesn't accept.
final class BuddyRequestRejected extends BuddyIssue {
  /// The issue.
  const new() : super._();

  @override
  String toString() => 'BuddyRequestRejected';
}

/// A 200 that couldn't become cards (contract, loader or engine failure).
final class BuddyReplyUnusable extends BuddyIssue {
  /// The issue.
  const new() : super._();

  @override
  String toString() => 'BuddyReplyUnusable';
}

/// The shared question budget didn't fit 32768 UTF-16 units; the assistant
/// row was saved without it.
final class BuddyBudgetTooLarge extends BuddyIssue {
  /// The issue.
  const new() : super._();

  @override
  String toString() => 'BuddyBudgetTooLarge';
}

/// A card was logged, but refreshing the previews afterwards failed (they
/// stay as they were until the next refresh).
final class BuddyRefreshFailed extends BuddyIssue {
  /// The issue.
  const new() : super._();

  @override
  String toString() => 'BuddyRefreshFailed';
}

/// A stored card or session couldn't be reopened as it was (A23 D13):
/// only the [issue] type is reported, never its content.
final class BuddyRestoreIssue extends BuddyIssue {
  /// The issue.
  const new(this.issue) : super._();

  /// Why (`sessionIncomplete`, `staleFacts`, …).
  final ProposalIssue issue;

  @override
  String toString() => 'BuddyRestoreIssue(${issue.name})';
}

/// Where Buddy issues go.
typedef BuddyIssueSink = void Function(BuddyIssue issue);

/// Reports the issue's type only (`ErrorReporting.reportKind`).
@Riverpod(keepAlive: true)
BuddyIssueSink buddyIssueSink(Ref ref) {
  final reporting = ref.watch(errorReportingProvider);
  return reporting.reportKind;
}
