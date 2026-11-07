import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

void main() {
  test('AI-082 memory ops validate bounds and compare by value', () {
    const ok = SaveMemoryItem(kind: 'alias', key: 'shake', value: 'whey');
    expect(ok.validate(), isNull);
    expect(ok.family, MemoryItemOp.familyName);
    expect(
      ok,
      const SaveMemoryItem(kind: 'alias', key: 'shake', value: 'whey'),
    );
    expect(
      ok.hashCode,
      isNot(
        const SaveMemoryItem(kind: 'alias', key: 'shake', value: 'x').hashCode,
      ),
    );
    expect(ok.toString(), isNot(contains('shake')));
    expect(
      const SaveMemoryItem(kind: '', key: 'a', value: 'b').validate(),
      InvalidMemoryItem.kind,
    );
    expect(
      SaveMemoryItem(kind: 'alias', key: 'a' * 201, value: 'b').validate(),
      InvalidMemoryItem.text,
    );
    expect(InvalidMemoryItem.stale.code, 'memoryItemStale');
    const id = '0199e3c2-5b1a-7000-8000-00000000000a';
    expect(DeleteMemoryItem(id, 1), DeleteMemoryItem(id, 1));
    expect(DeleteMemoryItem(id, 1).hashCode, DeleteMemoryItem(id, 1).hashCode);
    expect(DeleteMemoryItem(id, 1).toString(), contains(id));
    expect(() => DeleteMemoryItem('x', 1), throwsArgumentError);
    expect(const ClearMemoryItems(), const ClearMemoryItems());
    expect(const ClearMemoryItems().hashCode, (ClearMemoryItems).hashCode);
    expect(const ClearMemoryItems().toString(), 'ClearMemoryItems');
    expect(MemoryOrigin.fromCode('learned'), MemoryOrigin.learned);
    expect(MemoryOrigin.fromCode('x'), isNull);
    final item = MemoryItem(
      id: id,
      version: 1,
      kind: 'alias',
      key: 'shake',
      value: 'whey',
      origin: MemoryOrigin.explicit,
      createdAt: DateTime.utc(2026),
    );
    final same = MemoryItem(
      id: id,
      version: 1,
      kind: 'alias',
      key: 'shake',
      value: 'whey',
      origin: MemoryOrigin.explicit,
      createdAt: DateTime.utc(2026),
    );
    expect(item, same);
    expect(item.hashCode, same.hashCode);
    expect(item.toString(), isNot(contains('shake')));
  });
}
