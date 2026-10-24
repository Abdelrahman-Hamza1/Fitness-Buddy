import 'package:fb_domain/fb_domain.dart';

/// B09 replaces this minimal routing fixture with recorded v1 interpretations
/// and ProposalFacts from its recorded catalog/personal snapshot.
void main() {
  final result = ProposalEvaluation.evaluate(
    ProposalRequest(
      interpretation: const {
        'promptVersion': 'interpret-v1',
        'model': 'offline-recording',
        'intents': [
          {
            'kind': 'clarify',
            'language': 'english',
            'script': 'latin',
            'reason': 'unmatchedFood',
          },
        ],
      },
      messageId: '019a1b2c-0000-7000-8000-000000009999',
      idSource: _RecordedIds(),
      context: ProposalContext(
        referenceTime: EntryTime(DateTime.utc(2026, 10, 17, 8), 0),
        slots: [DefaultSlots.breakfast, DefaultSlots.snacks],
      ),
      facts: ProposalFacts(),
    ),
  );
  // Assertions consume only structure. Never print interpretations or names.
  assert(result.result.issue == null, 'Recorded fixture must be valid');
  assert(result.cards.isEmpty, 'Routing must not create food cards');
  assert(result.questionCount == 0, 'Routing has no food questions');
}

final class _RecordedIds implements ProposalIdSource {
  int _sequence = 0;
  @override
  String next() =>
      '019a1b2c-0000-7000-8000-${(++_sequence).toString().padLeft(12, '0')}';
}
