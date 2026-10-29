import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

const _v7 = '019a1b2c-0000-7000-8000-000000000001';
const _other = '019a1b2c-0000-7000-8000-000000000002';
const _v5 = '0a1b2c3d-0000-5000-8000-000000000001';
const _canary = 'CANARY-A22-PRIVATE';

ChatMessageDraft _user({
  String text = _canary,
  ChatMessageStatus status = ChatMessageStatus.queued,
  ChatLanguage? language,
  int? codecVersion,
  String? budgetJson,
}) => ChatMessageDraft(
  role: ChatMessageRole.user,
  text: text,
  status: status,
  language: language,
  codecVersion: codecVersion,
  budgetJson: budgetJson,
);

ChatMessageDraft _assistant({
  String text = 'Logged',
  String? replyTo = _other,
  int? codecVersion = 1,
  String? budgetJson = '{"codecVersion":1}',
}) => ChatMessageDraft(
  role: ChatMessageRole.assistant,
  text: text,
  status: ChatMessageStatus.done,
  language: ChatLanguage.english,
  replyToMessageId: replyTo,
  codecVersion: codecVersion,
  budgetJson: budgetJson,
);

void main() {
  // rule: A22 chat-wire-rules
  group('A22 chat message drafts follow the chatMessage wire rules', () {
    test('admissible user and assistant drafts', () {
      expect(_user().validateWire(), isNull);
      expect(_user(text: '').validateWire(), isNull);
      expect(_user(text: 'x' * 8190 + '🍎').validateWire(), isNull);
      expect(_assistant().validateWire(), isNull);
      expect(
        _assistant(codecVersion: null, budgetJson: null).validateWire(),
        isNull,
      );
      expect(
        _assistant(codecVersion: ChatProposalSyncBounds.codecVersionMax)
            .validateWire(),
        isNull,
      );
      final budget = '"${'x' * (ChatProposalSyncBounds.json - 2)}"';
      expect(_assistant(budgetJson: budget).validateWire(), isNull);
      expect(_assistant(replyTo: null).validateWire(), isNull);
    });

    test('each broken rule has its code', () {
      final cases = {
        _user(text: 'x' * 8193): InvalidChatMessage.text,
        _user(text: 'x' * 8191 + '🍎'): InvalidChatMessage.text,
        _user(text: 'a\u0000'): InvalidChatMessage.text,
        _user(text: 'a\uD800'): InvalidChatMessage.text,
        _user(text: '\uDC00'): InvalidChatMessage.text,
        _user(codecVersion: 1, budgetJson: '{}'): InvalidChatMessage.userBudget,
        _user(budgetJson: '{}'): InvalidChatMessage.userBudget,
        _user(codecVersion: 1): InvalidChatMessage.userBudget,
        _assistant(replyTo: 'not-a-uuid'): InvalidChatMessage.replyTo,
        _assistant(replyTo: _v7.toUpperCase()): InvalidChatMessage.replyTo,
        _assistant(codecVersion: 0): InvalidChatMessage.codecVersion,
        _assistant(codecVersion: ChatProposalSyncBounds.codecVersionMax + 1):
            InvalidChatMessage.codecVersion,
        _assistant(budgetJson: null): InvalidChatMessage.codecVersion,
        _assistant(codecVersion: null): InvalidChatMessage.budget,
        _assistant(budgetJson: '"${'x' * (ChatProposalSyncBounds.json - 1)}"'):
            InvalidChatMessage.budget,
        _assistant(budgetJson: '{"a":'): InvalidChatMessage.budget,
        _assistant(budgetJson: '{"a":"\u0000"}'): InvalidChatMessage.budget,
        _assistant(budgetJson: '{"a":"\uD800"}'): InvalidChatMessage.budget,
      };
      for (final MapEntry(key: draft, :value) in cases.entries) {
        expect(draft.validateWire(), value, reason: value.name);
      }
      expect({
        for (final c in InvalidChatMessage.values) c.code,
      }, hasLength(InvalidChatMessage.values.length));
      for (final c in InvalidChatMessage.values) {
        expect(c.code, matches(RegExp(r'^chatMessage[A-Z][A-Za-z]*$')));
      }
    });

    test('create needs a UUIDv7 row ID, never a UUIDv5', () {
      expect(CreateChatMessage(_v7, _user()).validate(), isNull);
      expect(CreateChatMessage(_v5, _user()).validate(), InvalidChatMessage.id);
      expect(
        CreateChatMessage(_v7, _user(text: 'a\u0000')).validate(),
        InvalidChatMessage.text,
      );
      expect(() => CreateChatMessage('nope', _user()), throwsArgumentError);
      expect(
        () => SetChatMessageStatus(_v7, 0, ChatMessageStatus.done),
        throwsArgumentError,
      );
      expect(
        () => SetChatMessageStatus('nope', 1, ChatMessageStatus.done),
        throwsArgumentError,
      );
    });
  });

  // rule: A22 chat-ops
  test('A22 chat message ops have value equality, one family and '
      'content-free strings', () {
    final create = CreateChatMessage(_v7, _user());
    final status = SetChatMessageStatus(
      _v7,
      1,
      ChatMessageStatus.done,
      language: ChatLanguage.arabizi,
    );
    expect(create.family, 'chatMessage');
    expect(status.family, ChatMessageOp.familyName);
    expect(create, isA<ChangeOp>());
    expect(create, CreateChatMessage(_v7, _user()));
    expect(create.hashCode, CreateChatMessage(_v7, _user()).hashCode);
    expect(create, isNot(CreateChatMessage(_v7, _user(text: 'other'))));
    expect(create, isNot(CreateChatMessage(_other, _user())));
    expect(
      status,
      SetChatMessageStatus(
        _v7,
        1,
        ChatMessageStatus.done,
        language: ChatLanguage.arabizi,
      ),
    );
    expect(
      status.hashCode,
      SetChatMessageStatus(
        _v7,
        1,
        ChatMessageStatus.done,
        language: ChatLanguage.arabizi,
      ).hashCode,
    );
    for (final other in [
      SetChatMessageStatus(_v7, 1, ChatMessageStatus.done),
      SetChatMessageStatus(_v7, 2, ChatMessageStatus.done),
      SetChatMessageStatus(_v7, 1, ChatMessageStatus.failed),
      SetChatMessageStatus(_other, 1, ChatMessageStatus.done),
    ]) {
      expect(status, isNot(other));
    }

    String describe(ChatMessageOp op) => switch (op) {
      CreateChatMessage(:final id) => 'create $id',
      SetChatMessageStatus(:final status) => 'status ${status.code}',
    };
    expect(describe(create), 'create $_v7');
    expect(describe(status), 'status done');

    final drafts = [
      _user(),
      _user(language: ChatLanguage.arabic, status: ChatMessageStatus.done),
      _assistant(),
      _assistant(text: _canary, budgetJson: '{"q":"$_canary"}'),
    ];
    for (final (i, a) in drafts.indexed) {
      for (final (j, b) in drafts.indexed) {
        expect(a == b, i == j);
        if (i == j) expect(a.hashCode, b.hashCode);
      }
    }
    final message = ChatMessage(
      id: _v7,
      version: 2,
      createdAt: DateTime.utc(2026, 10, 29, 8, 40),
      draft: drafts.last,
    );
    expect(message.role, ChatMessageRole.assistant);
    expect(message.text, _canary);
    expect(message.status, ChatMessageStatus.done);
    expect(message.language, ChatLanguage.english);
    expect(message.replyToMessageId, _other);
    expect(message.codecVersion, 1);
    expect(message.budgetJson, contains(_canary));
    expect(
      message,
      ChatMessage(
        id: _v7,
        version: 2,
        createdAt: DateTime.utc(2026, 10, 29, 8, 40),
        draft: drafts.last,
      ),
    );
    expect(
      message.hashCode,
      ChatMessage(
        id: _v7,
        version: 2,
        createdAt: DateTime.utc(2026, 10, 29, 8, 40),
        draft: drafts.last,
      ).hashCode,
    );
    expect(
      message,
      isNot(
        ChatMessage(
          id: _v7,
          version: 3,
          createdAt: DateTime.utc(2026, 10, 29, 8, 40),
          draft: drafts.last,
        ),
      ),
    );
    expect(
      () => ChatMessage(
        id: _v7,
        version: 1,
        createdAt: DateTime(2026),
        draft: _user(),
      ),
      throwsArgumentError,
    );
    expect(
      () => ChatMessage(
        id: _v7,
        version: 0,
        createdAt: DateTime.utc(2026),
        draft: _user(),
      ),
      throwsArgumentError,
    );

    // Privacy: no text or budget in any string form.
    for (final value in <Object>[
      create,
      status,
      message,
      ...drafts,
      CreateChatMessage(_v7, drafts.last),
    ]) {
      expect('$value', isNot(contains(_canary)));
    }
  });
}
